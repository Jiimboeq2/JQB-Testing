/*
 * JB_Commands_Gathering.iss
 * Gathering/Harvesting automation commands with thread management
 *
 * Commands:
 * - GatherNode - Harvest single node
 * - GatherNodeUntilUpdate - Gather until quest updates
 * - GatherMultipleNodes - Gather multiple node types for quest
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; GATHER NODE
; ============================================
objectdef Cmd_GatherNode inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["GatherNode", "Gathering", "Harvest a resource node (single attempt)\nParam: NodeName"]
    }

    method ExecuteThread(string nodeName)
    {
        echo [GatherNode] Attempting to harvest '${nodeName}'

        ; Target the node
        target ${nodeName}
        wait 5

        if !${Target(exists)} || !${Target.Name.Find["${nodeName}"]}
        {
            echo [GatherNode] Node '${nodeName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Node not found"]
            This:Cleanup
            return
        }

        ; Double-click to harvest
        Target:DoubleClick
        wait 5

        ; Wait for harvest to complete
        variable int waited = 0
        while ${Me.CastingSpell} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        echo [GatherNode] Harvest attempt completed
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; GATHER NODE UNTIL UPDATE
; ============================================
objectdef Cmd_GatherNodeUntilUpdate inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["GatherNodeUntilUpdate", "Gathering", "Gather nodes repeatedly until quest updates\nParam: NodeName,QuestName,MaxAttempts"]
    }

    method ExecuteThread(string params)
    {
        variable string nodeName = "${params.Token[1,","]}"
        variable string questName = "${params.Token[2,","]}"
        variable int maxAttempts = ${params.Token[3,","]}

        if ${maxAttempts} <= 0
            maxAttempts:Set[10]

        echo [GatherNodeUntilUpdate] Gathering '${nodeName}' until quest '${questName}' updates (max ${maxAttempts} attempts)

        variable int attempt = 0
        variable int initialStep

        ; Get initial quest step
        if ${Me.Quest[${questName}](exists)}
        {
            initialStep:Set[${Me.Quest[${questName}].Step}]
        }
        else
        {
            echo [GatherNodeUntilUpdate] Quest '${questName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Quest not found"]
            This:Cleanup
            return
        }

        ; Loop until quest updates or max attempts
        while ${attempt} < ${maxAttempts}
        {
            attempt:Inc
            echo [GatherNodeUntilUpdate] Attempt ${attempt}/${maxAttempts}

            ; Find and target nearest node
            call This.FindNearestNode "${nodeName}"

            if ${Target(exists)} && ${Target.Name.Find["${nodeName}"]}
            {
                ; Double-click to harvest
                Target:DoubleClick
                wait 5

                ; Wait for harvest to complete
                variable int waited = 0
                while ${Me.CastingSpell} && ${waited} < 100
                {
                    wait 1
                    waited:Inc
                }

                wait 10

                ; Check if quest updated
                if ${Me.Quest[${questName}](exists)} && ${Me.Quest[${questName}].Step} != ${initialStep}
                {
                    echo [GatherNodeUntilUpdate] Quest updated! (Step ${Me.Quest[${questName}].Step})
                    Success:Set[TRUE]
                    This:Cleanup
                    return
                }
            }
            else
            {
                echo [GatherNodeUntilUpdate] Node '${nodeName}' not found, waiting...
                wait 20
            }

            ; Small delay between attempts
            wait 10
        }

        echo [GatherNodeUntilUpdate] Max attempts reached without quest update
        HasError:Set[TRUE]
        ErrorMessage:Set["Max attempts reached"]
        This:Cleanup
    }

    method FindNearestNode(string nodeName)
    {
        ; Target nearest matching node
        target ${nodeName}
        wait 3

        ; Could enhance this with Actor search for closest match
        ; For now, basic targeting
    }
}

; ============================================
; GATHER MULTIPLE NODES
; ============================================
objectdef Cmd_GatherMultipleNodes inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["GatherMultipleNodes", "Gathering", "Gather from multiple node types until quest completes\nParam: QuestName,NodeType1;NodeType2;NodeType3,MaxAttempts"]
    }

    method ExecuteThread(string params)
    {
        variable string questName = "${params.Token[1,","]}"
        variable string nodeList = "${params.Token[2,","]}"
        variable int maxAttempts = ${params.Token[3,","]}

        if ${maxAttempts} <= 0
            maxAttempts:Set[15]

        echo [GatherMultipleNodes] Gathering from nodes: ${nodeList} for quest '${questName}' (max ${maxAttempts} attempts)

        variable int attempt = 0
        variable int initialStep
        variable int nodeCount
        variable int currentNode
        variable string nodeName

        ; Get initial quest step
        if ${Me.Quest[${questName}](exists)}
        {
            initialStep:Set[${Me.Quest[${questName}].Step}]
        }
        else
        {
            echo [GatherMultipleNodes] Quest '${questName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Quest not found"]
            This:Cleanup
            return
        }

        ; Count node types
        nodeCount:Set[${nodeList.Count[";"]}]
        nodeCount:Inc

        ; Loop until quest updates or max attempts
        while ${attempt} < ${maxAttempts}
        {
            attempt:Inc
            echo [GatherMultipleNodes] Attempt ${attempt}/${maxAttempts}

            ; Try each node type
            for (currentNode:Set[1]; ${currentNode} <= ${nodeCount}; currentNode:Inc)
            {
                nodeName:Set["${nodeList.Token[${currentNode},";"]}"]
                echo [GatherMultipleNodes] Trying node type: ${nodeName}

                ; Target node
                target ${nodeName}
                wait 5

                if ${Target(exists)} && ${Target.Name.Find["${nodeName}"]}
                {
                    ; Harvest
                    Target:DoubleClick
                    wait 5

                    ; Wait for harvest
                    variable int waited = 0
                    while ${Me.CastingSpell} && ${waited} < 100
                    {
                        wait 1
                        waited:Inc
                    }

                    wait 10

                    ; Check if quest updated
                    if ${Me.Quest[${questName}](exists)} && ${Me.Quest[${questName}].Step} != ${initialStep}
                    {
                        echo [GatherMultipleNodes] Quest updated!
                        Success:Set[TRUE]
                        This:Cleanup
                        return
                    }

                    ; Break inner loop if we found a node
                    break
                }
            }

            ; Delay between attempts
            wait 15
        }

        echo [GatherMultipleNodes] Max attempts reached
        HasError:Set[TRUE]
        ErrorMessage:Set["Max attempts reached"]
        This:Cleanup
    }
}
