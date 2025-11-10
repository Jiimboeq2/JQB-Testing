;; ================================================================================
;; JB_UI_PLAYBACK.ISS - Thread #3: Non-blocking Playback Processing
;; ================================================================================
;; Purpose: Process waypoints and commands without blocking the UI thread
;; Architecture: State machine with waitframe - no blocking while loops
;; Communication: Via global variables with UI thread
;; Updated: Now using JNavigation_Core.iss (ISXEQ2 patterns-based navigation)
;; ================================================================================

; Include required libraries
#include "${Script.CurrentDirectory}/../JB/Navigation/JNavigation_Core.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_PlaybackCommands.iss"

; ================================================================================
; PLAYBACK STATE MACHINE
; ================================================================================

variable(global) string JBUI_Playback_State = "IDLE"
variable(global) uint JBUI_Playback_StateStartTime = 0
variable(global) uint JBUI_Playback_CommandWaitUntil = 0

; Cached current item data
variable(global) string JBUI_Playback_CurrentType = ""
variable(global) string JBUI_Playback_CurrentData = ""

; Movement timeout
variable(global) uint JBUI_Playback_MovementStartTime = 0
variable(global) uint JBUI_Playback_MovementTimeout = 30000  ; 30 seconds

; ISXEQ2 Pattern: Continuous navigation mode
variable(global) bool JBUI_Playback_ContinuousMode = FALSE

; Command storage - commands indexed by waypoint number
; Format: "waypointIndex|commandName|params"
variable(global) collection:string JBUI_Playback_Commands

; ================================================================================
; MAIN THREAD LOOP - NON-BLOCKING
; ================================================================================

function main()
{
    echo [PlaybackThread] Started - non-blocking playback processor (Thread #3)
    echo [PlaybackThread] This thread runs independently from UI - no freezing!
    if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
        echo [Debug:Playback] Thread initialized - State:IDLE, Ready to process playback commands

    ; Initialize state
    JBUI_Playback_State:Set["IDLE"]

    ; Main loop - runs every frame, never blocks
    while ${Script[JB_UI_Playback](exists)}
    {
        ; Check if playback was stopped externally
        if !${JBUI_Playback_IsPlaying}
        {
            if !${JBUI_Playback_State.Equal["STOPPED"]}
            {
                echo [PlaybackThread] Playback stopped externally - cleaning up
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] Stop detected - CurrentState:${JBUI_Playback_State}, Calling cleanup
                call Playback_Cleanup
                JBUI_Playback_State:Set["STOPPED"]
            }
            waitframe
            continue
        }

        ; Check if paused
        if ${JBUI_Playback_IsPaused}
        {
            if !${JBUI_Playback_State.Equal["PAUSED"]}
            {
                echo [PlaybackThread] Paused at item ${JBUI_Playback_CurrentIndex}
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] Pause detected - CurrentIndex:${JBUI_Playback_CurrentIndex}, State:${JBUI_Playback_State}
                JBUI_Playback_State:Set["PAUSED"]
            }
            waitframe
            continue
        }

        ; Process current state
        switch ${JBUI_Playback_State}
        {
            case IDLE
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] State:IDLE - Processing initialization
                call State_Idle
                break

            case WAITING_MOVEMENT
                call State_WaitingMovement
                break

            case CONTINUOUS_NAVIGATION
                call State_ContinuousNavigation
                break

            case EXECUTING_COMMAND
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] State:EXECUTING_COMMAND - Processing command execution
                call State_ExecutingCommand
                break

            case PAUSED
                ; Already handled above - resume to IDLE when unpaused
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] State:PAUSED - Resuming to IDLE
                JBUI_Playback_State:Set["IDLE"]
                break

            case STOPPED
                ; Do nothing - waiting for restart
                break

            default
                echo [PlaybackThread] ERROR: Unknown state ${JBUI_Playback_State}
                JBUI_Playback_State:Set["IDLE"]
                break
        }

        ; Critical: waitframe at end of loop to prevent blocking
        waitframe
    }

    echo [PlaybackThread] Thread ending
    if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
        echo [Debug:Playback] Thread shutdown complete
}

; ================================================================================
; STATE: IDLE - Load waypoints and start continuous navigation
; ================================================================================

