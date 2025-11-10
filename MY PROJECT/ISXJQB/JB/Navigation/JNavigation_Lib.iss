; JNavigation - Enhanced Waypoint Navigation System
; Path: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JNavigation.iss
; Version: 2.3.2 - Fixed OgreBot key variable dependencies


; These MUST be declared at parse time for the script to load
variable(global) string JNav_ForwardKey = "w"
variable(global) string JNav_BackwardKey = "s"
variable(global) string JNav_FlyUpKey = "home"
variable(global) string JNav_FlyDownKey = "end"
variable(global) string JNav_JumpKey = "space"
variable(global) string JNav_CrouchKey = "c"

; Navigation state
variable(global) point3f J_Nav_CurrentWaypoint
variable(global) int J_Nav_CurrentWaypointIndex = 0
variable(global) bool J_Nav_Moving = FALSE
variable(global) bool J_Nav_Flying = FALSE
variable(global) bool J_Nav_MovingForward = FALSE
variable(global) bool J_Nav_MovementEnabled = FALSE
variable(global) bool J_Nav_EnableStuckDetection = TRUE
variable(global) bool J_Nav_EnableCombatPause = TRUE

; Precision thresholds
variable(global) float J_Nav_Precision = 1.5
variable(global) float J_Nav_PrecisionToDestination = 3.0
variable(global) float J_Nav_OffMapPrecision = 5.0
variable(global) float J_Nav_PrecisionWhileFlying = 2.0
variable(global) float J_Nav_WaypointTolerance = 3.0
variable(global) float J_Nav_EmergencyBailoutDistance = 10.0
variable(global) float J_Nav_Distance2DThreshold = 2.0
variable(global) float J_Nav_HeightPrecision = 2.0

; Timer-based stuck detection (OgreNavLib pattern)
variable(global) float J_Nav_StuckDistance = 1.0
variable(global) int J_Nav_StuckCounter = 0
variable(global) point3f J_Nav_LastLoc
variable(global) uint J_Nav_LastStuckCheck = 0
variable(global) uint J_Nav_StuckCheckInterval = 2000

; Facing adjustment throttling (prevent zigzagging)
variable(global) uint J_Nav_LastFaceTime = 0
variable(global) uint J_Nav_FaceInterval = 750

variable(global) string J_Nav_Version = "2.3.2"

