; ============================================================================
; JB UI Movement Thread - Standalone movement handler (NEW CORE)
; This MUST run as a separate script to use wait/waitframe commands
; ============================================================================

#include "${Script.CurrentDirectory}/../JB/Navigation/JNavigation_Core.iss"

function main()
{
    if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
        echo [JB Movement] Movement thread started (using JNavCore v${JNav_Version})

    ; Initialize navigation core
    Obj_JNavCore:Initialize

    while ${Script[JB_UI_Simple](exists)}
    {
        ; Wait for movement request
        while !${JBUI_Movement_Active} && ${Script[JB_UI_Simple](exists)}
        {
            wait 10
        }

        if !${Script[JB_UI_Simple](exists)}
            break

        ; Get target coordinates from UI with retry logic
        variable float targetX = 0
        variable float targetY = 0
        variable float targetZ = 0
        variable bool isFinal = FALSE
        variable int retries = 0

        if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
            echo [Debug:Movement] Movement request received - Reading target coordinates from UI

        ; Retry up to 10 times (100ms total) until we get valid coordinates
        while ${retries} < 10
        {
            targetX:Set[${JBUI_Movement_TargetX}]
            targetY:Set[${JBUI_Movement_TargetY}]
            targetZ:Set[${JBUI_Movement_TargetZ}]
            isFinal:Set[${JBUI_Movement_IsFinalWaypoint}]

            ; If we got valid coordinates, break
            if ${targetX} != 0 || ${targetY} != 0 || ${targetZ} != 0
            {
                if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                    echo [Debug:Movement] Coordinates read successfully (retry ${retries}) - X:${targetX.Precision[2]}, Y:${targetY.Precision[2]}, Z:${targetZ.Precision[2]}, IsFinal:${isFinal}
                break
            }

            ; Wait 10ms and retry
            wait 1
            retries:Inc
        }

        ; Validate coordinates (shouldn't be 0,0,0 unless actually moving to origin)
        if ${targetX} == 0 && ${targetY} == 0 && ${targetZ} == 0
        {
            echo [JB Movement] ERROR: Received invalid coordinates (0,0,0) after ${retries} retries - skipping
            if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                echo [Debug:Movement] Coordinate validation FAILED - All zeros after ${retries} retries
            JBUI_Movement_Active:Set[FALSE]
            JBUI_Movement_Arrived:Set[FALSE]
            continue
        }

        echo [JB Movement] Moving to ${targetX.Precision[1]}, ${targetY.Precision[1]}, ${targetZ.Precision[1]}
        if ${isFinal}
        {
            echo [JB Movement] FINAL waypoint - will use ${JNav_DestinationPrecision}m precision
        }

        if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
        {
            variable float initialDistance = ${Math.Distance[${Me.Loc},${targetX},${targetY},${targetZ}]}
            echo [Debug:Movement] Starting navigation - Current pos:(${Me.X.Precision[1]},${Me.Y.Precision[1]},${Me.Z.Precision[1]}), Target:(${targetX.Precision[1]},${targetY.Precision[1]},${targetZ.Precision[1]}), Distance:${initialDistance.Precision[2]}m
        }

        ; Use NEW JNavigation Core to move
        ; This handles all movement, stuck detection, flying, etc.
        if ${Obj_JNavCore(exists)}
        {
            if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                echo [Debug:Movement] Calling JNavCore.NavigateToWaypoint - Target:(${targetX},${targetY},${targetZ}), IsFinal:${isFinal}

            call Obj_JNavCore.NavigateToWaypoint ${targetX} ${targetY} ${targetZ} ${isFinal}

            ; Check if we got stuck
            if ${JBUI_Movement_Stuck(exists)} && ${JNav_StuckCounter} >= 3
            {
                JBUI_Movement_Stuck:Set[TRUE]
                echo [JB Movement] WARNING: Stuck detected during navigation
                if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                    echo [Debug:Movement] Navigation completed with STUCK status - StuckCounter:${JNav_StuckCounter}
            }
            else
            {
                echo [JB Movement] Arrived at waypoint
                if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                {
                    variable float finalDistance = ${Math.Distance[${Me.Loc},${targetX},${targetY},${targetZ}]}
                    echo [Debug:Movement] Navigation completed SUCCESSFULLY - Final pos:(${Me.X.Precision[1]},${Me.Y.Precision[1]},${Me.Z.Precision[1]}), Distance from target:${finalDistance.Precision[2]}m
                }
            }
        }
        else
        {
            echo [JB Movement] ERROR: JNavCore object not found
            if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
                echo [Debug:Movement] CRITICAL ERROR: Obj_JNavCore object does not exist
        }

        ; Signal completion to playback thread
        JBUI_Movement_Active:Set[FALSE]
        JBUI_Movement_Arrived:Set[TRUE]

        if ${JBUI_Debug_Movement(exists)} && ${JBUI_Debug_Movement}
            echo [Debug:Movement] Movement cycle complete - Signaled JBUI_Movement_Active:FALSE, JBUI_Movement_Arrived:TRUE
    }

    ; Clean up on exit
    if ${Obj_JNavCore(exists)}
    {
        Obj_JNavCore:StopAllMovement
    }

    echo [JB Movement] Movement thread stopped
}