function State_Idle()
{
    ; ISXEQ2 Pattern: On first call, load ALL waypoints and start continuous navigation
    if ${JBUI_Playback_CurrentIndex} == 0 && !${JBUI_Playback_ContinuousMode}
    {
        echo [PlaybackThread] === ISXEQ2 Pattern: Loading all waypoints upfront ===
        if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
            echo [Debug:Playback] Loading waypoints - CurrentIndex:0, ContinuousMode:FALSE, Starting initialization
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loading waypoints..."]

        ; Clear waypoint list
        call Obj_JNavCore.ClearWaypointPath

        ; Load all waypoints from file into collection
        call LoadAllWaypoints

        if ${JNav_TotalWaypoints} == 0
        {
            echo [PlaybackThread] ERROR: No waypoints loaded
            if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                echo [Debug:Playback] CRITICAL ERROR - No waypoints loaded from file, stopping playback
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: No waypoints found"]
            JBUI_Playback_IsPlaying:Set[FALSE]
            JBUI_Playback_State:Set["STOPPED"]
            return
        }

        echo [PlaybackThread] Loaded ${JNav_TotalWaypoints} waypoints - starting continuous navigation
        if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
            echo [Debug:Playback] Waypoints loaded successfully - Total:${JNav_TotalWaypoints}, Starting continuous navigation mode
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Starting continuous navigation (${JNav_TotalWaypoints} waypoints)"]

        ; Start continuous navigation ONCE
        call Obj_JNavCore.StartContinuousNavigation

        ; Enter continuous navigation mode
        JBUI_Playback_ContinuousMode:Set[TRUE]
        JBUI_Playback_State:Set["CONTINUOUS_NAVIGATION"]
        JBUI_Playback_MovementStartTime:Set[${System.TickCount}]
        if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
            echo [Debug:Playback] State transition - From:IDLE To:CONTINUOUS_NAVIGATION, ContinuousMode:TRUE
        return
    }

    ; If we get here in continuous mode, something went wrong
    if ${JBUI_Playback_ContinuousMode}
    {
        echo [PlaybackThread] ERROR: State_Idle called while in continuous mode
        JBUI_Playback_State:Set["CONTINUOUS_NAVIGATION"]
        return
    }

    ; Legacy path (shouldn't reach here in normal operation)
    echo [PlaybackThread] ERROR: Unexpected state - resetting
    JBUI_Playback_IsPlaying:Set[FALSE]
    JBUI_Playback_State:Set["STOPPED"]
}

; ================================================================================
; STATE: WAITING_MOVEMENT - Check if movement completed
; ================================================================================

function State_WaitingMovement()
{
    ; Check if movement completed
    if !${JBUI_Movement_Active}
    {
        variable float distance = ${Math.Distance[${Me.Loc},${JBUI_Movement_TargetX},${JBUI_Movement_TargetY},${JBUI_Movement_TargetZ}]}

        if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
            echo [Debug:Playback] Movement completed - JBUI_Movement_Active:FALSE, Distance:${distance.Precision[2]}m, Stuck:${JBUI_Movement_Stuck}

        ; Check if stuck
        if ${JBUI_Movement_Stuck}
        {
            echo [PlaybackThread] Movement STUCK - blacklisting waypoint location
            if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                echo [Debug:Playback] Stuck detected - Target:(${JBUI_Movement_TargetX.Precision[1]},${JBUI_Movement_TargetY.Precision[1]},${JBUI_Movement_TargetZ.Precision[1]}), Adding to blacklist
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["STUCK - blacklisting location"]

            ; Add to blacklist
            if ${JBUI_Stuck_Count} < 10
            {
                JBUI_Stuck_X[${JBUI_Stuck_Count}]:Set[${JBUI_Movement_TargetX}]
                JBUI_Stuck_Y[${JBUI_Stuck_Count}]:Set[${JBUI_Movement_TargetY}]
                JBUI_Stuck_Z[${JBUI_Stuck_Count}]:Set[${JBUI_Movement_TargetZ}]
                JBUI_Stuck_Count:Inc
                echo [PlaybackThread] Blacklisted stuck zone #${JBUI_Stuck_Count}
                if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                    echo [Debug:Playback] Blacklist updated - Count:${JBUI_Stuck_Count}/10
            }

            ; Reset stuck flag
            JBUI_Movement_Stuck:Set[FALSE]
        }
        else
        {
            echo [PlaybackThread] Arrived at waypoint (final distance: ${distance.Precision[1]}m)
            if ${JBUI_Debug_Playback(exists)} && ${JBUI_Debug_Playback}
                echo [Debug:Playback] Waypoint reached successfully - Distance:${distance.Precision[2]}m, No stuck detected
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Arrived (distance: ${distance.Precision[1]}m)"]
        }

        ; Move to next item
        JBUI_Playback_CurrentIndex:Inc
        UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]

        ; Return to IDLE to process next item
        JBUI_Playback_State:Set["IDLE"]
        return
    }

    ; Check for timeout (30 seconds)
    if ${Math.Calc[${System.TickCount} - ${JBUI_Playback_MovementStartTime}]} > ${JBUI_Playback_MovementTimeout}
    {
        echo [PlaybackThread] Movement timeout (30 seconds) - canceling
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Movement timeout - canceled"]

        ; Cancel movement
        JBUI_Movement_Active:Set[FALSE]

        ; Move to next item
        JBUI_Playback_CurrentIndex:Inc
        UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]

        JBUI_Playback_State:Set["IDLE"]
    }

    ; Still waiting - will check again next frame
}

