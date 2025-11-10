; ================================================================================
; JNavigation_Core.iss - Clean Navigation System from Zero
; ================================================================================
; Based on ISXEQ2 Navigation Library Patterns:
; - Smart movement selection (direct vs pathfinding)
; - Timer-based stuck detection (2-second intervals)
; - Collision and terrain checking
; - Pulse throttling for performance
; - NO external OgreNav dependencies
; ================================================================================

; ================================================================================
; GLOBAL CONFIGURATION
; ================================================================================

variable(global) string JNav_ForwardKey = "w"
variable(global) string JNav_BackwardKey = "s"
variable(global) string JNav_FlyUpKey = "home"
variable(global) string JNav_FlyDownKey = "end"
variable(global) string JNav_JumpKey = "space"

; Debug toggles (controlled by UI)
variable(global) bool JNav_Debug_Movement = FALSE
variable(global) bool JNav_Debug_Stuck = FALSE
variable(global) bool JNav_Debug_Flying = FALSE
variable(global) bool JNav_Debug_Arrival = FALSE

; ================================================================================
; NAVIGATION STATE - Initialize ALL variables to zero
; ================================================================================

variable(global) point3f JNav_CurrentTarget
variable(global) bool JNav_IsNavigating = FALSE
variable(global) bool JNav_IsMovingForward = FALSE
variable(global) bool JNav_IsFlying = FALSE

; ISXEQ2 pattern: Waypoint list for continuous multi-waypoint navigation
variable(global) collection:point3f JNav_WaypointList
variable(global) int JNav_TotalWaypoints = 0
variable(global) int JNav_CurrentWaypointIndex = 0

; Precision thresholds (from ISXEQ2 patterns)
variable(global) float JNav_DirectMovementDistance = 20.0  ; Under 20m = direct movement
variable(global) float JNav_WaypointPrecision = 2.0        ; Tight precision (2m) for waypoints
variable(global) float JNav_DestinationPrecision = 5.0     ; Looser precision (5m) for final destination
variable(global) float JNav_HeightTolerance = 2.0          ; Height difference tolerance

; Timer-based stuck detection (ISXEQ2 pattern: check every 2 seconds)
variable(global) point3f JNav_LastStuckCheckPos
variable(global) uint JNav_LastStuckCheckTime = 0
variable(global) uint JNav_StuckCheckInterval = 2000       ; 2 seconds
variable(global) int JNav_StuckCounter = 0
variable(global) float JNav_MinMovementThreshold = 0.1     ; Must move >0.1m to not be stuck

; Pulse throttling (ISXEQ2 pattern: reduce CPU overhead)
variable(global) uint JNav_LastNavigationPulse = 0
variable(global) uint JNav_NavigationPulseInterval = 50    ; Process every 50ms

; Facing throttling (prevent zigzagging)
variable(global) uint JNav_LastFacingUpdate = 0
variable(global) uint JNav_FacingUpdateInterval = 250      ; Update facing every 250ms

variable(global) string JNav_Version = "3.0.0-Core"

; ================================================================================
; NAVIGATION OBJECT DEFINITION
; ================================================================================

