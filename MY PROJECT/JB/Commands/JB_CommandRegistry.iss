/*
 * JB_CommandRegistry.iss
 * Central registry for all automation commands
 *
 * Responsibilities:
 * - Load all command category files
 * - Create instances of command objects
 * - Provide command lookup by name
 * - Provide command execution interface
 * - Integrate with JB_CommandManager for thread handling
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandManager.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Quest.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Gathering.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Crafting.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Combat.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Travel.iss"
#include "${Script.CurrentDirectory}/../JB/Commands/JB_Commands_Utility.iss"

objectdef JB_CommandRegistry
{
    ; Command storage by category
    variable collection:string CommandsByCategory
    variable collection:string CommandHelp
    variable collection:string CommandCategory

    ; Command instances (for object-based execution)
    ; Quest Commands
    variable Cmd_HailActor HailActor
    variable Cmd_HailAndAcceptQuest HailAndAcceptQuest
    variable Cmd_ClickActor ClickActor
    variable Cmd_ClickActorUntilUpdate ClickActorUntilUpdate
    variable Cmd_LoopUntilFaction LoopUntilFaction
    variable Cmd_WaitForQuestStep WaitForQuestStep
    variable Cmd_ConversationSequence ConversationSequence
    variable Cmd_ReplySequence ReplySequence

    ; Gathering Commands
    variable Cmd_GatherNode GatherNode
    variable Cmd_GatherNodeUntilUpdate GatherNodeUntilUpdate
    variable Cmd_GatherMultipleNodes GatherMultipleNodes

    ; Crafting Commands
    variable Cmd_CraftItem CraftItem
    variable Cmd_CraftUntilUpdate CraftUntilUpdate
    variable Cmd_ScribeRecipe ScribeRecipe
    variable Cmd_ScribeAndCraft ScribeAndCraft

    ; Combat Commands
    variable Cmd_KillUntilUpdate KillUntilUpdate
    variable Cmd_CastAbility CastAbility
    variable Cmd_UseItem UseItem
    variable Cmd_DisableCombat DisableCombat
    variable Cmd_EnableCombat EnableCombat
    variable Cmd_ZoneReset ZoneReset

    ; Travel Commands
    variable Cmd_TravelBell TravelBell
    variable Cmd_TravelSpire TravelSpire
    variable Cmd_TravelDruid TravelDruid
    variable Cmd_Door Door
    variable Cmd_WaitForZoned WaitForZoned
    variable Cmd_PortalToGuildHall PortalToGuildHall

    ; Utility Commands
    variable Cmd_Wait Wait
    variable Cmd_Mount Mount
    variable Cmd_Dismount Dismount
    variable Cmd_RepairGear RepairGear
    variable Cmd_Jump Jump
    variable Cmd_Evac Evac
    variable Cmd_Loop Loop
    variable Cmd_Reverse Reverse

    ; ============================================
    ; INITIALIZATION
    ; ============================================
    method Initialize()
    {
        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [CommandRegistry] Initializing command registry...

        ; Initialize collections
        CommandsByCategory:Clear
        CommandHelp:Clear
        CommandCategory:Clear

        ; Initialize all command objects
        This:InitializeCommandObjects

        ; Register all commands in collections
        This:RegisterCommands

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [CommandRegistry] Registered ${CommandCategory.Used} commands across 6 categories
    }

    ; Initialize all command object instances
    method InitializeCommandObjects()
    {
        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [CommandRegistry] Creating command object instances...

        ; Quest Commands
        HailActor:Initialize
        HailAndAcceptQuest:Initialize
        ClickActor:Initialize
        ClickActorUntilUpdate:Initialize
        LoopUntilFaction:Initialize
        WaitForQuestStep:Initialize
        ConversationSequence:Initialize
        ReplySequence:Initialize

        ; Gathering Commands
        GatherNode:Initialize
        GatherNodeUntilUpdate:Initialize
        GatherMultipleNodes:Initialize

        ; Crafting Commands
        CraftItem:Initialize
        CraftUntilUpdate:Initialize
        ScribeRecipe:Initialize
        ScribeAndCraft:Initialize

        ; Combat Commands
        KillUntilUpdate:Initialize
        CastAbility:Initialize
        UseItem:Initialize
        DisableCombat:Initialize
        EnableCombat:Initialize
        ZoneReset:Initialize

        ; Travel Commands
        TravelBell:Initialize
        TravelSpire:Initialize
        TravelDruid:Initialize
        Door:Initialize
        WaitForZoned:Initialize
        PortalToGuildHall:Initialize

        ; Utility Commands
        Wait:Initialize
        Mount:Initialize
        Dismount:Initialize
        RepairGear:Initialize
        Jump:Initialize
        Evac:Initialize
        Loop:Initialize
        Reverse:Initialize

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [CommandRegistry] Initialized 35 command objects
    }

    ; ============================================
    ; COMMAND REGISTRATION
    ; ============================================
    method RegisterCommands()
    {
        ; ===== QUEST COMMANDS =====
        This:RegisterCommand "HailActor" "Quest" "Hail NPC with optional dialog choices\nParam: NPCName or NPCName,choice1,choice2..."
        This:RegisterCommand "HailAndAcceptQuest" "Quest" "Hail NPC and auto-accept quest\nParam: NPCName"
        This:RegisterCommand "ClickActor" "Quest" "Double-click actor (quest items, doors)\nParam: ActorName"
        This:RegisterCommand "ClickActorUntilUpdate" "Quest" "Click actor until quest updates\nParam: ActorName,QuestName,MaxAttempts"
        This:RegisterCommand "LoopUntilFaction" "Quest" "Repeat quest for faction grinding\nParam: QuestName,FactionName,TargetValue"
        This:RegisterCommand "WaitForQuestStep" "Quest" "Wait for quest step completion\nParam: QuestName,StepKeyword"
        This:RegisterCommand "ConversationSequence" "Quest" "Click conversation bubble choices in sequence\nParam: choice1,choice2,choice3... (e.g. 1,1,3,1)"
        This:RegisterCommand "ReplySequence" "Quest" "Select reply dialog options in sequence\nParam: option1,option2,option3... (e.g. 1,2,1)"

        ; ===== GATHERING COMMANDS =====
        This:RegisterCommand "GatherNode" "Gathering" "Harvest single resource node\nParam: NodeName"
        This:RegisterCommand "GatherNodeUntilUpdate" "Gathering" "Gather until quest updates\nParam: NodeName,QuestName,MaxAttempts"
        This:RegisterCommand "GatherMultipleNodes" "Gathering" "Gather multiple node types for quest\nParam: QuestName,Node1;Node2;Node3,MaxAttempts"

        ; ===== CRAFTING COMMANDS =====
        This:RegisterCommand "CraftItem" "Crafting" "Craft item with quantity\nParam: ItemName,Quantity"
        This:RegisterCommand "CraftUntilUpdate" "Crafting" "Craft until quest updates\nParam: ItemName,QuestName,MaxAttempts"
        This:RegisterCommand "ScribeRecipe" "Crafting" "Learn recipe from inventory\nParam: RecipeName"
        This:RegisterCommand "ScribeAndCraft" "Crafting" "Scribe and craft in one command\nParam: RecipeName,Quantity"

        ; ===== COMBAT COMMANDS =====
        This:RegisterCommand "KillUntilUpdate" "Combat" "Kill mobs until quest updates\nParam: MobName,QuestName,MaxKills"
        This:RegisterCommand "CastAbility" "Combat" "Cast specific ability\nParam: AbilityName"
        This:RegisterCommand "UseItem" "Combat" "Use item from inventory\nParam: ItemName"
        This:RegisterCommand "DisableCombat" "Combat" "Turn off OgreBot combat\nParam: none"
        This:RegisterCommand "EnableCombat" "Combat" "Turn on OgreBot combat\nParam: none"
        This:RegisterCommand "ZoneReset" "Combat" "Reset current instance\nParam: none"

        ; ===== TRAVEL COMMANDS =====
        This:RegisterCommand "TravelBell" "Travel" "Travel via bell network\nParam: Destination"
        This:RegisterCommand "TravelSpire" "Travel" "Travel via spire network\nParam: Destination"
        This:RegisterCommand "TravelDruid" "Travel" "Travel via druid rings\nParam: Destination"
        This:RegisterCommand "Door" "Travel" "Use zone door\nParam: OptionNumber"
        This:RegisterCommand "WaitForZoned" "Travel" "Wait for zone transition\nParam: none"
        This:RegisterCommand "PortalToGuildHall" "Travel" "Portal to guild hall\nParam: none"

        ; ===== UTILITY COMMANDS =====
        This:RegisterCommand "Wait" "Utility" "Pause for seconds\nParam: Seconds"
        This:RegisterCommand "Mount" "Utility" "Mount up\nParam: none"
        This:RegisterCommand "Dismount" "Utility" "Dismount\nParam: none"
        This:RegisterCommand "RepairGear" "Utility" "Repair at merchant\nParam: none"
        This:RegisterCommand "Jump" "Utility" "Make character jump\nParam: none"
        This:RegisterCommand "Evac" "Utility" "Use evacuation ability\nParam: none"
        This:RegisterCommand "Loop" "Utility" "Loop waypoint path\nParam: LoopCount"
        This:RegisterCommand "Reverse" "Utility" "Reverse path direction\nParam: none"
    }

    method RegisterCommand(string cmdName, string category, string help)
    {
        CommandCategory:Set["${cmdName}", "${category}"]
        CommandHelp:Set["${cmdName}", "${help}"]

        ; Track by category for filtering
        if !${CommandsByCategory.Element["${category}"](exists)}
        {
            CommandsByCategory:Set["${category}", "${cmdName}"]
        }
        else
        {
            CommandsByCategory:Set["${category}", "${CommandsByCategory.Element["${category}"]};${cmdName}"]
        }
    }

    ; ============================================
    ; COMMAND EXECUTION
    ; ============================================

    ; Execute command by name with parameters
    method ExecuteCommand(string commandName, string parameters)
    {
        echo [CommandRegistry] Executing: ${commandName} (${parameters})

        if !${CommandCategory.Element["${commandName}"](exists)}
        {
            echo [CommandRegistry] ERROR: Command '${commandName}' not found
            return
        }

        ; Execute the appropriate command object
        switch ${commandName}
        {
            ; Quest Commands
            case HailActor
                HailActor:Execute["${parameters}"]
                break
            case HailAndAcceptQuest
                HailAndAcceptQuest:Execute["${parameters}"]
                break
            case ClickActor
                ClickActor:Execute["${parameters}"]
                break
            case ClickActorUntilUpdate
                ClickActorUntilUpdate:Execute["${parameters}"]
                break
            case LoopUntilFaction
                LoopUntilFaction:Execute["${parameters}"]
                break
            case WaitForQuestStep
                WaitForQuestStep:Execute["${parameters}"]
                break
            case ConversationSequence
                ConversationSequence:Execute["${parameters}"]
                break
            case ReplySequence
                ReplySequence:Execute["${parameters}"]
                break

            ; Gathering Commands
            case GatherNode
                GatherNode:Execute["${parameters}"]
                break
            case GatherNodeUntilUpdate
                GatherNodeUntilUpdate:Execute["${parameters}"]
                break
            case GatherMultipleNodes
                GatherMultipleNodes:Execute["${parameters}"]
                break

            ; Crafting Commands
            case CraftItem
                CraftItem:Execute["${parameters}"]
                break
            case CraftUntilUpdate
                CraftUntilUpdate:Execute["${parameters}"]
                break
            case ScribeRecipe
                ScribeRecipe:Execute["${parameters}"]
                break
            case ScribeAndCraft
                ScribeAndCraft:Execute["${parameters}"]
                break

            ; Combat Commands
            case KillUntilUpdate
                KillUntilUpdate:Execute["${parameters}"]
                break
            case CastAbility
                CastAbility:Execute["${parameters}"]
                break
            case UseItem
                UseItem:Execute["${parameters}"]
                break
            case DisableCombat
                DisableCombat:Execute["${parameters}"]
                break
            case EnableCombat
                EnableCombat:Execute["${parameters}"]
                break
            case ZoneReset
                ZoneReset:Execute["${parameters}"]
                break

            ; Travel Commands
            case TravelBell
                TravelBell:Execute["${parameters}"]
                break
            case TravelSpire
                TravelSpire:Execute["${parameters}"]
                break
            case TravelDruid
                TravelDruid:Execute["${parameters}"]
                break
            case Door
                Door:Execute["${parameters}"]
                break
            case WaitForZoned
                WaitForZoned:Execute["${parameters}"]
                break
            case PortalToGuildHall
                PortalToGuildHall:Execute["${parameters}"]
                break

            ; Utility Commands
            case Wait
                Wait:Execute["${parameters}"]
                break
            case Mount
                Mount:Execute["${parameters}"]
                break
            case Dismount
                Dismount:Execute["${parameters}"]
                break
            case RepairGear
                RepairGear:Execute["${parameters}"]
                break
            case Jump
                Jump:Execute["${parameters}"]
                break
            case Evac
                Evac:Execute["${parameters}"]
                break
            case Loop
                Loop:Execute["${parameters}"]
                break
            case Reverse
                Reverse:Execute["${parameters}"]
                break

            default
                echo [CommandRegistry] ERROR: Command '${commandName}' not implemented
                break
        }
    }

    ; ============================================
    ; QUERY METHODS
    ; ============================================

    ; Get all commands in a category
    member:string GetCommandsByCategory(string category)
    {
        if ${CommandsByCategory.Element["${category}"](exists)}
        {
            return "${CommandsByCategory.Element["${category}"]}"
        }

        return ""
    }

    ; Get command help text
    member:string GetCommandHelp(string commandName)
    {
        if ${CommandHelp.Element["${commandName}"](exists)}
        {
            return "${CommandHelp.Element["${commandName}"]}"
        }

        return "No help available"
    }

    ; Get command category
    member:string GetCommandCategory(string commandName)
    {
        if ${CommandCategory.Element["${commandName}"](exists)}
        {
            return "${CommandCategory.Element["${commandName}"]}"
        }

        return "Unknown"
    }

    ; Check if command exists
    member:bool CommandExists(string commandName)
    {
        return ${CommandCategory.Element["${commandName}"](exists)}
    }

    ; Get total command count
    member:int GetCommandCount()
    {
        return ${CommandCategory.Used}
    }

    ; Print registry summary
    method PrintSummary()
    {
        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
        {
            echo [CommandRegistry] ========================================
            echo [CommandRegistry] COMMAND REGISTRY SUMMARY
            echo [CommandRegistry] ========================================
            echo [CommandRegistry] Total Commands: ${This.GetCommandCount}
            echo [CommandRegistry]
            echo [CommandRegistry] Quest Commands: ${This.GetCommandsByCategory["Quest"].Count[";"]}
            echo [CommandRegistry] Gathering Commands: ${This.GetCommandsByCategory["Gathering"].Count[";"]}
            echo [CommandRegistry] Crafting Commands: ${This.GetCommandsByCategory["Crafting"].Count[";"]}
            echo [CommandRegistry] Combat Commands: ${This.GetCommandsByCategory["Combat"].Count[";"]}
            echo [CommandRegistry] Travel Commands: ${This.GetCommandsByCategory["Travel"].Count[";"]}
            echo [CommandRegistry] Utility Commands: ${This.GetCommandsByCategory["Utility"].Count[";"]}
            echo [CommandRegistry] ========================================
        }
    }
}

; ============================================
; GLOBAL INSTANCE
; ============================================
variable(global) JB_CommandRegistry JBCmdRegistry
