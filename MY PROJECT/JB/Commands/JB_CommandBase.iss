/*
 * JB_CommandBase.iss
 * Base object for all playback commands
 *
 * Design:
 * - Each command is an object instance
 * - Execute() runs in playback thread (Thread #3) context
 * - ExecuteThread() can use wait statements
 * - Command cleans up after completion or error
 */

#ifndef __JB_COMMANDBASE_INCLUDED__
#define __JB_COMMANDBASE_INCLUDED__

objectdef JB_CommandBase
{
    variable string CommandName
    variable string Category
    variable string HelpText
    variable string Parameters

    ; Execution state
    variable bool IsRunning = FALSE
    variable bool HasError = FALSE
    variable string ErrorMessage

    ; Execution result
    variable bool Success = FALSE
    variable string Result

    ; ============================================
    ; INITIALIZATION
    ; ============================================
    method Initialize(string name, string category, string help)
    {
        CommandName:Set["${name}"]
        Category:Set["${category}"]
        HelpText:Set["${help}"]
    }

    ; ============================================
    ; THREAD MANAGEMENT
    ; ============================================

    ; Execute command (runs in playback thread context)
    ; The playback system (JB_UI_Playback.iss) already runs as Thread #3
    ; So commands execute in that thread context automatically
    method Execute(string params)
    {
        if ${IsRunning}
        {
            echo [CommandBase] Error: ${CommandName} is already running
            return
        }

        Parameters:Set["${params}"]
        IsRunning:Set[TRUE]
        Success:Set[FALSE]
        HasError:Set[FALSE]

        echo [CommandBase] Executing ${CommandName} with params: ${params}

        ; Call the execution logic directly
        ; This runs in the playback thread (Thread #3) context
        This:ExecuteThread["${params}"]

        ; Note: ExecuteThread must call This:Cleanup when done
    }

    ; Check if command is still running
    member:bool IsActive()
    {
        return ${IsRunning}
    }

    ; Force stop the command
    method Stop()
    {
        if ${IsRunning}
        {
            echo [CommandBase] Stopping ${CommandName}
            This:Cleanup
        }
    }

    ; Cleanup after execution completes
    method Cleanup()
    {
        IsRunning:Set[FALSE]
        echo [CommandBase] Cleaned up ${CommandName} (Success: ${Success}, Error: ${HasError})
    }

    ; ============================================
    ; THREAD EXECUTION (Override in subclasses)
    ; ============================================

    ; Base implementation - subclasses should override this
    method ExecuteThread(string params)
    {
        ; This runs in a separate thread
        echo [CommandBase] ExecuteThread not implemented for ${CommandName}
        HasError:Set[TRUE]
        ErrorMessage:Set["ExecuteThread not implemented"]
        This:Cleanup
    }

    ; ============================================
    ; UTILITY METHODS
    ; ============================================

    ; Safe wait that respects thread termination
    method ThreadWait(int milliseconds)
    {
        variable int elapsed = 0
        variable int checkInterval = 100

        while ${elapsed} < ${milliseconds}
        {
            waitframe
            elapsed:Inc[${checkInterval}]

            ; Check if thread should terminate
            if !${IsRunning}
                return
        }
    }

    ; Wait with condition check (non-blocking)
    member:bool ThreadWaitCondition(int timeoutSeconds, string condition)
    {
        variable int elapsed = 0

        while ${elapsed} < ${timeoutSeconds}
        {
            ; Evaluate condition
            if ${condition}
            {
                return TRUE
            }

            wait 5
            elapsed:Inc[1]

            ; Check if thread should terminate
            if !${IsRunning}
                return FALSE
        }

        return FALSE
    }

    ; Get command info for UI
    member:string GetInfo()
    {
        return "${CommandName} (${Category})"
    }
}

#endif
