/*
 * JB_CommandManager.iss
 * Central manager for all playback commands
 *
 * Responsibilities:
 * - Track current executing command
 * - Manage command execution state
 * - Collect execution statistics
 * - Enforce sequential execution
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

objectdef JB_CommandManager
{
    ; Statistics
    variable int TotalExecuted = 0
    variable int TotalSuccess = 0
    variable int TotalFailed = 0

    ; Current executing command
    variable string CurrentCommand = ""
    variable bool IsExecuting = FALSE

    ; ============================================
    ; INITIALIZATION
    ; ============================================
    method Initialize()
    {
        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [CommandManager] Initialized
    }

    ; ============================================
    ; COMMAND EXECUTION
    ; ============================================

    ; Execute a command (runs in current thread context - playback Thread #3)
    ; Returns TRUE if successful, FALSE if failed
    member:bool ExecuteCommand(string commandName, string parameters)
    {
        if ${IsExecuting}
        {
            echo [CommandManager] Cannot execute ${commandName}: Another command is running
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Execution BLOCKED - Command:${commandName}, CurrentlyExecuting:${CurrentCommand}
            return FALSE
        }

        CurrentCommand:Set["${commandName}"]
        IsExecuting:Set[TRUE]
        TotalExecuted:Inc

        echo [CommandManager] Executing ${commandName} with params: ${parameters}
        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
            echo [Debug:Commands] Command started - Name:${commandName}, Params:${parameters}, TotalExecuted:${TotalExecuted}

        ; Auto-execute special ability for group
        relay all oc !c -Special auto
        wait 5

        ; Check for zoning triggered by special ability
        variable uint zoneCheckStart = ${System.TickCount}
        variable bool wasInZone = ${Me.InZone}

        ; Wait up to 5 seconds to detect zone transition start
        while ${Math.Calc[${System.TickCount} - ${zoneCheckStart}]} < 5000
        {
            if ${wasInZone} && !${Me.InZone}
            {
                echo [CommandManager] Zoning detected - waiting for zone transition
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Zoning detected - waiting..."]
                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Commands] Zone transition started - InZone:FALSE

                ; Wait for zoning to complete (back in zone)
                variable uint zoneWaitStart = ${System.TickCount}
                variable uint zoneTimeout = 60000  ; 60 second timeout for zoning

                while !${Me.InZone}
                {
                    if ${Math.Calc[${System.TickCount} - ${zoneWaitStart}]} > ${zoneTimeout}
                    {
                        echo [CommandManager] WARNING: Zone transition timeout after 60 seconds
                        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Zone timeout!"]
                        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                            echo [Debug:Commands] Zoning TIMEOUT - Continuing anyway
                        break
                    }
                    wait 10
                }

                if ${Me.InZone}
                {
                    echo [CommandManager] Zone transition complete
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Zone complete"]
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Commands] Zoning finished - InZone:TRUE, Duration:${Math.Calc[${System.TickCount} - ${zoneWaitStart}]}ms
                    wait 5  ; Extra safety wait after zoning
                }
                break
            }
            wait 1
        }

        ; Execute the actual command via CommandRegistry
        if !${JBCmdRegistry.ExecuteCommand["${commandName}", "${parameters}"]}
        {
            echo [CommandManager] Command not found: ${commandName}
            This.CommandCompleted[FALSE]
            return FALSE
        }

        ; Smart casting detection: check if a cast started
        variable uint castCheckStart = ${System.TickCount}
        variable bool castDetected = FALSE

        ; Wait up to 2 seconds (2000ms) for a cast to start
        while ${Math.Calc[${System.TickCount} - ${castCheckStart}]} < 2000
        {
            if ${Me.Casting}
            {
                castDetected:Set[TRUE]
                echo [CommandManager] Cast detected - waiting for completion
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Casting/Harvesting..."]
                if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                    echo [Debug:Commands] Casting started - Entering cast wait loop
                break
            }
            wait 1
        }

        ; If cast detected, wait for it to finish
        if ${castDetected}
        {
            variable uint castWaitStart = ${System.TickCount}
            variable uint castTimeout = 30000  ; 30 second timeout for safety

            while ${Me.Casting}
            {
                ; Safety timeout
                if ${Math.Calc[${System.TickCount} - ${castWaitStart}]} > ${castTimeout}
                {
                    echo [CommandManager] WARNING: Cast timeout after 30 seconds
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Cast timeout!"]
                    if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                        echo [Debug:Commands] Cast TIMEOUT - Breaking wait loop for safety
                    break
                }
                wait 1
            }

            echo [CommandManager] Cast completed
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Cast complete"]
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Casting finished - Duration:${Math.Calc[${System.TickCount} - ${castWaitStart}]}ms
        }
        else
        {
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] No cast detected within 2 seconds - Continuing
        }

        This.CommandCompleted[TRUE]
        return TRUE
    }

    ; Mark command as completed
    method CommandCompleted(bool success)
    {
        if ${success}
        {
            TotalSuccess:Inc
            echo [CommandManager] Command '${CurrentCommand}' completed successfully
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Command SUCCEEDED - Name:${CurrentCommand}, TotalSuccess:${TotalSuccess}, Success Rate:${Math.Calc[${TotalSuccess}*100/${TotalExecuted}].Precision[1]}%
        }
        else
        {
            TotalFailed:Inc
            echo [CommandManager] Command '${CurrentCommand}' failed
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Command FAILED - Name:${CurrentCommand}, TotalFailed:${TotalFailed}, Failure Rate:${Math.Calc[${TotalFailed}*100/${TotalExecuted}].Precision[1]}%
        }

        if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
            echo [Debug:Commands] Command execution complete - Clearing state, IsExecuting:FALSE

        CurrentCommand:Set[""]
        IsExecuting:Set[FALSE]
    }

    ; ============================================
    ; STATUS MANAGEMENT
    ; ============================================

    ; Stop current command
    method StopCurrent()
    {
        if ${IsExecuting}
        {
            echo [CommandManager] Stopping current command: ${CurrentCommand}
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Command STOPPED - Name:${CurrentCommand}, Was executing:TRUE, Forcing stop
            CurrentCommand:Set[""]
            IsExecuting:Set[FALSE]
        }
        else
        {
            if ${JBUI_Debug_Commands(exists)} && ${JBUI_Debug_Commands}
                echo [Debug:Commands] Stop requested but no command was executing
        }
    }

    ; ============================================
    ; STATUS & MONITORING
    ; ============================================

    ; Check if a command is running
    member:bool IsCommandRunning()
    {
        return ${IsExecuting}
    }

    ; Get current command name
    member:string GetCurrentCommand()
    {
        return "${CurrentCommand}"
    }

    ; Get statistics
    member:string GetStats()
    {
        return "Executed: ${TotalExecuted}, Success: ${TotalSuccess}, Failed: ${TotalFailed}"
    }

    ; Print status
    method PrintStatus()
    {
        echo [CommandManager] ${This.GetStats}
        if ${IsExecuting}
            echo [CommandManager] Currently executing: ${CurrentCommand}
    }
}

; ============================================
; GLOBAL INSTANCE
; ============================================
variable(global) JB_CommandManager JBCmdManager