; ================================================================================
; STATE: CONTINUOUS_NAVIGATION - Monitor continuous navigation progress
; ================================================================================

function State_ContinuousNavigation()
{
    ; Pulse the continuous navigation (non-blocking - returns immediately)
    call Obj_JNavCore.PulseContinuousNavigation

    ; Check if navigation completed
    if !${JNav_IsNavigating}
    {
        echo [PlaybackThread] === Continuous navigation completed ===
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Navigation completed!"]

        ; Check for loop mode
        if ${JBUI_Loop}
        {
            echo [PlaybackThread] Loop mode: Restarting path from beginning
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loop: Restarting path..."]

            ; Reset continuous mode flag
            JBUI_Playback_ContinuousMode:Set[FALSE]
            JBUI_Playback_CurrentIndex:Set[0]

            ; Return to IDLE to reload waypoints
            JBUI_Playback_State:Set["IDLE"]
            return
        }
        else
        {
            ; Finished - signal stop
            echo [PlaybackThread] Playback completed - all waypoints reached
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["=== PLAYBACK COMPLETED ==="]

            ; Stop playback
            JBUI_Playback_IsPlaying:Set[FALSE]
            JBUI_Playback_ContinuousMode:Set[FALSE]
            JBUI_Playback_State:Set["STOPPED"]
            return
        }
    }

    ; Update UI with current waypoint progress (real-time updates!)
    variable int previousIndex = ${JBUI_Playback_CurrentIndex}
    JBUI_Playback_CurrentIndex:Set[${JNav_CurrentWaypointIndex}]
    UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${Math.Calc[${JNav_CurrentWaypointIndex}+1]} / ${JNav_TotalWaypoints}"]

    ; Execute commands when waypoint changes
    if ${JBUI_Playback_CurrentIndex} != ${previousIndex}
    {
        call ExecuteCommandsAtWaypoint ${Math.Calc[${JBUI_Playback_CurrentIndex}+1]}
    }

    ; Check for timeout (5 minutes for entire path)
    variable uint totalTimeout = 300000
    if ${Math.Calc[${System.TickCount} - ${JBUI_Playback_MovementStartTime}]} > ${totalTimeout}
    {
        echo [PlaybackThread] Navigation timeout (5 minutes) - canceling
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Navigation timeout - canceled"]

        ; Stop navigation
        call Obj_JNavCore.StopAllMovement
        JNav_IsNavigating:Set[FALSE]

        ; Stop playback
        JBUI_Playback_IsPlaying:Set[FALSE]
        JBUI_Playback_ContinuousMode:Set[FALSE]
        JBUI_Playback_State:Set["STOPPED"]
    }

    ; Still navigating - will pulse again next frame
}

; ================================================================================
; STATE: EXECUTING_COMMAND - Check if command completed
; ================================================================================

function State_ExecutingCommand()
{
    ; Check if wait time elapsed
    if ${System.TickCount} >= ${JBUI_Playback_CommandWaitUntil}
    {
        echo [PlaybackThread] Command execution completed

        ; Move to next item
        JBUI_Playback_CurrentIndex:Inc
        UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]

        ; Return to IDLE
        JBUI_Playback_State:Set["IDLE"]
    }

    ; Still waiting for command to complete
}

; ================================================================================
; PROCESS WAYPOINT - Initiate movement (non-blocking)
; ================================================================================

