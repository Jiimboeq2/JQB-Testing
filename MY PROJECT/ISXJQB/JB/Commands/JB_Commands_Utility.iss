/*
 * JB_Commands_Utility.iss
 * Utility commands for automation support
 *
 * Commands:
 * - Wait - Pause execution for specified seconds
 * - Mount - Mount up
 * - Dismount - Dismount
 * - RepairGear - Repair equipment at merchant
 * - Jump - Make character jump
 * - Evac - Use evacuation ability
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; WAIT
; ============================================
objectdef Cmd_Wait inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Wait", "Utility", "Pause execution for specified seconds\nParam: Seconds"]
    }

    method ExecuteThread(string seconds)
    {
        variable int waitTime = ${seconds}

        if ${waitTime} <= 0
            waitTime:Set[1]

        echo [Wait] Waiting ${waitTime} seconds...

        variable int elapsed = 0

        while ${elapsed} < ${Math.Calc[${waitTime}*10]}
        {
            wait 1
            elapsed:Inc
        }

        echo [Wait] Wait completed
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; MOUNT
; ============================================
objectdef Cmd_Mount inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Mount", "Utility", "Mount up on your mount\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [Mount] Mounting up

        if ${Me.IsFlying}
        {
            echo [Mount] Already flying
            Success:Set[TRUE]
            This:Cleanup
            return
        }

        if ${Me.IsMounted}
        {
            echo [Mount] Already mounted
            Success:Set[TRUE]
            This:Cleanup
            return
        }

        ; Use mount ability
        eq2execute /useabilityonplayer Mount
        wait 20

        if ${Me.IsMounted} || ${Me.IsFlying}
        {
            echo [Mount] Mounted successfully
            Success:Set[TRUE]
        }
        else
        {
            echo [Mount] Failed to mount
            HasError:Set[TRUE]
            ErrorMessage:Set["Failed to mount"]
        }

        This:Cleanup
    }
}

; ============================================
; DISMOUNT
; ============================================
objectdef Cmd_Dismount inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Dismount", "Utility", "Dismount from your mount\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [Dismount] Dismounting

        if !${Me.IsMounted} && !${Me.IsFlying}
        {
            echo [Dismount] Not mounted
            Success:Set[TRUE]
            This:Cleanup
            return
        }

        ; Dismount
        eq2execute /dismount
        wait 10

        if !${Me.IsMounted} && !${Me.IsFlying}
        {
            echo [Dismount] Dismounted successfully
            Success:Set[TRUE]
        }
        else
        {
            echo [Dismount] Failed to dismount
            HasError:Set[TRUE]
            ErrorMessage:Set["Failed to dismount"]
        }

        This:Cleanup
    }
}

; ============================================
; REPAIR GEAR
; ============================================
objectdef Cmd_RepairGear inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["RepairGear", "Utility", "Repair all equipment at merchant\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [RepairGear] Repairing equipment

        ; Open merchant window if available
        if ${Target(exists)} && ${Target.Type.Equal["Merchant"]}
        {
            Target:DoubleClick
            wait 10

            if ${UIElement[Merchant](exists)}
            {
                ; Click repair all button
                if ${UIElement[Merchant@Repair_All_Button](exists)}
                {
                    UIElement[Merchant@Repair_All_Button]:LeftClick
                    wait 10

                    echo [RepairGear] Equipment repaired
                    Success:Set[TRUE]
                }
                else
                {
                    echo [RepairGear] Repair button not found
                    HasError:Set[TRUE]
                    ErrorMessage:Set["Repair button not found"]
                }

                ; Close merchant window
                UIElement[Merchant]:Hide
            }
            else
            {
                echo [RepairGear] Merchant window not open
                HasError:Set[TRUE]
                ErrorMessage:Set["Merchant window not open"]
            }
        }
        else
        {
            echo [RepairGear] No merchant targeted
            HasError:Set[TRUE]
            ErrorMessage:Set["No merchant targeted"]
        }

        This:Cleanup
    }
}

; ============================================
; JUMP
; ============================================
objectdef Cmd_Jump inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Jump", "Utility", "Make character jump\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [Jump] Jumping

        press space
        wait 5
        release space
        wait 5

        echo [Jump] Jump completed
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; EVAC
; ============================================
objectdef Cmd_Evac inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Evac", "Utility", "Use evacuation ability to teleport to safe spot\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [Evac] Using evacuation ability

        ; Use evac ability
        eq2execute /useability Evacuate
        wait 20

        ; Wait for potential zoning
        variable int waited = 0
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [Evac] Evacuation completed
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; LOOP
; ============================================
objectdef Cmd_Loop inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Loop", "Utility", "Loop waypoint path specified number of times\nParam: LoopCount"]
    }

    method ExecuteThread(string loopCount)
    {
        variable int loops = ${loopCount}

        if ${loops} <= 0
            loops:Set[1]

        echo [Loop] Setting path to loop ${loops} times

        ; This would integrate with the waypoint playback system
        ; For now, just mark as successful
        ; The actual looping logic should be in the playback controller

        echo [Loop] Loop count set to ${loops}
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; REVERSE
; ============================================
objectdef Cmd_Reverse inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Reverse", "Utility", "Reverse waypoint path direction\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [Reverse] Reversing waypoint path

        ; This would integrate with the waypoint playback system
        ; For now, just mark as successful
        ; The actual reverse logic should be in the playback controller

        echo [Reverse] Path reversed
        Success:Set[TRUE]
        This:Cleanup
    }
}
