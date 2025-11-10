/*
* JQuestBotRelay - Relay Command Handler System
* Path: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/JQuestBotRelay.iss
*
* Handles QB_ relay commands from main automation systems
* All waits removed from atoms and moved to queued functions
*/

variable(global) string J_QuestBotRelay_Version = "2.0.1"

atom(global) QB_OgreBotCustomCommand(
string Command,
string ForWho="",
string ControlName="",
string Action="",
string Value="",
string Extra1="",
string Extra2="",
string Extra3=""
)
{
    ; Check if this command is for me
    if !${CommandForMe["${ForWho}"]}
    return

    ; Queue the actual work (no waits in atoms!)
    switch ${Command}
    {
        case Ogre_Change_UI
            QueueCommand "call HandleUIChange \"${ForWho}\" \"${ControlName}\" \"${Action}\" \"${Value}\""
            break

        case Ogre_Object
            QueueCommand "call HandleOgreObject \"${ForWho}\" \"${ControlName}\" \"${Action}\" \"${Value}\""
            break

        case Navigation
            QueueCommand "call HandleNavigation \"${ForWho}\" \"${ControlName}\" \"${Action}\" \"${Value}\""
            break

        case SetCheckbox
            QueueCommand "call HandleSetCheckbox \"${ForWho}\" \"${ControlName}\" \"${Action}\""
            break

        case SetValue
            QueueCommand "call HandleSetValue \"${ForWho}\" \"${ControlName}\" \"${Value}\""
            break

        case ClickButton
            QueueCommand "call HandleClickButton \"${ForWho}\" \"${ControlName}\""
            break

        default
        echo ${Time}: [Relay] Unknown OgreBotCustom command: ${Command}
        break
    }
}

function HandleUIChange(string ForWho, string ControlName, string Action, string Value)
{
    if !${UIElement["${ControlName}"](exists)}
    {
        echo ${Time}: [Relay] UI element not found: ${ControlName}
        return
    }

    switch ${Action}
    {
        case SetValue
            UIElement["${ControlName}"]:SetValue[${Value}]
            break

        case SetChecked
            if !${UIElement["${ControlName}"].Checked}
            UIElement["${ControlName}"]:LeftClick
            break

        case SetUnchecked
            if ${UIElement["${ControlName}"].Checked}
            UIElement["${ControlName}"]:LeftClick
            break

        case Toggle
            UIElement["${ControlName}"]:LeftClick
            break

        case LeftClick
            UIElement["${ControlName}"]:LeftClick
            break

        case RightClick
            UIElement["${ControlName}"]:RightClick
            break

        default
        echo ${Time}: [Relay] Unknown UI action: ${Action}
        break
    }

    wait 2
}

function HandleSetCheckbox(string ForWho, string ControlName, string Action)
{
    if !${UIElement["${ControlName}"](exists)}
    {
        echo ${Time}: [Relay] Checkbox not found: ${ControlName}
        return
    }

    if ${Action.Equal["SetChecked"]} || ${Action.Equal["enable"]} || ${Action.Equal["true"]}
    {
        if !${UIElement["${ControlName}"].Checked}
        UIElement["${ControlName}"]:LeftClick
    }
    elseif ${Action.Equal["SetUnchecked"]} || ${Action.Equal["disable"]} || ${Action.Equal["false"]}
    {
        if ${UIElement["${ControlName}"].Checked}
        UIElement["${ControlName}"]:LeftClick
    }
    else
    {
        ; Toggle
        UIElement["${ControlName}"]:LeftClick
    }

    wait 2
}

function HandleSetValue(string ForWho, string ControlName, string Value)
{
    if !${UIElement["${ControlName}"](exists)}
    {
        echo ${Time}: [Relay] UI element not found: ${ControlName}
        return
    }

    UIElement["${ControlName}"]:SetValue[${Value}]
    wait 2
}

