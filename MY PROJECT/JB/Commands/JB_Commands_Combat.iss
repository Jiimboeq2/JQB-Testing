/*
 * JB_Commands_Combat.iss
 * Combat automation commands for instances and boss fights
 *
 * Commands:
 * - KillUntilUpdate - Kill mobs until quest updates
 * - CastAbility - Cast specific ability
 * - UseItem - Use item from inventory
 * - DisableCombat - Turn off OgreBot combat
 * - EnableCombat - Turn on OgreBot combat
 * - ZoneReset - Reset current instance
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; KILL UNTIL UPDATE
; ============================================
objectdef Cmd_KillUntilUpdate inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["KillUntilUpdate", "Combat", "Kill mobs repeatedly until quest updates\nParam: MobName,QuestName,MaxKills"]
    }

    method ExecuteThread(string params)
    {
        variable string mobName = "${params.Token[1,","]}"
        variable string questName = "${params.Token[2,","]}"
        variable int maxKills = ${params.Token[3,","]}

        if ${maxKills} <= 0
            maxKills:Set[15]

        echo [KillUntilUpdate] Killing '${mobName}' until quest '${questName}' updates (max ${maxKills} kills)

        variable int killCount = 0
        variable int initialStep

        ; Get initial quest step
        if ${Me.Quest[${questName}](exists)}
        {
            initialStep:Set[${Me.Quest[${questName}].Step}]
        }
        else
        {
            echo [KillUntilUpdate] Quest '${questName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Quest not found"]
            This:Cleanup
            return
        }

        ; Enable OgreBot autotarget for this mob
        eq2execute oc !ci -Ob_AutoTarget_Clear
        wait 5
        eq2execute oc !ci -Ob_AutoTarget_AddActor "${mobName},0,FALSE,FALSE"
        wait 5

        ; Loop until quest updates or max kills
        while ${killCount} < ${maxKills}
        {
            ; Wait for combat to start
            variable int combatWait = 0
            while !${Me.InCombat} && ${combatWait} < 100
            {
                wait 1
                combatWait:Inc

                ; Target mob if available
                if ${Actor[ExactName,"${mobName}"](exists)}
                {
                    target ${mobName}
                    wait 3
                }
            }

            ; Wait for combat to end
            if ${Me.InCombat}
            {
                echo [KillUntilUpdate] In combat with '${mobName}'...

                while ${Me.InCombat}
                {
                    wait 10
                }

                killCount:Inc
                echo [KillUntilUpdate] Kill ${killCount}/${maxKills}

                ; Check if quest updated
                if ${Me.Quest[${questName}](exists)} && ${Me.Quest[${questName}].Step} != ${initialStep}
                {
                    echo [KillUntilUpdate] Quest updated! (Step ${Me.Quest[${questName}].Step})

                    ; Clear autotarget
                    eq2execute oc !ci -Ob_AutoTarget_Clear
                    wait 5

                    Success:Set[TRUE]
                    This:Cleanup
                    return
                }

                ; Wait before looking for next mob
                wait 20
            }
            else
            {
                ; No mob found, wait a bit
                wait 30
            }
        }

        ; Clear autotarget
        eq2execute oc !ci -Ob_AutoTarget_Clear
        wait 5

        echo [KillUntilUpdate] Max kills reached without quest update
        HasError:Set[TRUE]
        ErrorMessage:Set["Max kills reached"]
        This:Cleanup
    }
}

; ============================================
; CAST ABILITY
; ============================================
objectdef Cmd_CastAbility inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["CastAbility", "Combat", "Cast a specific ability by name\nParam: AbilityName"]
    }

    method ExecuteThread(string abilityName)
    {
        echo [CastAbility] Casting '${abilityName}'

        if ${Me.Ability[${abilityName}](exists)}
        {
            Me.Ability[${abilityName}]:Use
            wait 5

            ; Wait for cast to complete
            variable int waited = 0
            while ${Me.CastingSpell} && ${waited} < 100
            {
                wait 1
                waited:Inc
            }

            echo [CastAbility] Ability cast completed
            Success:Set[TRUE]
        }
        else
        {
            echo [CastAbility] Ability '${abilityName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Ability not found"]
        }

        This:Cleanup
    }
}

; ============================================
; USE ITEM
; ============================================
objectdef Cmd_UseItem inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["UseItem", "Combat", "Use an item from inventory\nParam: ItemName"]
    }

    method ExecuteThread(string itemName)
    {
        echo [UseItem] Using item '${itemName}'

        if ${Me.Inventory[${itemName}](exists)}
        {
            Me.Inventory[${itemName}]:Use
            wait 10

            echo [UseItem] Item used successfully
            Success:Set[TRUE]
        }
        else
        {
            echo [UseItem] Item '${itemName}' not found in inventory
            HasError:Set[TRUE]
            ErrorMessage:Set["Item not found"]
        }

        This:Cleanup
    }
}

; ============================================
; DISABLE COMBAT
; ============================================
objectdef Cmd_DisableCombat inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["DisableCombat", "Combat", "Turn off OgreBot combat mode\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [DisableCombat] Disabling OgreBot combat

        eq2execute oc !ci -pause
        wait 5

        echo [DisableCombat] Combat disabled
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; ENABLE COMBAT
; ============================================
objectdef Cmd_EnableCombat inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["EnableCombat", "Combat", "Turn on OgreBot combat mode\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [EnableCombat] Enabling OgreBot combat

        eq2execute oc !ci -resume
        wait 5

        echo [EnableCombat] Combat enabled
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; ZONE RESET
; ============================================
objectdef Cmd_ZoneReset inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ZoneReset", "Combat", "Reset current instance/zone\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [ZoneReset] Resetting zone/instance

        eq2execute oc !ci -ResetZone
        wait 10

        ; Wait for zone reset to complete
        variable int waited = 0
        while ${Zone.Resetting} && ${waited} < 300
        {
            wait 10
            waited:Inc
        }

        echo [ZoneReset] Zone reset completed
        Success:Set[TRUE]
        This:Cleanup
    }
}