function ProcessWaypoint(string xmlLine)
{
    echo [PlaybackThread] ProcessWaypoint: ${xmlLine}

    ; Parse coordinates from XML using Token method (simple and reliable)
    ; Format: <Waypoint X="VALUE" Y="VALUE" Z="VALUE" />
    ; Split on quotes: Token 2 is X, Token 4 is Y, Token 6 is Z
    variable string xVal
    variable string yVal
    variable string zVal

    variable int tokenCount = ${xmlLine.Count["\""]}
    if ${tokenCount} >= 6
    {
        xVal:Set["${xmlLine.Token[2,"\""]}"]
        yVal:Set["${xmlLine.Token[4,"\""]}"]
        zVal:Set["${xmlLine.Token[6,"\""]}"]
    }

    ; Validate coordinates (check if we got valid strings)
    if ${xVal.Length} == 0 || ${yVal.Length} == 0 || ${zVal.Length} == 0
    {
        echo [PlaybackThread] ERROR: Failed to parse waypoint coordinates
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Invalid waypoint"]

        ; Skip to next
        JBUI_Playback_CurrentIndex:Inc
        UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]
        JBUI_Playback_State:Set["IDLE"]
        return
    }

    variable float distance = ${Math.Distance[${Me.Loc},${xVal},${yVal},${zVal}]}
    echo [PlaybackThread] Moving to (${xVal}, ${yVal}, ${zVal}) - Distance: ${distance.Precision[1]}m
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Moving to: (${xVal}, ${yVal}, ${zVal}) - ${distance.Precision[1]}m"]

    ; Check if blacklisted
    variable int i
    for (i:Set[0] ; ${i} < ${JBUI_Stuck_Count} ; i:Inc)
    {
        variable float blacklistDist = ${Math.Distance[${xVal},${yVal},${zVal},${JBUI_Stuck_X[${i}]},${JBUI_Stuck_Y[${i}]},${JBUI_Stuck_Z[${i}]}]}

        if ${blacklistDist} < ${JBUI_Stuck_Blacklist_Radius}
        {
            echo [PlaybackThread] SKIPPING - too close to stuck zone #${i} (${blacklistDist.Precision[1]}m)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["SKIPPED - near stuck zone"]

            ; Skip to next
            JBUI_Playback_CurrentIndex:Inc
            UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]
            JBUI_Playback_State:Set["IDLE"]
            return
        }
    }

    ; Check if movement thread running
    if !${Script[JB_UI_Movement](exists)}
    {
        echo [PlaybackThread] ERROR: Movement thread not running
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Movement thread not running"]

        ; Stop playback
        JBUI_Playback_IsPlaying:Set[FALSE]
        JBUI_Playback_State:Set["STOPPED"]
        return
    }

    ; Set waypoint marker
    eq2execute waypoint ${xVal} ${yVal} ${zVal}

    ; Send movement request to movement thread
    JBUI_Movement_TargetX:Set[${xVal}]
    JBUI_Movement_TargetY:Set[${yVal}]
    JBUI_Movement_TargetZ:Set[${zVal}]
    JBUI_Movement_Arrived:Set[FALSE]
    JBUI_Movement_Stuck:Set[FALSE]

    ; Debug: Verify values were set
    echo [PlaybackThread] Set coordinates: X=${JBUI_Movement_TargetX} Y=${JBUI_Movement_TargetY} Z=${JBUI_Movement_TargetZ}

    ; Check if this is the final waypoint
    variable int nextIndex = ${Math.Calc[${JBUI_Playback_CurrentIndex} + 1]}
    if ${nextIndex} >= ${JBUI_Playback_TotalItems}
    {
        JBUI_Movement_IsFinalWaypoint:Set[TRUE]
    }
    else
    {
        JBUI_Movement_IsFinalWaypoint:Set[FALSE]
    }

    JBUI_Movement_Active:Set[TRUE]

    ; Record start time for timeout
    JBUI_Playback_MovementStartTime:Set[${System.TickCount}]

    ; Transition to WAITING_MOVEMENT state
    JBUI_Playback_State:Set["WAITING_MOVEMENT"]
    echo [PlaybackThread] Waiting for movement to complete (non-blocking)...
}

; ================================================================================
; PROCESS COMMAND - Execute command (non-blocking where possible)
; ================================================================================

function ProcessCommand(string xmlLine)
{
    echo [PlaybackThread] ProcessCommand: ${xmlLine}

    ; Parse command type
    variable string cmdType = ""
    variable string cmdValue = ""

    ; Extract Type attribute
    variable int typeStart = ${xmlLine.Find["Type=\""]}
    if ${typeStart} > 0
    {
        typeStart:Set[${Math.Calc[${typeStart}+6]}]
        variable int typeEnd = ${xmlLine.Find["\"", ${typeStart}]}
        if ${typeEnd} > 0
        {
            cmdType:Set[${xmlLine.Mid[${typeStart}, ${Math.Calc[${typeEnd}-${typeStart}]}]}]
        }
    }

    ; Extract Value attribute
    variable int valueStart = ${xmlLine.Find["Value=\""]}
    if ${valueStart} > 0
    {
        valueStart:Set[${Math.Calc[${valueStart}+7]}]
        variable int valueEnd = ${xmlLine.Find["\"", ${valueStart}]}
        if ${valueEnd} > 0
        {
            cmdValue:Set[${xmlLine.Mid[${valueStart}, ${Math.Calc[${valueEnd}-${valueStart}]}]}]
        }
    }

    if ${cmdType.Length} == 0
    {
        echo [PlaybackThread] ERROR: Failed to parse command type
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Invalid command"]

        ; Skip to next
        JBUI_Playback_CurrentIndex:Inc
        UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]
        JBUI_Playback_State:Set["IDLE"]
        return
    }

    echo [PlaybackThread] Command: ${cmdType} = ${cmdValue}
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Command: ${cmdType} ${cmdValue}"]

    ; Handle simple commands that execute immediately
    switch ${cmdType}
    {
        case Wait
            ; Convert seconds to milliseconds
            variable int waitMs = ${Math.Calc[${cmdValue} * 1000]}
            JBUI_Playback_CommandWaitUntil:Set[${Math.Calc[${System.TickCount} + ${waitMs}]}]

            echo [PlaybackThread] Waiting ${cmdValue} seconds (non-blocking)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Waiting ${cmdValue} seconds"]

            ; Transition to EXECUTING_COMMAND state
            JBUI_Playback_State:Set["EXECUTING_COMMAND"]
            return

        default
            ; For now, other commands execute immediately and we move to next item
            ; TODO: Implement non-blocking versions of other commands
            echo [PlaybackThread] Command type '${cmdType}' not yet implemented in non-blocking playback
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Command '${cmdType}' - TODO"]

            ; Move to next item immediately
            JBUI_Playback_CurrentIndex:Inc
            UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]
            JBUI_Playback_State:Set["IDLE"]
            break
    }
}