function HandleClickButton(string ForWho, string ControlName)
{
    if !${UIElement["${ControlName}"](exists)}
    {
        echo ${Time}: [Relay] Button not found: ${ControlName}
        return
    }

    UIElement["${ControlName}"]:LeftClick
    wait 2
}

function HandleOgreObject(string ForWho, string ObjectName, string Action, string Target)
{
    echo ${Time}: [Relay] Ogre_Object: ${ObjectName} ${Action} ${Target}
    ; Implementation depends on specific needs
}

function HandleNavigation(string ForWho, string NavType, string Param1, string Param2)
{
    echo ${Time}: [Relay] Navigation: ${NavType}
    ; Implementation depends on navigation system
}

atom(global) QB_OgreCraftCommand(
string Command,
string ForWho="",
string QueueFile="",
string RecipeName="",
string Count="",
string Extra1=""
)
{
    ; Check if this command is for me
    if !${CommandForMe["${ForWho}"]}
    return

    ; Queue the actual work (no waits in atoms!)
    switch ${Command}
    {
        case Load_Craft_Bot
            QueueCommand "call HandleLoadCraftBot \"${ForWho}\""
            break

        case Load_Queue_File
            QueueCommand "call HandleLoadQueueFile \"${ForWho}\" \"${QueueFile}\""
            break

        case Start_Craft_Queue
            QueueCommand "call HandleStartCraftQueue \"${ForWho}\""
            break

        case Stop_Craft_Queue
            QueueCommand "call HandleStopCraftQueue \"${ForWho}\""
            break

        case AddRecipeName
            QueueCommand "call HandleAddRecipe \"${ForWho}\" \"${RecipeName}\" \"${Count}\""
            break

        case Change_UI
            QueueCommand "call HandleCraftUIChange \"${ForWho}\" \"${QueueFile}\" \"${RecipeName}\" \"${Count}\""
            break

        case Clear_Queue
            QueueCommand "call HandleClearQueue \"${ForWho}\""
            break

        default
        echo ${Time}: [Relay] Unknown OgreCraft command: ${Command}
        break
    }
}

function HandleLoadCraftBot(string ForWho)
{
    echo ${Time}: [Relay] Loading OgreCraft...

    ; Load OgreCraft if not already loaded
    if !${Script[OgreCraft](exists)}
    {
        run OgreCraft
        wait 50
    }

    ; Wait for ready
    variable int timeout = 0
    while !${OgreCraft.IsReady} && ${timeout} < 100
    {
        wait 5
        timeout:Inc
    }

    if ${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] OgreCraft ready
    }
    else
    {
        echo ${Time}: [Relay] OgreCraft failed to load
    }
}

function HandleLoadQueueFile(string ForWho, string QueueFile)
{
    if !${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] OgreCraft not ready
        return
    }

    echo ${Time}: [Relay] Loading craft queue: ${QueueFile}

    OgreCraft:LoadQueue["${QueueFile}"]

    wait 10

    variable int timeout = 0
    while ${OgreCraft.RecipesInQueue} == 0 && ${timeout} < 50
    {
        wait 5
        timeout:Inc
    }

    if ${OgreCraft.RecipesInQueue} > 0
    {
        echo ${Time}: [Relay] Queue loaded: ${OgreCraft.RecipesInQueue} recipes
    }
    else
    {
        echo ${Time}: [Relay] Queue appears empty
    }
}

function HandleStartCraftQueue(string ForWho)
{
    if !${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] OgreCraft not ready
        return
    }

    if ${OgreCraft.RecipesInQueue} == 0
    {
        echo ${Time}: [Relay] No recipes in queue
        return
    }

    echo ${Time}: [Relay] Starting craft queue...
    OgreCraft:StartQueue
}

function HandleStopCraftQueue(string ForWho)
{
    if ${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] Stopping craft queue...
        OgreCraft:StopQueue
    }
}

function HandleAddRecipe(string ForWho, string RecipeName, string Count)
{
    if !${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] OgreCraft not ready
        return
    }

    variable int recipeCount = 1
    if ${Count.Length}
    recipeCount:Set[${Count}]

    echo ${Time}: [Relay] Adding recipe: ${RecipeName} x${recipeCount}
    OgreCraft:AddRecipe["${RecipeName}",${recipeCount}]
}

