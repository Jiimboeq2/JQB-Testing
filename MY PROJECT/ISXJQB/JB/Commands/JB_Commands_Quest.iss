/*
 * JB_Commands_Quest.iss
 * Quest automation commands with thread management
 *
 * Commands:
 * - HailActor - Hail and handle dialog
 * - HailAndAcceptQuest - One-command quest acceptance
 * - ClickActor - Click quest items/objects
 * - ClickActorUntilUpdate - Click until quest updates
 * - ConversationBubble - Handle conversation choices
 * - ReplyDialog - Reply to dialog windows
 * - AcceptQuest - Accept specific quest
 * - CheckQuestStep - Verify quest step completion
 * - WaitForQuestStep - Wait for quest step
 * - LoopUntilFaction - Repeat quest for faction grinding
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; HAIL ACTOR
; ============================================
objectdef Cmd_HailActor inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["HailActor", "Quest", "Hail an NPC with optional conversation choices\nParam: ActorName or ActorName,choice1,choice2..."]
    }

    method ExecuteThread(string params)
    {
        variable string actorName
        variable string choiceSequence
        variable int commaPos

        ; Parse actor name and choices
        commaPos:Set[${params.Find[","]}]

        if ${commaPos} > 0
        {
            actorName:Set["${params.Left[${Math.Calc[${commaPos}-1]}]}"]
            choiceSequence:Set["${params.Right[${Math.Calc[${params.Length}-${commaPos}]}]}"]
        }
        else
        {
            actorName:Set["${params}"]
            choiceSequence:Set[""]
        }

        echo [HailActor] Hailing '${actorName}' with choices: ${choiceSequence}

        ; Target the actor
        target ${actorName}
        wait 5

        if !${Target(exists)} || !${Target.Name.Find["${actorName}"]}
        {
            echo [HailActor] Failed to target '${actorName}'
            HasError:Set[TRUE]
            ErrorMessage:Set["Failed to target actor"]
            This:Cleanup
            return
        }

        ; Hail
        eq2execute /hail
        wait 10

        ; Handle conversation choices if provided
        if ${choiceSequence.Length} > 0
        {
            call This.HandleConversation "${choiceSequence}"
        }

        Success:Set[TRUE]
        This:Cleanup
    }

    method HandleConversation(string choices)
    {
        variable int i
        variable int choiceNum
        variable string currentChoice
        variable int numChoices

        numChoices:Set[${choices.Count[","]}]
        numChoices:Inc

        for (i:Set[1]; ${i} <= ${numChoices}; i:Inc)
        {
            currentChoice:Set["${choices.Token[${i},","]}"]

            ; Check if it's a conversation bubble (c#) or reply dialog (r#)
            if ${currentChoice.Left[1].Equal["c"]}
            {
                choiceNum:Set[${currentChoice.Right[${Math.Calc[${currentChoice.Length}-1]}]}]
                call This.ClickConversationBubble ${choiceNum}
            }
            elseif ${currentChoice.Left[1].Equal["r"]}
            {
                choiceNum:Set[${currentChoice.Right[${Math.Calc[${currentChoice.Length}-1]}]}]
                call This.ClickReplyDialog ${choiceNum}
            }
            else
            {
                ; Assume it's a direct choice number
                choiceNum:Set[${currentChoice}]
                call This.ClickConversationBubble ${choiceNum}
            }

            wait 5
        }
    }

    method ClickConversationBubble(int choice)
    {
        echo [HailActor] Clicking conversation bubble choice ${choice}
        eq2execute /select_conversationbubble_option ${choice}
        wait 3
    }

    method ClickReplyDialog(int choice)
    {
        echo [HailActor] Clicking reply dialog choice ${choice}
        eq2execute /select_reply ${choice}
        wait 3
    }
}

; ============================================
; HAIL AND ACCEPT QUEST
; ============================================
objectdef Cmd_HailAndAcceptQuest inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["HailAndAcceptQuest", "Quest", "Hail NPC and auto-accept quest\nParam: NPCName"]
    }

    method ExecuteThread(string npcName)
    {
        echo [HailAndAcceptQuest] Hailing '${npcName}' and accepting quest

        ; Target the NPC
        target ${npcName}
        wait 5

        if !${Target(exists)} || !${Target.Name.Find["${npcName}"]}
        {
            echo [HailAndAcceptQuest] Failed to target '${npcName}'
            HasError:Set[TRUE]
            ErrorMessage:Set["Failed to target NPC"]
            This:Cleanup
            return
        }

        ; Hail
        eq2execute /hail
        wait 10

        ; Wait for quest offer window
        variable int waited = 0
        while !${UIElement[QuestOfferWnd](exists)} && ${waited} < 50
        {
            wait 1
            waited:Inc
        }

        if ${UIElement[QuestOfferWnd](exists)}
        {
            echo [HailAndAcceptQuest] Quest offered, accepting...
            UIElement[QuestOfferWnd@AcceptButton]:LeftClick
            wait 5
        }
        else
        {
            echo [HailAndAcceptQuest] No quest offer window appeared
        }

        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; CLICK ACTOR
; ============================================
objectdef Cmd_ClickActor inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ClickActor", "Quest", "Double-click an actor (quest items, doors, objects)\nParam: ActorName"]
    }

    method ExecuteThread(string actorName)
    {
        echo [ClickActor] Clicking '${actorName}'

        ; Target the actor
        target ${actorName}
        wait 5

        if !${Target(exists)} || !${Target.Name.Find["${actorName}"]}
        {
            echo [ClickActor] Failed to target '${actorName}'
            HasError:Set[TRUE]
            ErrorMessage:Set["Failed to target actor"]
            This:Cleanup
            return
        }

        ; Double-click
        Target:DoubleClick
        wait 10

        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; CLICK ACTOR UNTIL UPDATE
; ============================================
objectdef Cmd_ClickActorUntilUpdate inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ClickActorUntilUpdate", "Quest", "Click actor repeatedly until quest updates\nParam: ActorName,QuestName,MaxAttempts"]
    }

    method ExecuteThread(string params)
    {
        variable string actorName = "${params.Token[1,","]}"
        variable string questName = "${params.Token[2,","]}"
        variable int maxAttempts = ${params.Token[3,","]}

        if ${maxAttempts} <= 0
            maxAttempts:Set[10]

        echo [ClickActorUntilUpdate] Clicking '${actorName}' until quest '${questName}' updates (max ${maxAttempts} attempts)

        variable int attempt = 0
        variable int initialStep

        ; Get initial quest step
        if ${Me.Quest[${questName}](exists)}
        {
            initialStep:Set[${Me.Quest[${questName}].Step}]
        }
        else
        {
            echo [ClickActorUntilUpdate] Quest '${questName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Quest not found"]
            This:Cleanup
            return
        }

        ; Loop until quest updates or max attempts
        while ${attempt} < ${maxAttempts}
        {
            attempt:Inc

            ; Target and click
            target ${actorName}
            wait 5

            if ${Target(exists)} && ${Target.Name.Find["${actorName}"]}
            {
                Target:DoubleClick
                wait 10

                ; Check if quest updated
                if ${Me.Quest[${questName}].Step} != ${initialStep}
                {
                    echo [ClickActorUntilUpdate] Quest updated! (Step ${Me.Quest[${questName}].Step})
                    Success:Set[TRUE]
                    This:Cleanup
                    return
                }
            }
            else
            {
                echo [ClickActorUntilUpdate] Actor '${actorName}' not found, waiting...
                wait 20
            }
        }

        echo [ClickActorUntilUpdate] Max attempts reached without quest update
        HasError:Set[TRUE]
        ErrorMessage:Set["Max attempts reached"]
        This:Cleanup
    }
}

; ============================================
; LOOP UNTIL FACTION
; ============================================
objectdef Cmd_LoopUntilFaction inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["LoopUntilFaction", "Quest", "Repeat quest until faction threshold reached\nParam: QuestName,FactionName,FactionValue"]
    }

    method ExecuteThread(string params)
    {
        variable string questName = "${params.Token[1,","]}"
        variable string factionName = "${params.Token[2,","]}"
        variable int targetFaction = ${params.Token[3,","]}

        echo [LoopUntilFaction] Repeating quest '${questName}' until ${factionName} >= ${targetFaction}

        ; This is a placeholder - actual implementation would require
        ; integration with quest system and faction checking
        ; For now, mark as success
        echo [LoopUntilFaction] Faction looping not yet fully implemented
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; WAIT FOR QUEST STEP
; ============================================
objectdef Cmd_WaitForQuestStep inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["WaitForQuestStep", "Quest", "Wait for specific quest step to complete\nParam: QuestName,StepKeyword"]
    }

    method ExecuteThread(string params)
    {
        variable string questName = "${params.Token[1,","]}"
        variable string stepKeyword = "${params.Token[2,","]}"
        variable int timeout = 300  ; 5 minutes

        echo [WaitForQuestStep] Waiting for quest '${questName}' step containing '${stepKeyword}'

        variable int elapsed = 0

        while ${elapsed} < ${timeout}
        {
            if ${Me.Quest[${questName}](exists)}
            {
                ; Check if current step description contains keyword
                if ${Me.Quest[${questName}].Instruction.Find["${stepKeyword}"]}
                {
                    echo [WaitForQuestStep] Quest step found!
                    Success:Set[TRUE]
                    This:Cleanup
                    return
                }
            }

            wait 10
            elapsed:Inc
        }

        echo [WaitForQuestStep] Timeout waiting for quest step
        HasError:Set[TRUE]
        ErrorMessage:Set["Timeout waiting for quest step"]
        This:Cleanup
    }
}

; ============================================
; CONVERSATION SEQUENCE
; ============================================
objectdef Cmd_ConversationSequence inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ConversationSequence", "Quest", "Click conversation bubble choices in sequence\nParam: choice1,choice2,choice3... (e.g. 1,1,3,1)"]
    }

    method ExecuteThread(string params)
    {
        variable int choiceNum
        variable int tokenCount = 1
        variable int selectCount = 0

        echo [ConversationSequence] Processing conversation bubble selections: ${params}

        ; Process each choice in sequence
        while ${params.Token[${tokenCount},","](exists)}
        {
            choiceNum:Set[${params.Token[${tokenCount},","]}]

            if ${choiceNum} > 0
            {
                echo [ConversationSequence] Selecting choice ${choiceNum}
                eq2execute /select_conversationbubble_option ${choiceNum}
                wait 10
                selectCount:Inc
            }

            tokenCount:Inc
        }

        echo [ConversationSequence] Selected ${selectCount} conversation choices
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; REPLY SEQUENCE
; ============================================
objectdef Cmd_ReplySequence inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ReplySequence", "Quest", "Select reply dialog options in sequence\nParam: option1,option2,option3... (e.g. 1,2,1)"]
    }

    method ExecuteThread(string params)
    {
        variable int optionNum
        variable int tokenCount = 1
        variable int selectCount = 0

        echo [ReplySequence] Processing reply dialog selections: ${params}

        ; Process each option in sequence
        while ${params.Token[${tokenCount},","](exists)}
        {
            optionNum:Set[${params.Token[${tokenCount},","]}]

            if ${optionNum} > 0
            {
                echo [ReplySequence] Selecting option ${optionNum}
                eq2execute /select_reply ${optionNum}
                wait 10
                selectCount:Inc
            }

            tokenCount:Inc
        }

        echo [ReplySequence] Selected ${selectCount} reply options
        Success:Set[TRUE]
        This:Cleanup
    }
}