; ================================================================================
; LOAD ITEM FROM FILE - Read current item from XML
; ================================================================================

function LoadItemFromFile()
{
    ; This function reads the file and finds the item at JBUI_Playback_CurrentIndex
    ; Returns: "waypoint" or "command" or "" (empty on error)
    ; Sets: JBUI_Playback_CurrentData with the XML line

    JBUI_Playback_CurrentData:Set[""]

    ; Only XML supported
    if !${JBUI_Playback_PathFile.Find[".xml"]}
    {
        echo [PlaybackThread] ERROR: Only XML playback supported
        return ""
    }

    variable file f
    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    variable string line
    variable int currentItem = 0

    while !${f.EOF}
    {
        ; Read line ONCE per iteration (don't check exists, just read)
        line:Set["${f.Read}"]
        if ${line.Length} == 0
            continue

        ; Check for waypoint (space after ensures it's not <Waypoints> container)
        if ${line.Find["<Waypoint "]} >= 0
        {
            if ${currentItem} == ${JBUI_Playback_CurrentIndex}
            {
                JBUI_Playback_CurrentData:Set["${line}"]
                f:Close
                return "waypoint"
            }
            currentItem:Inc
        }

        ; Check for command
        if ${line.Find["<Command "]} >= 0
        {
            if ${currentItem} == ${JBUI_Playback_CurrentIndex}
            {
                JBUI_Playback_CurrentData:Set["${line}"]
                f:Close
                return "command"
            }
            currentItem:Inc
        }
    }

    f:Close
    echo [PlaybackThread] ERROR: Could not find item ${JBUI_Playback_CurrentIndex} in file
    return ""
}

; ================================================================================
; PEEK NEXT WAYPOINT - Load next waypoint coordinates for lookahead
; ================================================================================

function PeekNextWaypoint(int targetIndex)
{
    ; This function peeks at the next waypoint in the file (targetIndex)
    ; Sets: JBUI_Movement_NextX/Y/Z and JBUI_Movement_HasNext

    ; Open file
    variable file f
    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    ; Read through file counting waypoints/commands
    variable string line
    variable int currentItem = 0

    while !${f.EOF}
    {
        ; Read line
        line:Set["${f.Read}"]

        ; Skip empty lines and comments
        if ${line.Length} == 0
            continue
        if ${line.Left[1].Equal["#"]}
            continue

        ; Check for waypoint (space after ensures it's not <Waypoints> container)
        if ${line.Find["<Waypoint "]} >= 0
        {
            if ${currentItem} == ${targetIndex}
            {
                ; Found next waypoint - parse coordinates to string variables first
                variable int tokenCount = ${line.Count["\""]}
                if ${tokenCount} >= 6
                {
                    variable string nextXStr
                    variable string nextYStr
                    variable string nextZStr

                    nextXStr:Set["${line.Token[2,"\""]}"]
                    nextYStr:Set["${line.Token[4,"\""]}"]
                    nextZStr:Set["${line.Token[6,"\""]}"]

                    ; Now set global float variables (no quotes around variable expansion)
                    JBUI_Movement_NextX:Set[${nextXStr}]
                    JBUI_Movement_NextY:Set[${nextYStr}]
                    JBUI_Movement_NextZ:Set[${nextZStr}]
                    JBUI_Movement_HasNext:Set[TRUE]
                    echo [PlaybackThread] Lookahead: Next waypoint at (${JBUI_Movement_NextX}, ${JBUI_Movement_NextY}, ${JBUI_Movement_NextZ})
                }
                else
                {
                    echo [PlaybackThread] ERROR: Could not parse next waypoint - token count ${tokenCount}
                    JBUI_Movement_HasNext:Set[FALSE]
                }
                f:Close
                return
            }
            currentItem:Inc
        }

        ; Check for command (skip - we only lookahead for waypoints)
        if ${line.Find["<Command "]} >= 0
        {
            currentItem:Inc
        }
    }

    f:Close
    echo [PlaybackThread] ERROR: Could not find next waypoint at index ${targetIndex}
    JBUI_Movement_HasNext:Set[FALSE]
}