function HandleClearQueue(string ForWho)
{
    if ${OgreCraft.IsReady}
    {
        echo ${Time}: [Relay] Clearing craft queue...
        OgreCraft:ClearQueue
    }
}

function HandleCraftUIChange(string ForWho, string UIElement, string Action, string Value)
{
    echo ${Time}: [Relay] OgreCraft UI: ${UIElement} ${Action} ${Value}
    ; Implementation depends on specific UI needs
}

atom(global) QB_QuestBotCommands(
string Command,
string ForWho="",
string ActorName="",
string VerbName="",
string DialogueOption="",
string Extra1="",
string Extra2="",
string Extra3="",
string Extra4="",
string Extra5=""
)
{
    ; Check if this command is for me
    if !${CommandForMe["${ForWho}"]}
    return

    ; Queue the actual work (no waits in atoms!)
    switch ${Command}
    {
        case Actor_DoubleClick
            QueueCommand "call HandleActorDoubleClick \"${ActorName}\""
            break

        case Apply_Verb
            QueueCommand "call HandleApplyVerb \"${ActorName}\" \"${VerbName}\""
            break

        case Hail
            QueueCommand "call HandleHail \"${ActorName}\""
            break

        case NPC_Dialogue
            QueueCommand "call HandleNPCDialogue \"${DialogueOption}\""
            break

        case Open_Door
            QueueCommand "call HandleOpenDoor \"${ActorName}\""
            break

        case Read_Book
            QueueCommand "call HandleReadBook \"${ActorName}\""
            break

        case Harvest_Quest_Item
            QueueCommand "call HandleHarvestQuestItem \"${ActorName}\" \"${VerbName}\""
            break

        case Target_Actor
            QueueCommand "call HandleTargetActor \"${ActorName}\""
            break

        case Clear_Target
            QueueCommand "call HandleClearTarget"
            break

        case Use_Item
            QueueCommand "call HandleUseItem \"${ActorName}\""
            break

        case Accept_Reward
            QueueCommand "call HandleAcceptReward \"${ActorName}\""
            break

        case Wait_For_Combat
            QueueCommand "call HandleWaitForCombat"
            break

        case Wait_While_Combat
            QueueCommand "call HandleWaitWhileCombat"
            break

        default
        echo ${Time}: [Relay] Unknown QuestBot command: ${Command}
        break
    }
}

function HandleActorDoubleClick(string ActorName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [Relay] Double-clicking: ${ActorName}
        Actor[${actorID}]:DoubleClick
        wait 10
    }
    else
    {
        echo ${Time}: [Relay] Actor not found: ${ActorName}
    }
}

function HandleApplyVerb(string ActorName, string VerbName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [Relay] Applying verb '${VerbName}' to ${ActorName}
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}].Verb["${VerbName}"]:Execute
        wait 10
    }
    else
    {
        echo ${Time}: [Relay] Actor not found: ${ActorName}
    }
}

function HandleHail(string ActorName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [Relay] Hailing: ${ActorName}
        Actor[${actorID}]:DoTarget
        wait 5
        eq2execute /hail
        wait 10
    }
    else
    {
        echo ${Time}: [Relay] Actor not found: ${ActorName}
    }
}

function HandleNPCDialogue(string DialogueOption)
{
    echo ${Time}: [Relay] NPC Dialogue: ${DialogueOption}
    ; Implementation depends on dialogue system
}

function HandleOpenDoor(string DoorName)
{
    variable int doorID = ${Actor["${DoorName}"].ID}

    if ${doorID}
    {
        echo ${Time}: [Relay] Opening door: ${DoorName}
        Actor[${doorID}]:DoubleClick
        wait 10
    }
    else
    {
        echo ${Time}: [Relay] Door not found: ${DoorName}
    }
}