objectdef JNavCore_obj
{
    ; ================================================================================
    ; INITIALIZE - Reset all navigation state to zero
    ; ================================================================================

    ; ================================================================================
    ; MOVEMENT CONTROL - Define these FIRST (called by DirectMovement)
    ; ================================================================================

    function StartForwardMovement()
    {
        if !${JNav_IsMovingForward}
        {
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:NavCore] Pressing forward key '${JNav_ForwardKey}'
            press -hold ${JNav_ForwardKey}
            JNav_IsMovingForward:Set[TRUE]
        }
        else
        {
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:NavCore] Forward already held, not pressing again
        }
    }

    function StopForwardMovement()
    {
        if ${JNav_IsMovingForward}
        {
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:NavCore] Releasing forward key '${JNav_ForwardKey}'
            press -release ${JNav_ForwardKey}
            JNav_IsMovingForward:Set[FALSE]
        }
        else
        {
            if ${JBUI_Debug_Navigation(exists)} && ${JBUI_Debug_Navigation}
                echo [Debug:NavCore] Forward not held, nothing to release
        }
    }

    function StopAllMovement()
    {
        call This.StopForwardMovement

        ; Release all vertical keys
        press -release ${JNav_FlyUpKey}
        press -release ${JNav_FlyDownKey}
    }

    function ReleaseAllKeys()
    {
        press -release ${JNav_ForwardKey}
        press -release ${JNav_BackwardKey}
        press -release a
        press -release d
        press -release ${JNav_JumpKey}
        press -release ${JNav_FlyUpKey}
        press -release ${JNav_FlyDownKey}

        JNav_IsMovingForward:Set[FALSE]
    }

    function Initialize()
    {
        ; Reset all state variables
        JNav_IsNavigating:Set[FALSE]
        JNav_IsMovingForward:Set[FALSE]
        JNav_IsFlying:Set[FALSE]

        JNav_CurrentTarget.X:Set[0]
        JNav_CurrentTarget.Y:Set[0]
        JNav_CurrentTarget.Z:Set[0]

        JNav_LastStuckCheckPos.X:Set[${Me.X}]
        JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
        JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
        JNav_LastStuckCheckTime:Set[${System.TickCount}]
        JNav_StuckCounter:Set[0]

        JNav_LastNavigationPulse:Set[${System.TickCount}]
        JNav_LastFacingUpdate:Set[0]

        ; Release all movement keys
        call This.ReleaseAllKeys
    }

    ; ================================================================================
    ; HELPER FUNCTIONS - Define before DirectMovement calls them
    ; ================================================================================

    function UpdateFlyingState(float heightDiff)
    {
        variable float absHeightDiff = ${Math.Abs[${heightDiff}]}
        variable bool canFly = FALSE

        ; Check if character can fly
        if ${Me.IsSwimming} || ${Me.InWater} || ${Me.FlyingUsingMount} || ${Me.OnFlyingMount}
        {
            canFly:Set[TRUE]
        }

        ; Enable flying if: can fly AND significant height difference (>7m)
        if ${canFly} && ${absHeightDiff} >= 7.0
        {
            if !${JNav_IsFlying} && ${JNav_Debug_Flying}
            {
                echo ${Time}: [NavCore] Enabling flying mode (height diff: ${heightDiff.Precision[1]}m)
            }
            JNav_IsFlying:Set[TRUE]
        }
        ; Disable flying if: can't fly OR close to target height (<5m)
        elseif !${canFly} || ${absHeightDiff} < 5.0
        {
            if ${JNav_IsFlying} && ${JNav_Debug_Flying}
            {
                echo ${Time}: [NavCore] Disabling flying mode (height diff: ${heightDiff.Precision[1]}m)
            }
            JNav_IsFlying:Set[FALSE]
        }
    }

    function HandleVerticalMovement(float heightDiff)
    {
        variable float absHeightDiff = ${Math.Abs[${heightDiff}]}

        ; If height difference is significant, adjust
        if ${absHeightDiff} > ${JNav_HeightTolerance}
        {
            if ${heightDiff} > 0
            {
                ; Need to go up
                press -hold ${JNav_FlyUpKey}
                press -release ${JNav_FlyDownKey}
            }
            else
            {
                ; Need to go down
                press -hold ${JNav_FlyDownKey}
                press -release ${JNav_FlyUpKey}
            }
        }
        else
        {
            ; At correct height
            press -release ${JNav_FlyUpKey}
            press -release ${JNav_FlyDownKey}
        }
    }

    member:bool IsStuck()
    {
        ; Only check every 2 seconds (not every frame!)
        if ${Math.Calc[${System.TickCount} - ${JNav_LastStuckCheckTime}]} < ${JNav_StuckCheckInterval}
            return FALSE

        ; Time to check - compare current position to last check
        variable float distanceMoved = ${Math.Distance[${Me.X},${Me.Y},${Me.Z},${JNav_LastStuckCheckPos.X},${JNav_LastStuckCheckPos.Y},${JNav_LastStuckCheckPos.Z}]}

        if ${distanceMoved} < ${JNav_MinMovementThreshold}
        {
            ; Character hasn't moved enough - increment stuck counter
            JNav_StuckCounter:Inc

            ; Stuck if counter reaches threshold (3 checks * 2 seconds = 6 seconds)
            if ${JNav_StuckCounter} >= 3
            {
                if ${JNav_Debug_Stuck}
                {
                    echo ${Time}: [NavCore] Character stuck (moved ${distanceMoved.Precision[2]}m in ${Math.Calc[${JNav_StuckCounter} * 2]} seconds)
                }
                return TRUE
            }
        }
        else
        {
            ; Made progress - reset counter
            JNav_StuckCounter:Set[0]
        }

        ; Update for next check
        JNav_LastStuckCheckPos.X:Set[${Me.X}]
        JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
        JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
        JNav_LastStuckCheckTime:Set[${System.TickCount}]

        return FALSE
    }

    function UnstuckManeuver()
    {
        if ${JNav_Debug_Stuck}
        {
            echo ${Time}: [NavCore] Executing unstuck maneuver
        }

        ; Back up
        press -hold ${JNav_BackwardKey}
        wait 10
        press -release ${JNav_BackwardKey}

        ; Jump
        press ${JNav_JumpKey}
        wait 5

        ; Strafe left
        press -hold a
        wait 5
        press -release a

        ; Jump again
        press ${JNav_JumpKey}
        wait 5
    }

    member:bool HasArrived(float distance3D, float distance2D, float heightDiff, float precision)
    {
        variable float absHeightDiff = ${Math.Abs[${heightDiff}]}

        ; Flying: Check full 3D distance
        if ${JNav_IsFlying}
        {
            if ${distance3D} <= ${precision}
                return TRUE
        }
        else
        {
            ; Ground: Check 2D (horizontal) AND height separately
            ; ISXEQ2 pattern: Prevent accepting arrival if still climbing/descending
            if ${distance2D} <= ${precision} && ${absHeightDiff} <= ${JNav_HeightTolerance}
                return TRUE
        }

        return FALSE
    }

    ; ================================================================================
    ; CONTINUOUS MULTI-WAYPOINT NAVIGATION (ISXEQ2 Pattern)
    ; ================================================================================

    function ClearWaypointPath()
    {
        JNav_WaypointList:Clear
        JNav_TotalWaypoints:Set[0]
        JNav_CurrentWaypointIndex:Set[0]
    }

    function AddWaypoint(float X, float Y, float Z)
    {
        variable point3f waypoint
        waypoint.X:Set[${X}]
        waypoint.Y:Set[${Y}]
        waypoint.Z:Set[${Z}]

        JNav_WaypointList:Set[${JNav_TotalWaypoints},${waypoint}]
        JNav_TotalWaypoints:Inc

        echo [NavCore] Added waypoint ${JNav_TotalWaypoints}: (${X.Precision[1]}, ${Y.Precision[1]}, ${Z.Precision[1]})
    }

    function StartContinuousNavigation()
    {
        if ${JNav_TotalWaypoints} == 0
        {
            echo [NavCore] ERROR: No waypoints loaded
            return
        }

        echo [NavCore] Starting continuous navigation through ${JNav_TotalWaypoints} waypoints

        JNav_CurrentWaypointIndex:Set[0]
        JNav_IsNavigating:Set[TRUE]

        ; Set first waypoint as target
        JNav_CurrentTarget.X:Set[${JNav_WaypointList.Get[0].X}]
        JNav_CurrentTarget.Y:Set[${JNav_WaypointList.Get[0].Y}]
        JNav_CurrentTarget.Z:Set[${JNav_WaypointList.Get[0].Z}]

        ; Initialize stuck detection
        JNav_LastStuckCheckPos.X:Set[${Me.X}]
        JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
        JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
        JNav_LastStuckCheckTime:Set[${System.TickCount}]
        JNav_StuckCounter:Set[0]

        ; Reset pulse timers
        JNav_LastNavigationPulse:Set[${System.TickCount}]

        ; Start forward movement ONCE
        call This.StartForwardMovement

        echo [NavCore] Continuous navigation initialized - call PulseContinuousNavigation() each frame
    }

    ; ================================================================================
    ; NAVIGATE TO WAYPOINT - Main entry point (Legacy single-waypoint support)
    ; ================================================================================

    function NavigateToWaypoint(float targetX, float targetY, float targetZ, bool isFinalWaypoint=FALSE)
    {
        variable float distance3D = ${Math.Distance[${Me.X},${Me.Y},${Me.Z},${targetX},${targetY},${targetZ}]}
        variable float distance2D = ${Math.Distance[${Me.X},${Me.Z},${targetX},${targetZ}]}

        if ${JNav_Debug_Movement}
        {
            echo ${Time}: [NavCore] Starting navigation to: (${targetX.Precision[1]}, ${targetY.Precision[1]}, ${targetZ.Precision[1]})
            echo ${Time}: [NavCore] Distance: 3D=${distance3D.Precision[1]}m, 2D=${distance2D.Precision[1]}m
        }

        ; Set target
        JNav_CurrentTarget.X:Set[${targetX}]
        JNav_CurrentTarget.Y:Set[${targetY}]
        JNav_CurrentTarget.Z:Set[${targetZ}]

        ; Initialize stuck detection for this waypoint
        JNav_LastStuckCheckPos.X:Set[${Me.X}]
        JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
        JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
        JNav_LastStuckCheckTime:Set[${System.TickCount}]
        JNav_StuckCounter:Set[0]

        ; Reset pulse timers
        JNav_LastNavigationPulse:Set[${System.TickCount}]
        JNav_LastFacingUpdate:Set[0]

        ; SMART MOVEMENT SELECTION (ISXEQ2 pattern)
        ; Direct movement for all distances (pathfinding is future enhancement)
        call This.DirectMovement ${isFinalWaypoint}
    }

    ; ================================================================================
    ; PULSE CONTINUOUS NAVIGATION - Process one frame of continuous navigation (Non-blocking)
    ; ================================================================================
    ; Call this every frame from the Playback thread's State_ContinuousNavigation
    ; Returns immediately after processing one pulse (50ms throttled)

    function PulseContinuousNavigation()
    {
        ; Check if navigation is still active
        if !${JNav_IsNavigating}
            return

        ; PULSE THROTTLING - only process every 50ms
        if ${Math.Calc[${System.TickCount} - ${JNav_LastNavigationPulse}]} < ${JNav_NavigationPulseInterval}
            return

        JNav_LastNavigationPulse:Set[${System.TickCount}]

        ; Calculate distance to current waypoint
        variable float distance3D = ${Math.Distance[${Me.X},${Me.Y},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Y},${JNav_CurrentTarget.Z}]}
        variable float distance2D = ${Math.Distance[${Me.X},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Z}]}
        variable float heightDiff = ${Math.Calc[${JNav_CurrentTarget.Y} - ${Me.Y}]}

        ; ISXEQ2 Pattern: Check if within 2m of current waypoint
        if ${This.HasArrived[${distance3D},${distance2D},${heightDiff},${JNav_WaypointPrecision}]}
        {
            echo [NavCore] Reached waypoint ${Math.Calc[${JNav_CurrentWaypointIndex} + 1]} / ${JNav_TotalWaypoints}

            ; Move to next waypoint
            JNav_CurrentWaypointIndex:Inc

            ; Check if this was the last waypoint
            if ${JNav_CurrentWaypointIndex} >= ${JNav_TotalWaypoints}
            {
                echo [NavCore] Reached FINAL waypoint - stopping
                call This.StopAllMovement
                JNav_IsNavigating:Set[FALSE]
                call This.ClearWaypointPath
                return
            }

            ; Load next waypoint as target - KEEP FORWARD KEY HELD
            JNav_CurrentTarget.X:Set[${JNav_WaypointList.Get[${JNav_CurrentWaypointIndex}].X}]
            JNav_CurrentTarget.Y:Set[${JNav_WaypointList.Get[${JNav_CurrentWaypointIndex}].Y}]
            JNav_CurrentTarget.Z:Set[${JNav_WaypointList.Get[${JNav_CurrentWaypointIndex}].Z}]

            echo [NavCore] Moving to waypoint ${Math.Calc[${JNav_CurrentWaypointIndex} + 1]}: (${JNav_CurrentTarget.X.Precision[1]}, ${JNav_CurrentTarget.Y.Precision[1]}, ${JNav_CurrentTarget.Z.Precision[1]})
        }

        ; Update flying state
        call This.UpdateFlyingState ${heightDiff}

        ; FACE TARGET - ISXEQ2 pattern: face every iteration for smooth curves
        face ${JNav_CurrentTarget.X} ${JNav_CurrentTarget.Z}

        ; Handle vertical movement (flying/swimming)
        if ${JNav_IsFlying}
        {
            call This.HandleVerticalMovement ${heightDiff}
        }

        ; TIMER-BASED STUCK DETECTION
        if ${This.IsStuck}
        {
            echo [NavCore] STUCK detected - attempting recovery
            call This.StopForwardMovement
            call This.UnstuckManeuver

            ; Reset stuck detection
            JNav_LastStuckCheckPos.X:Set[${Me.X}]
            JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
            JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
            JNav_LastStuckCheckTime:Set[${System.TickCount}]
            JNav_StuckCounter:Set[0]

            ; Resume forward movement
            call This.StartForwardMovement
        }
    }

    ; ================================================================================
    ; DIRECT MOVEMENT - Simple point-to-point movement (Legacy single waypoint)
    ; ================================================================================

    function DirectMovement(bool isFinalWaypoint)
    {
        variable float distance3D
        variable float distance2D
        variable float heightDiff
        variable int loopCounter = 0
        variable int maxLoops = 600  ; 60 seconds max (assuming ~10fps)

        JNav_IsNavigating:Set[TRUE]

        ; Determine precision based on waypoint type
        variable float targetPrecision = ${JNav_WaypointPrecision}
        if ${isFinalWaypoint}
        {
            targetPrecision:Set[${JNav_DestinationPrecision}]
            if ${JNav_Debug_Arrival}
            {
                echo ${Time}: [NavCore] Final waypoint - using ${targetPrecision}m precision
            }
        }

        ; Check if we're already at the target
        distance3D:Set[${Math.Distance[${Me.X},${Me.Y},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Y},${JNav_CurrentTarget.Z}]}]
        distance2D:Set[${Math.Distance[${Me.X},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Z}]}]

        if ${distance3D} <= ${targetPrecision}
        {
            if ${JNav_Debug_Arrival}
            {
                echo ${Time}: [NavCore] Already at target (${distance3D.Precision[1]}m <= ${targetPrecision}m)
            }
            JNav_IsNavigating:Set[FALSE]
            return
        }

        ; Determine if we need flying
        heightDiff:Set[${Math.Calc[${JNav_CurrentTarget.Y} - ${Me.Y}]}]
        call This.UpdateFlyingState ${heightDiff}

        ; Start forward movement - don't face first, let the throttled loop handle gradual turning
        ; This creates smooth curved paths between waypoints instead of hard turns
        echo [NavCore] DEBUG: Starting forward movement
        call This.StartForwardMovement

        ; Reset facing timer so we face immediately on first loop iteration
        JNav_LastFacingUpdate:Set[0]

        ; Main navigation loop with pulse throttling
        while ${JNav_IsNavigating}
        {
            loopCounter:Inc

            ; Emergency timeout (ALWAYS log - this is an error)
            if ${loopCounter} > ${maxLoops}
            {
                echo ${Time}: [NavCore] ERROR: TIMEOUT (60 seconds) - stopping navigation
                break
            }

            ; PULSE THROTTLING (ISXEQ2 pattern: reduce CPU overhead)
            ; Only process navigation logic every 50ms, not every frame
            if ${Math.Calc[${System.TickCount} - ${JNav_LastNavigationPulse}]} < ${JNav_NavigationPulseInterval}
            {
                waitframe
                continue
            }
            JNav_LastNavigationPulse:Set[${System.TickCount}]

            ; Calculate current distance
            distance3D:Set[${Math.Distance[${Me.X},${Me.Y},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Y},${JNav_CurrentTarget.Z}]}]
            distance2D:Set[${Math.Distance[${Me.X},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Z}]}]
            heightDiff:Set[${Math.Calc[${JNav_CurrentTarget.Y} - ${Me.Y}]}]

            ; Check if arrived (ISXEQ2 pattern: dual precision system)
            if ${This.HasArrived[${distance3D},${distance2D},${heightDiff},${targetPrecision}]}
            {
                echo [NavCore] DEBUG: ARRIVED - 3D=${distance3D.Precision[1]}m, 2D=${distance2D.Precision[1]}m, height=${heightDiff.Precision[1]}m, precision=${targetPrecision}m
                echo [NavCore] DEBUG: Position - Me:(${Me.X.Precision[1]},${Me.Y.Precision[1]},${Me.Z.Precision[1]}) Target:(${JNav_CurrentTarget.X.Precision[1]},${JNav_CurrentTarget.Y.Precision[1]},${JNav_CurrentTarget.Z.Precision[1]})
                break
            }

            ; Update flying state based on current height difference
            call This.UpdateFlyingState ${heightDiff}

            ; FACE TARGET - ISXEQ2 pattern: call face every iteration for smooth curves
            ; Not throttled - this creates smooth curved paths while moving
            face ${JNav_CurrentTarget.X} ${JNav_CurrentTarget.Z}

            ; Handle vertical movement (flying/swimming)
            if ${JNav_IsFlying}
            {
                call This.HandleVerticalMovement ${heightDiff}
            }

            ; TIMER-BASED STUCK DETECTION (ISXEQ2 pattern: check every 2 seconds)
            if ${This.IsStuck}
            {
                if ${JNav_Debug_Stuck}
                {
                    echo ${Time}: [NavCore] STUCK detected - attempting recovery
                }

                ; Stop and try unstuck maneuver
                call This.StopForwardMovement
                call This.UnstuckManeuver

                ; Reset stuck detection
                JNav_LastStuckCheckPos.X:Set[${Me.X}]
                JNav_LastStuckCheckPos.Y:Set[${Me.Y}]
                JNav_LastStuckCheckPos.Z:Set[${Me.Z}]
                JNav_LastStuckCheckTime:Set[${System.TickCount}]
                JNav_StuckCounter:Set[0]

                ; Resume movement
                call This.StartForwardMovement
            }

            waitframe
        }

        ; Only stop on final waypoint - keep forward held for smooth continuous movement
        ; Character will pass within 2m of waypoint and curve toward next one
        if ${isFinalWaypoint}
        {
            call This.StopAllMovement
        }

        JNav_IsNavigating:Set[FALSE]
    }


    ; ================================================================================
    ; STATUS & INFO
    ; ================================================================================

    method ShowStatus()
    {
        echo ${Time}: ================================================================================
        echo ${Time}: [NavCore] Navigation Status (v${JNav_Version})
        echo ${Time}: ================================================================================
        echo ${Time}: Navigating: ${JNav_IsNavigating}
        echo ${Time}: Moving Forward: ${JNav_IsMovingForward}
        echo ${Time}: Flying: ${JNav_IsFlying}
        echo ${Time}: Current Target: (${JNav_CurrentTarget.X.Precision[1]}, ${JNav_CurrentTarget.Y.Precision[1]}, ${JNav_CurrentTarget.Z.Precision[1]})

        if ${JNav_IsNavigating}
        {
            variable float dist = ${Math.Distance[${Me.X},${Me.Y},${Me.Z},${JNav_CurrentTarget.X},${JNav_CurrentTarget.Y},${JNav_CurrentTarget.Z}]}
            echo ${Time}: Distance to Target: ${dist.Precision[1]}m
        }

        echo ${Time}: Stuck Counter: ${JNav_StuckCounter}
        echo ${Time}: Direct Movement Distance: ${JNav_DirectMovementDistance}m
        echo ${Time}: Waypoint Precision: ${JNav_WaypointPrecision}m
        echo ${Time}: Destination Precision: ${JNav_DestinationPrecision}m
        echo ${Time}: ================================================================================
    }
}

; ================================================================================
; GLOBAL INSTANCE
; ================================================================================

variable(global) JNavCore_obj Obj_JNavCore

; ================================================================================
; JNavigation_Core.iss loaded
; ================================================================================
; Initialization done by Movement thread (JB_UI_Movement.iss)
; Debug toggles controlled by UI:
;   JNav_Debug_Movement - Log movement start/distance
;   JNav_Debug_Stuck    - Log stuck detection/recovery
;   JNav_Debug_Flying   - Log flying mode changes
;   JNav_Debug_Arrival  - Log arrival detection
; ================================================================================