; ================================================================================
; EXECUTE COMMANDS AT WAYPOINT
; ================================================================================

function ExecuteCommandsAtWaypoint(int waypointIndex)
{
    ; Check each stored command to see if it matches this waypoint
    variable iterator cmdIter
    JBUI_Playback_Commands:GetIterator[cmdIter]

    if !${cmdIter:First(exists)}
        return

    do
    {
        ; Parse command data: "waypointIndex|commandName|params"
        variable string cmdData = "${cmdIter.Value}"
        variable int cmdWpIndex
        variable string cmdName
        variable string cmdParams

        ; Find first pipe
        variable int pipe1 = ${cmdData.Find["|"]}
        if ${pipe1} < 0
            continue

        ; Extract waypoint index
        cmdWpIndex:Set["${cmdData.Left[${pipe1}]}"]

        ; Check if this command is for the current waypoint
        if ${cmdWpIndex} != ${waypointIndex}
            continue

        ; Find second pipe
        variable int pipe2 = ${cmdData.Find["|", ${Math.Calc[${pipe1}+1]}]}
        if ${pipe2} < 0
            continue

        ; Extract command name
        cmdName:Set["${cmdData.Mid[${Math.Calc[${pipe1}+1]}, ${Math.Calc[${pipe2}-${pipe1}-1]}]}"]

        ; Extract params (everything after second pipe)
        cmdParams:Set["${cmdData.Right[${Math.Calc[${cmdData.Length}-${pipe2}-1]}]}"]

        ; Execute command via CommandManager
        echo [PlaybackThread] Executing command at waypoint ${waypointIndex}: ${cmdName} ${cmdParams}
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Executing: ${cmdName}"]

        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
            echo [Debug:Commands] Waypoint ${waypointIndex} -> ${cmdName} (${cmdParams})

        ; Wait for any previous command to finish
        while ${JBCmdManager.IsExecuting}
        {
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Waiting for previous command to complete...
            wait 1
        }

        ; Execute via CommandManager
        if !${JBCmdManager.ExecuteCommand["${cmdName}", "${cmdParams}"]}
        {
            echo [PlaybackThread] WARNING: Command execution failed: ${cmdName}
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Command failed: ${cmdName}"]
        }
    }
    while ${cmdIter:Next(exists)}
}

; ================================================================================
; LOAD ALL WAYPOINTS - ISXEQ2 Pattern: Load entire waypoint list upfront
; ================================================================================