function HandleReadBook(string BookName)
{
    echo ${Time}: [Relay] Reading book: ${BookName}
    ; Implementation needed
}

function HandleHarvestQuestItem(string ItemName, string Count)
{
    echo ${Time}: [Relay] Harvesting quest item: ${ItemName}
    ; Implementation needed
}

function HandleTargetActor(string ActorName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [Relay] Targeting: ${ActorName}
        Actor[${actorID}]:DoTarget
        wait 5
    }
    else
    {
        echo ${Time}: [Relay] Actor not found: ${ActorName}
    }
}

function HandleClearTarget()
{
    echo ${Time}: [Relay] Clearing target
    eq2execute /target_none
    wait 5
}

function HandleUseItem(string ItemName)
{
    echo ${Time}: [Relay] Using item: ${ItemName}
    ; Implementation needed
}

function HandleAcceptReward(string RewardNumber)
{
    echo ${Time}: [Relay] Accepting reward: ${RewardNumber}
    ; Implementation needed
}

function HandleWaitForCombat()
{
    echo ${Time}: [Relay] Waiting for combat to start...

    variable int timeout = 0
    while !${Me.InCombat} && ${timeout} < 300
    {
        wait 10
        timeout:Inc
    }

    if ${Me.InCombat}
    {
        echo ${Time}: [Relay] Combat started
    }
    else
    {
        echo ${Time}: [Relay] Combat timeout
    }
}

function HandleWaitWhileCombat()
{
    echo ${Time}: [Relay] Waiting for combat to end...

    while ${Me.InCombat}
    {
        wait 10
    }

    echo ${Time}: [Relay] Combat ended
}

atom(global) QB_NavigationCommand(
string Command,
string ForWho="",
string Param1="",
string Param2="",
string Param3="",
string Param4=""
)
{
    ; Check if this command is for me
    if !${CommandForMe["${ForWho}"]}
    return

    ; Queue the actual work (no waits in atoms!)
    switch ${Command}
    {
        case GoTo
        case Waypoint
            QueueCommand "call HandleGoToWaypoint \"${Param1}\" \"${Param2}\" \"${Param3}\" \"${Param4}\""
            break

        case Face
            QueueCommand "call HandleFace \"${Param1}\" \"${Param2}\""
            break

        case StopMovement
            QueueCommand "call HandleStopMovement"
            break

        default
        echo ${Time}: [Relay] Unknown Navigation command: ${Command}
        break
    }
}

function HandleGoToWaypoint(string X, string Y, string Z, string Tolerance)
{
    variable float fX = ${X}
    variable float fY = ${Y}
    variable float fZ = ${Z}
    variable float fTolerance = 3.0

    if ${Tolerance.Length}
    fTolerance:Set[${Tolerance}]

    echo ${Time}: [Relay] Navigating to: ${fX}, ${fY}, ${fZ}

    ; Call navigation system if available
    if ${Obj_JNav(exists)}
    {
        Obj_JNav:NavigateToWaypoint ${fX} ${fY} ${fZ} ${fTolerance}
    }
}

function HandleFace(string X, string Z)
{
    variable float fX = ${X}
    variable float fZ = ${Z}

    echo ${Time}: [Relay] Facing: ${fX}, ${fZ}
    face ${fX} ${fZ}
}

function HandleStopMovement()
{
    echo ${Time}: [Relay] Stopping movement
    press -release w
    press -release a
    press -release s
    press -release d
}