objectdef JNavigation_obj
{
    function NavigatePath(jsonvalue pathData, bool reverse, bool preBuff, bool ignoreAggro)
    {
        variable int waypointCount
        variable int startIndex
        variable int endIndex
        variable int increment
        variable int currentIndex

        ; Validate path data
        if !${pathData.Type.Equal[array]}
        {
            echo ${Time}: ERROR: Invalid path data - not an array
            return
        }

        waypointCount:Set[${pathData.Size}]

        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] Path data validated - Type: ${pathData.Type}, Size: ${waypointCount}

        if ${waypointCount} == 0
        {
            echo ${Time}: ERROR: Path has no waypoints
            return
        }

        echo ${Time}: ================================================
        echo ${Time}: [Navigation] Starting path navigation
        echo ${Time}: [Navigation] Waypoints: ${waypointCount}
        echo ${Time}: [Navigation] Direction: ${reverse.Select["Reverse","Forward"]}
        echo ${Time}: ================================================

        ; Determine direction
        if ${reverse}
        {
            startIndex:Set[${Math.Calc[${waypointCount}-1]}]
            endIndex:Set[0]
            increment:Set[-1]
        }
        else
        {
            startIndex:Set[0]
            endIndex:Set[${Math.Calc[${waypointCount}-1]}]
            increment:Set[1]
        }

        ; Pre-buff if requested
        if ${preBuff}
        {
            call This.PreBuff
        }

        ; Navigate each waypoint
        currentIndex:Set[${startIndex}]

        while 1
        {
            ; Check if we've completed the path
            if ${reverse}
            {
                if ${currentIndex} < ${endIndex}
                break
            }
            else
            {
                if ${currentIndex} > ${endIndex}
                break
            }

            ; Validate waypoint data
            if !${pathData.Get[${currentIndex}].Has[x]} || !${pathData.Get[${currentIndex}].Has[y]} || !${pathData.Get[${currentIndex}].Has[z]}
            {
                echo ${Time}: WARNING: Waypoint ${Math.Calc[${currentIndex}+1]} missing coordinates, skipping
                if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                    echo [Debug:Waypoints] Missing coords - Has[x]:${pathData.Get[${currentIndex}].Has[x]}, Has[y]:${pathData.Get[${currentIndex}].Has[y]}, Has[z]:${pathData.Get[${currentIndex}].Has[z]}
                currentIndex:Set[${Math.Calc[${currentIndex}+${increment}]}]
                continue
            }

            ; Set current waypoint
            J_Nav_CurrentWaypoint.X:Set[${pathData.Get[${currentIndex}].Get[x]}]
            J_Nav_CurrentWaypoint.Y:Set[${pathData.Get[${currentIndex}].Get[y]}]
            J_Nav_CurrentWaypoint.Z:Set[${pathData.Get[${currentIndex}].Get[z]}]

            J_Nav_CurrentWaypointIndex:Set[${Math.Calc[${currentIndex}+1]}]

            if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                echo [Debug:Waypoints] Loaded WP ${J_Nav_CurrentWaypointIndex}/${waypointCount}: X=${J_Nav_CurrentWaypoint.X.Precision[2]}, Y=${J_Nav_CurrentWaypoint.Y.Precision[2]}, Z=${J_Nav_CurrentWaypoint.Z.Precision[2]}

            echo ${Time}: [Navigation] → Waypoint ${J_Nav_CurrentWaypointIndex}/${waypointCount}: (${J_Nav_CurrentWaypoint.X.Precision[1]}, ${J_Nav_CurrentWaypoint.Y.Precision[1]}, ${J_Nav_CurrentWaypoint.Z.Precision[1]})

            ; Move to waypoint
            call This.MoveToWaypoint

            ; Combat check
            if ${J_Nav_EnableCombatPause} && ${Me.InCombat} && !${ignoreAggro}
            {
                echo ${Time}: [Navigation] Combat detected - pausing navigation
                call This.StopMovement

                while ${Me.InCombat}
                {
                    waitframe
                }

                echo ${Time}: [Navigation] Combat ended - resuming navigation
                waitframe
            }

            ; Increment
            currentIndex:Set[${Math.Calc[${currentIndex}+${increment}]}]

            waitframe
        }

        call This.StopMovement
        echo ${Time}: [Navigation] Path completed successfully
    }

    ; =====================================================
    ; WRAPPER FOR INSTANCE RUNNER - Extracts path from instance data
    ; =====================================================

    function NavigatePathFromInstance(string pathName, jsonvalue instanceData, bool reverse, bool preBuff, bool ignoreAggro)
    {
        variable jsonvalue pathData

        ; Check if instance data has navigationPaths
        if !${instanceData.Has[navigationPaths]}
        {
            echo ${Time}:  ERROR: Instance data missing 'navigationPaths' section
            return
        }

        ; Check if specific path exists
        if !${instanceData.Get[navigationPaths].Has["${pathName.Escape}"]}
        {
            echo ${Time}:  ERROR: Path '${pathName}' not found in instance data
            echo ${Time}: Available paths: ${instanceData.Get[navigationPaths].Keys}
            return
        }

        ; Get the path
        pathData:SetReference["instanceData.Get[navigationPaths].Get[\"${pathName.Escape}\"]"]

        echo ${Time}: [Navigation] Using path: ${pathName}

        ; Navigate it
        call This.NavigatePath "${pathData}" ${reverse} ${preBuff} ${ignoreAggro}
    }

    ; =====================================================
    ; MOVEMENT CONTROL (OgreNavLib pattern)
    ; =====================================================

    function StartMoving()
    {
        ; Use held forward key instead of autorun toggle
        if ${J_Nav_Flying} || !${Me.IsMoving}
        {
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:Navigation] Starting movement - Flying:${J_Nav_Flying}, Key:${JNav_ForwardKey}
            press -hold ${JNav_ForwardKey}
            J_Nav_MovingForward:Set[TRUE]
            J_Nav_MovementEnabled:Set[TRUE]
        }
    }

    function StopMovingForward()
    {
        if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
            echo [Debug:Navigation] Stopping forward movement - Releasing key:${JNav_ForwardKey}
        press -release ${JNav_ForwardKey}
        J_Nav_MovingForward:Set[FALSE]
    }

    ; =====================================================
    ; TIMER-BASED STUCK DETECTION (OgreNavLib pattern)
    ; =====================================================

    member:bool CheckStuck()
    {
        ; Only check every 2 seconds (not every frame!)
        if (${System.TickCount} - ${J_Nav_LastStuckCheck}) < ${J_Nav_StuckCheckInterval}
            return FALSE

        ; Time to check - compare current location to last check
        variable float distanceMoved = ${Math.Distance[${J_Nav_LastLoc},${Me.Loc}]}
        if ${distanceMoved} < ${J_Nav_StuckDistance}
        {
            J_Nav_StuckCounter:Inc

            ; Dynamic stuck threshold based on situation:
            ; - In combat or executing commands: Use shorter threshold (6 seconds)
            ; - Normal navigation: Use longer threshold (20 seconds)
            variable int stuckThreshold = 10  ; 10 checks * 2 seconds = 20 seconds

            ; Check if in combat or busy with commands
            if ${Me.InCombat} || (${JBUI_Movement_Active(exists)} && ${JBUI_Movement_Active})
            {
                stuckThreshold:Set[3]  ; 3 checks * 2 seconds = 6 seconds (faster response)
            }

            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:Navigation] Stuck check - Moved:${distanceMoved.Precision[2]}m, Counter:${J_Nav_StuckCounter}/${stuckThreshold}, InCombat:${Me.InCombat}

            if ${J_Nav_StuckCounter} >= ${stuckThreshold}
            {
                echo ${Time}: [Navigation] STUCK DETECTED - no movement for ${Math.Calc[${stuckThreshold}*2]} seconds
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Stuck triggered - LastLoc:(${J_Nav_LastLoc.X.Precision[1]},${J_Nav_LastLoc.Y.Precision[1]},${J_Nav_LastLoc.Z.Precision[1]}), CurrentLoc:(${Me.X.Precision[1]},${Me.Y.Precision[1]},${Me.Z.Precision[1]})
                return TRUE
            }
        }
        else
        {
            ; Made progress - reset counter
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation} && ${J_Nav_StuckCounter} > 0
                echo [Debug:Navigation] Progress made - Moved:${distanceMoved.Precision[2]}m, Resetting stuck counter (was:${J_Nav_StuckCounter})
            J_Nav_StuckCounter:Set[0]
        }

        ; Update for next check
        J_Nav_LastLoc:Set[${Me.Loc}]
        J_Nav_LastStuckCheck:Set[${System.TickCount}]

        return FALSE
    }

    ; =====================================================
    ; DISTANCE2D - Horizontal distance only (ignores Y height)
    ; CRITICAL for dock/edge navigation!
    ; =====================================================

    member:float Distance2D(float destX, float destY, float destZ)
    {
        ; Only X and Z (horizontal) - ignores Y (height)
        return ${Math.Distance[${Me.X},${Me.Z},${destX},${destZ}]}
    }

    ; =====================================================
    ; WAYPOINT VALIDATION - Catch bad coordinates
    ; =====================================================

    member:bool ValidateWaypoint(float X, float Y, float Z)
    {
        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] Validating waypoint: (${X.Precision[2]}, ${Y.Precision[2]}, ${Z.Precision[2]})

        ; Check for 0,0,0 (invalid waypoint)
        if ${Math.Distance[0,0,0,${X},${Y},${Z}]} == 0
        {
            echo ${Time}: [Navigation] ERROR: Invalid waypoint (0,0,0) detected - SKIPPING
            if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                echo [Debug:Waypoints] Validation FAILED: Waypoint is at origin (0,0,0)
            return FALSE
        }

        ; Check for extreme distances (likely bad data - over 10km away)
        variable float distanceFromMe = ${Math.Distance[${Me.Loc},${X},${Y},${Z}]}
        if ${distanceFromMe} > 10000
        {
            echo ${Time}: [Navigation] ERROR: Waypoint extremely far away (${distanceFromMe.Precision[0]}m) - likely bad data - SKIPPING
            if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                echo [Debug:Waypoints] Validation FAILED: Distance ${distanceFromMe.Precision[1]}m exceeds 10000m limit
            return FALSE
        }

        ; Check for NaN or invalid coordinates
        if ${X} == 0 && ${Y} == 0 && ${Z} == 0
        {
            echo ${Time}: [Navigation] ERROR: All coordinates are zero - SKIPPING
            if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                echo [Debug:Waypoints] Validation FAILED: All coordinates are zero
            return FALSE
        }

        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] Validation PASSED - Distance from player: ${distanceFromMe.Precision[1]}m

        return TRUE
    }

    ; =====================================================
    ; COLLISION & LOS CHECKING - Warn about problematic paths
    ; =====================================================

    method CheckWaypointSafety(float X, float Y, float Z)
    {
        variable float distance = ${Math.Distance[${Me.Loc},${X},${Y},${Z}]}

        ; Only check collision/LOS if waypoint is far enough away (> 10m)
        ; Too close and these checks are unreliable
        if ${distance} < 10
            return

        ; Check for collision (obstacle in the way)
        ; Note: CheckCollision/CheckLOS may not be available in all ISXEQ2 versions
        ; Commented out to prevent errors - stuck detection will handle obstacles
        ; if ${Me.CheckCollision[${X},${Y},${Z}]}
        ; {
        ;     echo ${Time}: [Navigation] WARNING: Collision detected to waypoint (${distance.Precision[1]}m away)
        ; }
    }

    ; =====================================================
    ; WITHIN RANGE CHECK - Smart arrival detection
    ; =====================================================

    member:bool WithinRangeToDestination(float destX, float destY, float destZ, float tolerance)
    {
        variable float distance3D = ${Math.Distance[${Me.Loc},${destX},${destY},${destZ}]}
        variable float distance2D = ${This.Distance2D[${destX},${destY},${destZ}]}
        variable float heightDiff = ${Math.Abs[${Math.Calc[${Me.Y}-${destY}]}]}

        ; Ground vs Flying arrival logic:
        ; - Flying: Check full 3D (we control X, Y, Z with fly keys)
        ; - Ground: Check 2D for movement, but ALSO check height for arrival
        ;           Walking up slopes/bridges naturally increases Y - don't accept
        ;           arrival if we're 10m below, need to keep moving forward!

        if ${J_Nav_Flying}
        {
            ; Flying: Check full 3D distance (we control X, Y, Z)
            if ${distance3D} <= ${tolerance}
            {
                echo ${Time}: [Navigation] Flying arrival: 3D distance ${distance3D.Precision[1]}m <= ${tolerance}m
                return TRUE
            }
        }
        else
        {
            ; Ground: Check BOTH 2D (horizontal) AND height (vertical)
            ; Height tolerance: 1.5m (tight enough for slopes, loose enough for lumpy terrain)
            variable float groundHeightTolerance = 1.5

            if ${distance2D} <= ${tolerance} && ${heightDiff} <= ${groundHeightTolerance}
            {
                echo ${Time}: [Navigation] Ground arrival: 2D=${distance2D.Precision[1]}m, height=${heightDiff.Precision[1]}m (both within tolerance)
                return TRUE
            }
        }

        return FALSE
    }

    ; =====================================================
    ; CORE MOVEMENT - Move to a single waypoint
    ; =====================================================

    function MoveToWaypoint()
    {
        variable float distance
        variable float distance2D
        variable int stuckAttempts = 0
        variable int maxStuckAttempts = 3
        variable int loopCounter = 0
        variable int maxLoops = 600

        J_Nav_Moving:Set[TRUE]

        ; VALIDATE WAYPOINT - Check for bad coordinates
        if !${This.ValidateWaypoint[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}]}
        {
            echo ${Time}: [Navigation] Waypoint validation failed - aborting movement
            J_Nav_Moving:Set[FALSE]
            return
        }

        ; CHECK WAYPOINT SAFETY - Collision and LOS warnings
        This:CheckWaypointSafety[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}]

        ; Initialize stuck detection timer
        J_Nav_LastLoc:Set[${Me.Loc}]
        J_Nav_LastStuckCheck:Set[${System.TickCount}]
        J_Nav_StuckCounter:Set[0]

        ; Reset facing timer to ensure immediate facing on new waypoint
        J_Nav_LastFaceTime:Set[0]

        ; Check if already at destination BEFORE movement (using smart range check)
        if ${This.WithinRangeToDestination[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z},${J_Nav_WaypointTolerance}]}
        {
            echo ${Time}: [Navigation] Already within range of waypoint - skipping movement
            J_Nav_Moving:Set[FALSE]
            return
        }

        ; Calculate distances
        distance:Set[${Math.Distance[${Me.Loc},${J_Nav_CurrentWaypoint}]}]
        distance2D:Set[${This.Distance2D[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}]}]

        ; Detect if we SHOULD fly (height >= 7m) AND if we CAN fly (mount/swimming)
        ; Ground mode: Only move X/Z, ignore Y (terrain controls height)
        variable float heightDiff = ${Math.Calc[${J_Nav_CurrentWaypoint.Y}-${Me.Y}]}
        variable float absHeightDiff = ${Math.Abs[${heightDiff}]}

        ; Check if character can actually fly
        variable bool canFly = FALSE
        if ${Me.IsSwimming} || ${Me.InWater} || ${Me.FlyingUsingMount} || ${Me.OnFlyingMount}
        {
            canFly:Set[TRUE]
        }

        ; Only enable flying if BOTH: big height difference AND ability to fly
        if ${canFly} && ${absHeightDiff} >= 7.0
        {
            J_Nav_Flying:Set[TRUE]
            if ${heightDiff} > 0
            {
                echo ${Time}: [Navigation] Height difference: ${heightDiff.Precision[1]}m upward - enabling flying (will control Y-axis)
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Flying mode ON - CanFly:TRUE, HeightDiff:${heightDiff.Precision[2]}m, Target height:${J_Nav_CurrentWaypoint.Y.Precision[1]}
            }
            else
            {
                echo ${Time}: [Navigation] Height difference: ${heightDiff.Precision[1]}m downward - enabling flying (will control Y-axis)
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Flying mode ON - CanFly:TRUE, HeightDiff:${heightDiff.Precision[2]}m, Target height:${J_Nav_CurrentWaypoint.Y.Precision[1]}
            }
        }
        else
        {
            J_Nav_Flying:Set[FALSE]
            if ${absHeightDiff} >= 7.0 && !${canFly}
            {
                echo ${Time}: [Navigation] Height difference: ${heightDiff.Precision[1]}m but no flying ability - using ground mode (2D only)
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Flying mode OFF - CanFly:FALSE, HeightDiff:${heightDiff.Precision[2]}m
            }
            elseif ${absHeightDiff} > 1.0
            {
                echo ${Time}: [Navigation] Height difference: ${heightDiff.Precision[1]}m - staying on ground (terrain controls Y-axis)
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Ground mode - HeightDiff:${heightDiff.Precision[2]}m (below 7m threshold)
            }
        }

        ; Start movement (held forward key, not autorun toggle)
        ; BUT: If horizontally at waypoint, only start flying (not forward movement)
        if ${distance2D} >= ${J_Nav_Distance2DThreshold}
        {
            call This.StartMoving
            echo ${Time}: [Navigation] Moving to waypoint (3D: ${distance.Precision[1]}m, 2D: ${distance2D.Precision[1]}m)
        }
        else
        {
            echo ${Time}: [Navigation] Horizontally at waypoint (2D: ${distance2D.Precision[1]}m) - only adjusting height (3D: ${distance.Precision[1]}m)
        }

        ; Main movement loop
        while 1
        {
            distance:Set[${Math.Distance[${Me.Loc},${J_Nav_CurrentWaypoint}]}]
            distance2D:Set[${Math.Distance[${Me.X},${Me.Z},${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Z}]}]

            loopCounter:Inc

            ; Check if movement was cancelled externally
            if !${J_Nav_Moving}
            {
                echo ${Time}: [Navigation] Movement cancelled externally

                ; Release forward key to prevent overshoot
                if ${J_Nav_MovingForward}
                {
                    call This.StopMovingForward
                }

                break
            }

            ; Emergency timeout - prevent infinite loops (600 frames = ~60 seconds)
            if ${loopCounter} > ${maxLoops}
            {
                echo ${Time}: [Navigation] EMERGENCY TIMEOUT (60 seconds) - accepting current position (distance: ${distance.Precision[1]}m)

                ; Release forward key to prevent overshoot
                if ${J_Nav_MovingForward}
                {
                    call This.StopMovingForward
                }

                break
            }

            ; Re-check flying status during movement
            ; Re-check height difference in case terrain changed
            variable float currentHeightDiff = ${Math.Calc[${J_Nav_CurrentWaypoint.Y}-${Me.Y}]}
            variable float absCurrentHeightDiff = ${Math.Abs[${currentHeightDiff}]}

            ; Check if character can fly (mount or swimming)
            variable bool currentCanFly = FALSE
            if ${Me.IsSwimming} || ${Me.InWater} || ${Me.FlyingUsingMount} || ${Me.OnFlyingMount}
            {
                currentCanFly:Set[TRUE]
            }

            ; Enable flying: Can fly AND (big height difference OR already swimming/mounted)
            ; Disable flying: Can't fly OR close to target height
            if ${currentCanFly}
            {
                ; Character can fly - check if we should enable flying mode
                if ${absCurrentHeightDiff} >= 7.0
                {
                    if !${J_Nav_Flying}
                    {
                        if ${currentHeightDiff} > 0
                        {
                            echo ${Time}: [Navigation] Height difference now ${currentHeightDiff.Precision[1]}m upward - enabling flying
                        }
                        else
                        {
                            echo ${Time}: [Navigation] Height difference now ${currentHeightDiff.Precision[1]}m downward - enabling flying
                        }
                    }
                    J_Nav_Flying:Set[TRUE]
                }
                elseif ${absCurrentHeightDiff} < 5.0
                {
                    ; Disable flying when close to target height (5m threshold with 2m hysteresis)
                    if ${J_Nav_Flying}
                    {
                        echo ${Time}: [Navigation] Height difference now ${currentHeightDiff.Precision[1]}m - disabling flying (terrain controls height)
                    }
                    J_Nav_Flying:Set[FALSE]
                }
            }
            else
            {
                ; Character can't fly - force ground mode
                if ${J_Nav_Flying}
                {
                    echo ${Time}: [Navigation] Lost flying ability - switching to ground mode
                }
                J_Nav_Flying:Set[FALSE]
            }

            ; Within 1 meter: Full stop for natural-looking arrival
            ; This makes the character slow down and stop instead of running full speed to the end
            if ${distance} <= 1.0
            {
                if ${J_Nav_MovingForward}
                {
                    echo ${Time}: [Navigation] Within 1m (${distance.Precision[1]}m) - stopping all movement
                    call This.StopMovement
                }
            }

            ; Check if we've arrived
            ; WithinRangeToDestination now handles ground vs flying logic:
            ; - Ground: Only checks X/Z (2D), ignores Y (terrain controls it)
            ; - Flying: Checks X/Y/Z (3D), we control all axes
            if ${This.WithinRangeToDestination[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z},${J_Nav_WaypointTolerance}]}
            {
                if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                    echo [Debug:Navigation] Arrived at waypoint - Distance:${distance.Precision[2]}m, Tolerance:${J_Nav_WaypointTolerance}m, Flying:${J_Nav_Flying}

                ; Only release forward key if:
                ; 1. Final waypoint (always stop precisely)
                ; 2. Already within 1m (was stopped above for safety)
                ; For intermediate waypoints arriving at 1-3m: DON'T release key = smooth flow
                if ${J_Nav_MovingForward}
                {
                    ; Check if this is the final waypoint (UI sets this flag)
                    if ${JBUI_Movement_IsFinalWaypoint(exists)} && ${JBUI_Movement_IsFinalWaypoint}
                    {
                        call This.StopMovingForward
                        echo ${Time}: [Navigation] Final waypoint - releasing forward key
                    }
                    elseif ${distance} <= 1.0
                    {
                        ; Already stopped above, but just in case
                        call This.StopMovingForward
                    }
                    else
                    {
                        if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                            echo [Debug:Navigation] Intermediate waypoint - keeping forward key held for smooth flow
                    }
                }

                break
            }

            ; Emergency bailout - if close enough and stuck, accept it
            if ${distance} <= ${J_Nav_EmergencyBailoutDistance} && ${stuckAttempts} >= 2
            {
                echo ${Time}: [Navigation] EMERGENCY BAILOUT - close enough (${distance.Precision[1]}m <= ${J_Nav_EmergencyBailoutDistance}m) and stuck - accepting position

                ; Release forward key to prevent overshoot
                if ${J_Nav_MovingForward}
                {
                    call This.StopMovingForward
                }

                break
            }

            ; Timer-based stuck detection (checks every 2 seconds)
            if ${J_Nav_EnableStuckDetection} && ${distance} > 2
            {
                if ${This.CheckStuck}
                {
                    stuckAttempts:Inc

                    if ${stuckAttempts} > ${maxStuckAttempts}
                    {
                        echo ${Time}: [Navigation] Failed to unstuck after ${maxStuckAttempts} attempts - aborting waypoint

                        ; Signal to UI that we're stuck (for blacklisting)
                        JBUI_Movement_Stuck:Set[TRUE]

                        break
                    }

                    ; Stop movement for unstuck maneuver
                    call This.StopMovement

                    ; Try unstuck routine
                    call This.UnstuckRoutine ${stuckAttempts}

                    ; Reset stuck detection
                    J_Nav_StuckCounter:Set[0]
                    J_Nav_LastLoc:Set[${Me.Loc}]
                    J_Nav_LastStuckCheck:Set[${System.TickCount}]

                    ; Resume movement
                    call This.StartMoving
                }
            }

            ; Face the waypoint (throttled to reduce zigzagging)
            ; Only adjust heading every 200ms instead of every frame
            if ${Math.Calc[${System.TickCount}-${J_Nav_LastFaceTime}]} >= ${J_Nav_FaceInterval}
            {
                face ${J_Nav_CurrentWaypoint.X} ${J_Nav_CurrentWaypoint.Z}
                J_Nav_LastFaceTime:Set[${System.TickCount}]
            }

            ; When FLYING: Check horizontal distance for safety
            ; If horizontally at waypoint while flying, STOP forward movement (only adjust height)
            ; This prevents running off edges/docks when descending
            if ${J_Nav_Flying}
            {
                if ${This.Distance2D[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}]} < ${J_Nav_Distance2DThreshold}
                {
                    ; Horizontally at waypoint while flying - stop forward movement
                    if ${J_Nav_MovingForward}
                    {
                        call This.StopMovingForward
                        echo ${Time}: [Navigation] Horizontally at waypoint (2D: ${This.Distance2D[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}].Precision[1]}m) - only adjusting height (3D: ${distance.Precision[1]}m)
                    }
                }
                else
                {
                    ; Still need to move forward horizontally
                    if !${J_Nav_MovingForward}
                    {
                        call This.StartMoving
                    }
                }
            }
            else
            {
                ; On ground: Just keep forward key held, 2D arrival detection handles stopping
                if !${J_Nav_MovingForward}
                {
                    call This.StartMoving
                }
            }

            ; Handle vertical movement if flying/swimming (use configurable keys)
            ; BUT: Don't adjust height if we're very close horizontally (prevents drift loop)
            if ${J_Nav_Flying}
            {
                ; If within tight tolerance (0.5m), stop all vertical adjustments to prevent drift
                variable float current2D = ${This.Distance2D[${J_Nav_CurrentWaypoint.X},${J_Nav_CurrentWaypoint.Y},${J_Nav_CurrentWaypoint.Z}]}
                if ${current2D} <= 1.0
                {
                    ; Too close - vertical adjustments cause horizontal drift, just stop
                    press -release ${JNav_FlyUpKey}
                    press -release ${JNav_FlyDownKey}
                }
                elseif ${J_Nav_CurrentWaypoint.Y} > ${Math.Calc[${Me.Y}+${J_Nav_HeightPrecision}]}
                {
                    ; Need to go up
                    press -hold ${JNav_FlyUpKey}
                    press -release ${JNav_FlyDownKey}
                }
                elseif ${J_Nav_CurrentWaypoint.Y} < ${Math.Calc[${Me.Y}-${J_Nav_HeightPrecision}]}
                {
                    ; Need to go down
                    press -hold ${JNav_FlyDownKey}
                    press -release ${JNav_FlyUpKey}
                }
                else
                {
                    ; At correct height - release both
                    press -release ${JNav_FlyUpKey}
                    press -release ${JNav_FlyDownKey}
                }
            }

            waitframe
        }

        ; Don't stop movement - let it flow to next waypoint
        ; call This.StopMovement
    }

    ; =====================================================
    ; STOP MOVEMENT - Release all movement keys
    ; =====================================================

    function StopMovement()
    {
        ; Release all configurable keys
        press -release ${JNav_ForwardKey}
        press -release ${JNav_BackwardKey}
        press -release a
        press -release d
        press -release ${JNav_JumpKey}
        press -release ${JNav_CrouchKey}
        press -release ${JNav_FlyUpKey}
        press -release ${JNav_FlyDownKey}

        J_Nav_Moving:Set[FALSE]
        J_Nav_MovingForward:Set[FALSE]
        J_Nav_MovementEnabled:Set[FALSE]
    }

    ; =====================================================
    ; UNSTUCK ROUTINE - Try different maneuvers
    ; =====================================================

    function UnstuckRoutine(int attemptNumber)
    {
        echo ${Time}: [Navigation] Executing unstuck routine (attempt ${attemptNumber})...

        call This.StopMovement
        waitframe

        switch ${attemptNumber}
        {
            case 1
            ; Try backing up
                echo ${Time}: [Navigation] Unstuck: Backing up
                press -hold ${JNav_BackwardKey}
                wait 5
                press -release ${JNav_BackwardKey}
                waitframe

            ; Jump
                press ${JNav_JumpKey}
                waitframe
                break

            case 2
            ; Try strafing left
                echo ${Time}: [Navigation] Unstuck: Strafing left
                press -hold a
                wait 5
                press -release a
                waitframe

            ; Jump
                press ${JNav_JumpKey}
                waitframe
                break

            case 3
            ; Try strafing right and backing up
                echo ${Time}: [Navigation] Unstuck: Strafing right
                press -hold d
                wait 5
                press -release d

                press -hold ${JNav_BackwardKey}
                wait 5
                press -release ${JNav_BackwardKey}

            ; Multiple jumps
                press ${JNav_JumpKey}
                waitframe
                press ${JNav_JumpKey}
                waitframe
                break
        }

        ; Resume movement after unstuck routine
        J_Nav_Moving:Set[TRUE]
        echo ${Time}: [Navigation] Unstuck routine complete - resuming movement
    }

    ; =====================================================
    ; PRE-BUFF - Basic buff setup before navigation
    ; =====================================================

    function PreBuff()
    {
        echo ${Time}: [Navigation] Pre-buffing...

        ; Target self
        Target ${Me.ID}
        waitframe

        ; Turn on attack if not already
        if !${Me.AutoAttackOn}
        {
            press AUTOATTACK
            waitframe
        }

        echo ${Time}: [Navigation] Pre-buff complete
    }

    ; =====================================================
    ; SINGLE WAYPOINT - Navigate to specific coordinates
    ; =====================================================

    function NavigateToWaypoint(float X, float Y, float Z, float Tolerance=3.0)
    {
        J_Nav_CurrentWaypoint.X:Set[${X}]
        J_Nav_CurrentWaypoint.Y:Set[${Y}]
        J_Nav_CurrentWaypoint.Z:Set[${Z}]
        J_Nav_WaypointTolerance:Set[${Tolerance}]

        echo ${Time}: [Navigation] Navigating to (${X.Precision[1]}, ${Y.Precision[1]}, ${Z.Precision[1]})

        call This.MoveToWaypoint

        echo ${Time}: [Navigation] Reached destination
    }

    ; =====================================================
    ; NAVIGATE FROM JSON STRING - Parse JSON and navigate
    ; =====================================================

    function NavigateFromJSONString(string jsonString, bool reverse, bool preBuff, bool ignoreAggro)
    {
        variable jsonvalue pathData

        ; Parse JSON string
        pathData:SetValue["${jsonString}"]

        if !${pathData.Type.Equal[array]}
        {
            echo ${Time}:  ERROR: Failed to parse JSON path data
            return
        }

        call This.NavigatePath "${pathData}" ${reverse} ${preBuff} ${ignoreAggro}
    }

    ; =====================================================
    ; NAVIGATE FROM FILE - Load and navigate path from file
    ; =====================================================

    function NavigateFromFile(string filePath, bool reverse, bool preBuff, bool ignoreAggro)
    {
        variable jsonvalue pathData
        variable string fileContent

        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] Loading path file: ${filePath}

        ; Check file exists
        if !${System.FileExists["${filePath}"]}
        {
            echo ${Time}:  ERROR: Path file not found: ${filePath}
            return
        }

        ; Read file
        fileContent:Set["${File.Read["${filePath}"]}"]

        if !${fileContent.Length}
        {
            echo ${Time}:  ERROR: Path file is empty: ${filePath}
            return
        }

        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] File read successfully - Content length: ${fileContent.Length} chars

        ; Parse JSON
        pathData:SetValue["${fileContent}"]

        if !${pathData.Type.Equal[array]}
        {
            echo ${Time}:  ERROR: Invalid JSON in path file: ${filePath}
            if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
                echo [Debug:Waypoints] JSON parse failed - Type: ${pathData.Type} (expected: array)
            return
        }

        if ${JBUI_Debug_Waypoints(exists)} && ${JBUI_Debug_Waypoints}
            echo [Debug:Waypoints] JSON parsed successfully - Waypoints: ${pathData.Size}

        echo ${Time}: [Navigation] Loaded path from: ${filePath}

        call This.NavigatePath "${pathData}" ${reverse} ${preBuff} ${ignoreAggro}
    }

    ; =====================================================
    ; CONFIGURATION METHODS
    ; =====================================================

    method SetTolerance(float Tolerance)
    {
        J_Nav_WaypointTolerance:Set[${Tolerance}]
        echo ${Time}: [Navigation] Waypoint tolerance set to ${Tolerance}m
    }

    method EnableStuckDetection()
    {
        J_Nav_EnableStuckDetection:Set[TRUE]
        echo ${Time}: [Navigation] Stuck detection enabled
    }

    method DisableStuckDetection()
    {
        J_Nav_EnableStuckDetection:Set[FALSE]
        echo ${Time}: [Navigation] Stuck detection disabled
    }

    method EnableCombatPause()
    {
        J_Nav_EnableCombatPause:Set[TRUE]
        echo ${Time}: [Navigation] Combat pause enabled
    }

    method DisableCombatPause()
    {
        J_Nav_EnableCombatPause:Set[FALSE]
        echo ${Time}: [Navigation] Combat pause disabled
    }

    ; =====================================================
    ; STATUS & INFO
    ; =====================================================

    method ShowStatus()
    {
        echo ${Time}: ================================================
        echo ${Time}: [Navigation] Status (v${J_Nav_Version})
        echo ${Time}: ================================================
        echo ${Time}: Moving: ${J_Nav_Moving}
        echo ${Time}: Flying: ${J_Nav_Flying}
        echo ${Time}: Current Waypoint: ${J_Nav_CurrentWaypointIndex}
        echo ${Time}: Target: (${J_Nav_CurrentWaypoint.X.Precision[1]}, ${J_Nav_CurrentWaypoint.Y.Precision[1]}, ${J_Nav_CurrentWaypoint.Z.Precision[1]})

        if ${J_Nav_Moving}
        {
            echo ${Time}: Distance: ${Math.Distance[${Me.Loc},${J_Nav_CurrentWaypoint}].Precision[1]}m
        }

        echo ${Time}: Tolerance: ${J_Nav_WaypointTolerance}m
        echo ${Time}: Stuck Detection: ${J_Nav_EnableStuckDetection}
        echo ${Time}: Combat Pause: ${J_Nav_EnableCombatPause}
        echo ${Time}: ================================================
    }

    member:bool IsMoving()
    {
        return ${J_Nav_Moving}
    }

    member:float GetDistanceToWaypoint()
    {
        if ${J_Nav_Moving}
        return ${Math.Distance[${Me.Loc},${J_Nav_CurrentWaypoint}]}
        return 0
    }
}