function LoadAllWaypoints()
{
    echo [PlaybackThread] === Loading all waypoints and commands from file ===

    ; Only XML supported
    if !${JBUI_Playback_PathFile.Find[".xml"]}
    {
        echo [PlaybackThread] ERROR: Only XML playback supported
        return
    }

    ; Clear previous commands
    JBUI_Playback_Commands:Clear

    ; Open file
    variable file f
    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    variable string line
    variable int waypointCount = 0
    variable int commandCount = 0

    ; Declare coordinate variables outside loop to avoid redeclaration
    variable string xVal
    variable string yVal
    variable string zVal
    variable int xStart
    variable int xEnd
    variable int yStart
    variable int yEnd
    variable int zStart
    variable int zEnd

    while !${f.EOF}
    {
        ; Read line
        line:Set["${f.Read}"]
        if ${line.Length} == 0
            continue

        ; Reset coordinate values for each line to prevent carryover
        xVal:Set[""]
        yVal:Set[""]
        zVal:Set[""]

        ; Check for waypoint tag (must have space after to avoid matching <Waypoints> container)
        ; Pattern: <Waypoint X="..." (space after "Waypoint" ensures it's a waypoint tag, not container)
        if ${line.Find["<Waypoint "]} >= 0
        {
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] Parsing waypoint line: ${line}

            ; Parse coordinates using substring extraction with Find
            ; Format: <Waypoint X="VALUE" Y="VALUE" Z="VALUE" />

            ; Find X="..." and extract value
            xStart:Set[${line.Find["X="]}]
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] xStart position = ${xStart}

            if ${xStart} >= 0
            {
                ; Skip past X=" (3 characters: X, =, ")
                xStart:Set[${Math.Calc[${xStart} + 3]}]
                ; Find closing quote starting from xStart
                xEnd:Set[${line.Find[" Y=", ${xStart}]}]

                if ${xEnd} > ${xStart}
                {
                    ; Subtract 1 to exclude the closing quote
                    xEnd:Set[${Math.Calc[${xEnd} - 1]}]
                    xVal:Set["${line.Mid[${xStart}, ${Math.Calc[${xEnd} - ${xStart}]}]}"]
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Playback] Extracted X = ${xVal}
                }
            }

            ; Find Y="..." and extract value
            yStart:Set[${line.Find["Y="]}]
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] yStart position = ${yStart}

            if ${yStart} >= 0
            {
                yStart:Set[${Math.Calc[${yStart} + 3]}]
                yEnd:Set[${line.Find[" Z=", ${yStart}]}]

                if ${yEnd} > ${yStart}
                {
                    yEnd:Set[${Math.Calc[${yEnd} - 1]}]
                    yVal:Set["${line.Mid[${yStart}, ${Math.Calc[${yEnd} - ${yStart}]}]}"]
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Playback] Extracted Y = ${yVal}
                }
            }

            ; Find Z="..." and extract value
            ; Z is last attribute, search for "/> pattern that ends the tag
            zStart:Set[${line.Find["Z="]}]
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] zStart position = ${zStart}

            if ${zStart} >= 0
            {
                ; Skip past Z=" (3 characters: Z, =, ")
                zStart:Set[${Math.Calc[${zStart} + 3]}]

                ; Find the end pattern " />" - space before the closing tag
                ; X looks for " Y=", Y looks for " Z=", Z looks for " />"
                zEnd:Set[${line.Find[" />", ${zStart}]}]

                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Playback] Z end search - zStart=${zStart}, zEnd=${zEnd}

                if ${zEnd} > ${zStart}
                {
                    ; Subtract 1 to exclude the closing quote (same as X and Y do)
                    zEnd:Set[${Math.Calc[${zEnd} - 1]}]
                    zVal:Set["${line.Mid[${zStart}, ${Math.Calc[${zEnd} - ${zStart}]}]}"]
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Playback] Extracted Z = ${zVal}
                }
                else
                {
                    echo [PlaybackThread] WARNING: Could not find '\"/>\" pattern for Z coordinate (zStart=${zStart}, zEnd=${zEnd})
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Playback] Problem line: ${line}
                }
            }

            ; Validate coordinates
            if ${xVal.Length} > 0 && ${yVal.Length} > 0 && ${zVal.Length} > 0
            {
                ; Add waypoint to collection
                call Obj_JNavCore.AddWaypoint ${xVal} ${yVal} ${zVal}
                waypointCount:Inc

                echo [PlaybackThread] Added waypoint ${waypointCount}: (${xVal}, ${yVal}, ${zVal})
            }
            else
            {
                echo [PlaybackThread] WARNING: Skipping waypoint with invalid coordinates (X=${xVal} Y=${yVal} Z=${zVal})
            }
        }
        ; Check for command tag (only if not a waypoint line)
        ; Supports two formats:
        ; 1. Type/Value format: <Command Type="Special" /> or <Command Type="Wait" Value="5" />
        ; 2. Name/Params format: <Command Name="CommandName" Params="..." WaypointIndex="1" />
        ; Space after "Command" ensures it's a command tag with attributes
        elseif ${line.Find["<Command "]} >= 0
        {
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] Command check passed for: ${line}
            else
                echo [PlaybackThread] Parsing command line: ${line}

            variable string cmdName = ""
            variable string cmdParams = ""
            variable int wpIndex = ${waypointCount}  ; Attach to last successfully parsed waypoint

            ; Declare reusable variables for quote position finding
            variable int openQuote
            variable int closeQuote

            ; Try to extract Type="..."
            variable int typePos = ${line.Find["Type=\""]}
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] typePos = ${typePos}

            if ${typePos} >= 0
            {
                ; Find opening quote position (after Type=)
                openQuote:Set[${Math.Calc[${typePos} + 5]}]
                ; Find closing quote
                closeQuote:Set[${line.Find["\"", ${Math.Calc[${openQuote} + 1]}]}]

                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Playback] Type extraction - openQuote=${openQuote}, closeQuote=${closeQuote}

                if ${closeQuote} > ${openQuote}
                {
                    variable int typeLength = ${Math.Calc[${closeQuote} - ${openQuote} - 1]}
                    if ${typeLength} > 0 && ${typeLength} < 50
                    {
                        cmdName:Set["${line.Mid[${Math.Calc[${openQuote} + 1]}, ${typeLength}]}"]
                        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                            echo [Debug:Playback] Extracted Type = ${cmdName}
                        else
                            echo [PlaybackThread] Found command Type = ${cmdName}
                    }
                    else
                    {
                        echo [PlaybackThread] ERROR: Invalid Type extraction length: ${typeLength}
                    }
                }
                else
                {
                    echo [PlaybackThread] ERROR: Could not find Type closing quote
                }
            }

            ; Try to extract Value="..." if present
            variable int valuePos = ${line.Find["Value=\""]}
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Playback] valuePos = ${valuePos}

            if ${valuePos} >= 0
            {
                openQuote:Set[${Math.Calc[${valuePos} + 6]}]
                closeQuote:Set[${line.Find["\"", ${Math.Calc[${openQuote} + 1]}]}]

                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Playback] Value extraction - openQuote=${openQuote}, closeQuote=${closeQuote}

                if ${closeQuote} > ${openQuote}
                {
                    variable int valueLength = ${Math.Calc[${closeQuote} - ${openQuote} - 1]}
                    if ${valueLength} > 0 && ${valueLength} < 200
                    {
                        cmdParams:Set["${line.Mid[${Math.Calc[${openQuote} + 1]}, ${valueLength}]}"]
                        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                            echo [Debug:Playback] Extracted Value = ${cmdParams}
                        else
                            echo [PlaybackThread] Found command Value = ${cmdParams}
                    }
                    else
                    {
                        echo [PlaybackThread] ERROR: Invalid Value extraction length: ${valueLength}
                    }
                }
                else
                {
                    echo [PlaybackThread] ERROR: Could not find Value closing quote
                }
            }

            ; If Type not found, try Name="..." format
            if ${cmdName.Length} == 0
            {
                variable int namePos = ${line.Find["Name=\""]}
                if ${namePos} >= 0
                {
                    openQuote:Set[${Math.Calc[${namePos} + 5]}]
                    closeQuote:Set[${line.Find["\"", ${Math.Calc[${openQuote} + 1]}]}]

                    if ${closeQuote} > ${openQuote}
                    {
                        cmdName:Set["${line.Mid[${Math.Calc[${openQuote} + 1]}, ${Math.Calc[${closeQuote} - ${openQuote} - 1]}]}"]
                        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                            echo [Debug:Playback] Extracted Name = ${cmdName}
                    }
                }

                ; Try Params="..." if Name format
                if ${cmdName.Length} > 0
                {
                    variable int paramsPos = ${line.Find["Params=\""]}
                    if ${paramsPos} >= 0
                    {
                        openQuote:Set[${Math.Calc[${paramsPos} + 7]}]
                        closeQuote:Set[${line.Find["\"", ${Math.Calc[${openQuote} + 1]}]}]

                        if ${closeQuote} > ${openQuote}
                        {
                            cmdParams:Set["${line.Mid[${Math.Calc[${openQuote} + 1]}, ${Math.Calc[${closeQuote} - ${openQuote} - 1]}]}"]
                            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                                echo [Debug:Playback] Extracted Params = ${cmdParams}
                        }
                    }

                    ; Try WaypointIndex="..." to override default
                    variable int indexPos = ${line.Find["WaypointIndex=\""]}
                    if ${indexPos} >= 0
                    {
                        openQuote:Set[${Math.Calc[${indexPos} + 14]}]
                        closeQuote:Set[${line.Find["\"", ${Math.Calc[${openQuote} + 1]}]}]

                        if ${closeQuote} > ${openQuote}
                        {
                            variable string wpIndexStr = "${line.Mid[${Math.Calc[${openQuote} + 1]}, ${Math.Calc[${closeQuote} - ${openQuote} - 1]}]}"
                            wpIndex:Set[${wpIndexStr}]
                            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                                echo [Debug:Playback] Extracted WaypointIndex = ${wpIndex}
                        }
                    }
                }
            }

            ; Store command if valid
            if ${cmdName.Length} > 0
            {
                commandCount:Inc
                variable string cmdKey = "cmd_${commandCount}"
                JBUI_Playback_Commands:Set["${cmdKey}", "${wpIndex}|${cmdName}|${cmdParams}"]
                echo [PlaybackThread] Added command ${commandCount} at waypoint ${wpIndex}: ${cmdName} (${cmdParams})
            }
            else
            {
                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Playback] WARNING: Command tag found but no Type or Name extracted
            }
        }
    }

    f:Close

    echo [PlaybackThread] === Loaded ${waypointCount} waypoints and ${commandCount} commands ===
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loaded ${waypointCount} waypoints, ${commandCount} commands"]
}

; ================================================================================
; CLEANUP - Stop movement and reset state
; ================================================================================

function Playback_Cleanup()
{
    echo [PlaybackThread] Cleaning up playback state

    ; Stop navigation if active
    if ${JNav_IsNavigating}
    {
        call Obj_JNavCore.StopAllMovement
        JNav_IsNavigating:Set[FALSE]
    }

    ; Clear waypoint list
    call Obj_JNavCore.ClearWaypointPath

    ; Clear commands
    JBUI_Playback_Commands:Clear

    ; Reset continuous mode
    JBUI_Playback_ContinuousMode:Set[FALSE]

    ; Stop movement if active - just set flags, don't call navigation methods
    ; The movement thread (Thread #2) handles the actual navigation calls
    if ${JBUI_Movement_Active}
    {
        JBUI_Movement_Active:Set[FALSE]
    }

    ; Reset playback state
    JBUI_Playback_State:Set["IDLE"]
    JBUI_Playback_CurrentType:Set[""]
    JBUI_Playback_CurrentData:Set[""]
}