function:bool CommandForMe(string TargetName)
{
    ; Check if this command should be executed by this character

    if ${TargetName.Equal["all"]} || ${TargetName.Equal["All"]}
    return TRUE

    if ${TargetName.Equal["${Me.Name}"]}
    return TRUE

    ; Check for group identifiers
    if ${TargetName.Equal["igw:${Me.Name}"]}
    return TRUE

    ; Check for class/role identifiers
    if ${TargetName.Equal["tanks"]} || ${TargetName.Equal["tank"]}
    {
        if ${Me.Class.Equal["guardian"]} || ${Me.Class.Equal["berserker"]} || ${Me.Class.Equal["monk"]} || ${Me.Class.Equal["bruiser"]} || ${Me.Class.Equal["paladin"]} || ${Me.Class.Equal["shadowknight"]}
        return TRUE
    }

    if ${TargetName.Equal["healers"]} || ${TargetName.Equal["healer"]}
    {
        if ${Me.Class.Equal["warden"]} || ${Me.Class.Equal["fury"]} || ${Me.Class.Equal["templar"]} || ${Me.Class.Equal["inquisitor"]} || ${Me.Class.Equal["mystic"]} || ${Me.Class.Equal["defiler"]} || ${Me.Class.Equal["channeler"]}
        return TRUE
    }

    if ${TargetName.Equal["dps"]}
    {
        if ${Me.Class.Equal["ranger"]} || ${Me.Class.Equal["assassin"]} || ${Me.Class.Equal["brigand"]} || ${Me.Class.Equal["swashbuckler"]} || ${Me.Class.Equal["troubador"]} || ${Me.Class.Equal["dirge"]} || ${Me.Class.Equal["wizard"]} || ${Me.Class.Equal["warlock"]} || ${Me.Class.Equal["conjuror"]} || ${Me.Class.Equal["necromancer"]} || ${Me.Class.Equal["coercer"]} || ${Me.Class.Equal["illusionist"]}
        return TRUE
    }

    if ${TargetName.Equal["casters"]} || ${TargetName.Equal["caster"]}
    {
        if ${Me.Class.Equal["wizard"]} || ${Me.Class.Equal["warlock"]} || ${Me.Class.Equal["conjuror"]} || ${Me.Class.Equal["necromancer"]} || ${Me.Class.Equal["coercer"]} || ${Me.Class.Equal["illusionist"]}
        return TRUE
    }

    if ${TargetName.Equal["melee"]}
    {
        if ${Me.Class.Equal["ranger"]} || ${Me.Class.Equal["assassin"]} || ${Me.Class.Equal["brigand"]} || ${Me.Class.Equal["swashbuckler"]} || ${Me.Class.Equal["monk"]} || ${Me.Class.Equal["bruiser"]}
        return TRUE
    }

    if ${TargetName.Equal["Fighter"]} || ${TargetName.Equal["fighters"]}
    {
        if ${Me.Class.Equal["guardian"]} || ${Me.Class.Equal["berserker"]} || ${Me.Class.Equal["monk"]} || ${Me.Class.Equal["bruiser"]} || ${Me.Class.Equal["paladin"]} || ${Me.Class.Equal["shadowknight"]}
        return TRUE
    }

    if ${TargetName.Equal["Priest"]} || ${TargetName.Equal["priests"]}
    {
        if ${Me.Class.Equal["warden"]} || ${Me.Class.Equal["fury"]} || ${Me.Class.Equal["templar"]} || ${Me.Class.Equal["inquisitor"]} || ${Me.Class.Equal["mystic"]} || ${Me.Class.Equal["defiler"]} || ${Me.Class.Equal["channeler"]}
        return TRUE
    }

    if ${TargetName.Equal["Scout"]} || ${TargetName.Equal["scouts"]}
    {
        if ${Me.Class.Equal["ranger"]} || ${Me.Class.Equal["assassin"]} || ${Me.Class.Equal["brigand"]} || ${Me.Class.Equal["swashbuckler"]} || ${Me.Class.Equal["troubador"]} || ${Me.Class.Equal["dirge"]}
        return TRUE
    }

    if ${TargetName.Equal["Mage"]} || ${TargetName.Equal["mages"]}
    {
        if ${Me.Class.Equal["wizard"]} || ${Me.Class.Equal["warlock"]} || ${Me.Class.Equal["conjuror"]} || ${Me.Class.Equal["necromancer"]} || ${Me.Class.Equal["coercer"]} || ${Me.Class.Equal["illusionist"]}
        return TRUE
    }

    return FALSE
}