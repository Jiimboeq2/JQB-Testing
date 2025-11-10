/*
 * JB_PlaybackCommands.iss
 *
 * Playback command library for ISX_JQB automation system
 * These commands are used by:
 * - XML waypoint playback
 * - JSON instance scripts
 * - UI automation features
 * - QuestBot integration
 *
 * Categories:
 * - Travel (bells, spires, druid rings, zone doors)
 * - Quest interactions (hail, doubleclick, verbs, items)
 * - Combat/Wait (zone waiting, combat waiting)
 * - Crafting
 * - OgreBot integration
 *
 * NOTE: This is DIFFERENT from Object_Everquest2CommandParser.iss
 * That file handles live OgreBot commands (oc !ci -)
 * This file handles scripted playback commands for automation
 *
 * =====================================================
 * QUICK START GUIDE - COMMON USAGE EXAMPLES
 * =====================================================
 *
 * TRAVEL:
 *   call Cmd_TravelBell "Thundering Steppes"
 *   call Cmd_TravelSpire "Commonlands"
 *   call Cmd_TravelDruid "Steamfont"
 *   call Cmd_PortalToGuildHall
 *
 * XML FORMAT:
 *   <Command Type="TravelBell" Value="Thundering Steppes" />
 *   <Command Type="TravelSpire" Value="Commonlands" />
 *   <Command Type="PortalToGuildHall" />
 *
 * QUEST INTERACTIONS:
 *   ; Simple hail
 *   call Cmd_Hail "Scout Malachi"
 *
 *   ; Hail with conversation options
 *   call Cmd_Hail "Scout Malachi,1,2,3"
 *
 *   ; Hail with conversation bubbles (c) and reply dialogs (r)
 *   call Cmd_Hail "Scout Malachi,c1,c2,r1"
 *
 *   ; Reply dialog with multiple selections
 *   call Cmd_ReplyDialog "1,2,1"
 *
 *   ; Other quest commands
 *   call Cmd_DoubleClick "a treasure chest"
 *   call Cmd_AcceptQuest "Gathering Silk"
 *
 * XML FORMAT:
 *   <Command Type="Hail" Value="Scout Malachi,1,2,3" />
 *   <Command Type="ReplyDialog" Value="1,2,1" />
 *   <Command Type="AcceptQuest" Value="Gathering Silk" />
 *
 * FACTION GRINDING:
 *   ; Repeat quest until Riliss faction >= 40000
 *   call Cmd_RepeatQuestUntilFaction "Gathering Silk,Riliss,40000"
 *
 *   ; Check current faction value
 *   variable int myFaction = ${Get_Faction["Riliss","Get_Value"]}
 *   variable string factionStanding = ${Get_Faction["Riliss","Get_SpewStat"]}
 *
 * WAITING:
 *   call Cmd_Wait "10"
 *   call Cmd_WaitForZoned
 *   call Cmd_WaitWhileCombat
 *
 * COMBAT CONTROL (for raid mechanics):
 *   call Cmd_Disable_AOEs "TRUE"
 *   call Cmd_Disable_Interrupts
 *   call Cmd_Enable_Interrupts
 *   call Cmd_SetCS_NPC "0,a named mob,5"
 *
 * CRAFTING:
 *   call Cmd_Craft_AddRecipe "1,Rough Linen Tunic"
 *   call Cmd_Craft_Start
 *
 * MERCHANTS:
 *   call Cmd_OpenAndBuyFromMerchant "Merchant Bob,Bread,10"
 *
 * MOVEMENT:
 *   call Cmd_Waypoint "100.5,200.3,50.2"
 *   call Cmd_SetCS_BehindNPC "a raid boss,5"
 *
 * AUTOTARGET (for raid mechanics):
 *   call Cmd_Ob_AutoTarget_Clear
 *   call Cmd_Ob_AutoTarget_AddActor "a fanatic Allu'thoa,0,FALSE,FALSE"
 *
 * =====================================================
 * SIMPLIFIED COMMANDS (Easier to Read & Write!)
 * =====================================================
 * These are simplified versions of complex old patterns
 *
 * QUEST SHORTCUTS:
 *   ; Hail and accept quest in one command
 *   call Cmd_HailAndAcceptQuest "Hydona"
 *
 *   ; Click actors (quest items, doors, etc)
 *   call Cmd_ClickActor "Brine Jar"
 *
 *   ; Click actors repeatedly until quest updates
 *   call Cmd_ClickActorUntilUpdate "Brine Jar,Despite the challenge,10"
 *
 *   ; Wait for quest step to complete
 *   call Cmd_WaitForQuestStep "Despite the challenge,crates"
 *
 * GATHERING (HARVEST QUESTS):
 *   ; Gather from harvest nodes (single attempt)
 *   call Cmd_GatherNode "aether roots"
 *
 *   ; Gather repeatedly until quest updates (RECOMMENDED!)
 *   call Cmd_GatherNodeUntilUpdate "aether roots,Test Your Mettle: Where?,10"
 *
 *   ; Gather multiple node types until quest completes (REPLACES Path -QA!)
 *   call Cmd_GatherMultipleNodes "Test Your Mettle,aether roots;rough ore;animal den,15"
 *
 * KILL QUESTS:
 *   ; Kill NPCs repeatedly until quest updates (uses OgreBot autotarget)
 *   call Cmd_KillUntilUpdate "a gnoll scout,Gnoll Slayer,15"
 *
 * CRAFTING QUESTS:
 *   ; Craft an item (adds to queue and starts)
 *   call Cmd_CraftItem "Preening Oil,1"
 *
 *   ; Craft repeatedly until quest updates
 *   call Cmd_CraftUntilUpdate "Rough Linen Tunic,Crafting Tutorial,10"
 *
 *   ; Scribe a recipe
 *   call Cmd_ScribeRecipe "Invisibility Potion for Burnish"
 *
 *   ; Scribe and craft in one command!
 *   call Cmd_ScribeAndCraft "Invisibility Potion for Burnish,1"
 *
 * XML FORMAT (Much cleaner than old Path -QA flags!):
 *   <!-- Quest shortcuts -->
 *   <Command Type="HailAndAcceptQuest" Value="Hydona" />
 *   <Command Type="ClickActor" Value="Brine Jar" />
 *   <Command Type="ClickActorUntilUpdate" Value="Brine Jar,Quest Name,10" />
 *
 *   <!-- Gathering -->
 *   <Command Type="GatherNode" Value="aether roots" />
 *   <Command Type="GatherNodeUntilUpdate" Value="aether roots,Quest Name,10" />
 *   <Command Type="GatherMultipleNodes" Value="Quest Name,node1;node2;node3,15" />
 *
 *   <!-- Killing -->
 *   <Command Type="KillUntilUpdate" Value="a gnoll scout,Quest Name,15" />
 *
 *   <!-- Crafting -->
 *   <Command Type="CraftItem" Value="Preening Oil,1" />
 *   <Command Type="CraftUntilUpdate" Value="Recipe Name,Quest Name,10" />
 *   <Command Type="ScribeAndCraft" Value="Recipe Name,1" />
 *
 *   <!-- Quest completion -->
 *   <Command Type="WaitForQuestStep" Value="Quest Name,step text" />
 *
 * =====================================================
 * COMPLETE XML QUEST EXAMPLE
 * =====================================================
 * <?xml version="1.0" encoding="UTF-8"?>
 * <Waypoints>
 *     <!-- Travel to quest zone -->
 *     <Command Type="TravelBell" Value="Thundering Steppes" />
 *     <Command Type="WaitForZoned" />
 *
 *     <!-- Walk to quest giver -->
 *     <Waypoint X="100.5" Y="50.2" Z="-200.3" />
 *     <Waypoint X="150.2" Y="55.1" Z="-250.8" />
 *
 *     <!-- Talk to quest giver and accept quest -->
 *     <Command Type="Hail" Value="Scout Malachi,1,2" />
 *     <Command Type="AcceptQuest" Value="Gathering Silk" />
 *
 *     <!-- Walk to quest objective -->
 *     <Waypoint X="200.1" Y="60.5" Z="-300.2" />
 *
 *     <!-- Double click quest object -->
 *     <Command Type="DoubleClick" Value="silk bundle" />
 *     <Command Type="Wait" Value="20" />
 *
 *     <!-- Return to quest giver -->
 *     <Waypoint X="150.2" Y="55.1" Z="-250.8" />
 *
 *     <!-- Turn in quest -->
 *     <Command Type="Hail" Value="Scout Malachi" />
 *     <Command Type="ReplyDialog" Value="1" />
 * </Waypoints>
 * =====================================================
 */

variable(global) string JB_PlaybackCommands_Version = "1.1.0"

/*
 * =====================================================
 * TRAVEL COMMAND IMPLEMENTATIONS
 * =====================================================
 */

function Cmd_TravelBell(string destination)
{
    echo ${Time}: [TravelBell] Traveling to: ${destination}

    ; Use OgreBot API for bell travel
    ; Parameters: (who, zoneName, exactMatch, multipleZoneOption)
    OgreBotAPI:TravelBell["igw:${Me.Name}","${destination}",FALSE,"LAST_ENTRY"]
    wait 20

    ; Wait for zoning to complete
    call Cmd_WaitForZoned
}

function Cmd_TravelSpire(string destination)
{
    echo ${Time}: [TravelSpire] Traveling to: ${destination}

    ; Use OgreBot API for spire travel
    ; Parameters: (who, zoneName, exactMatch, multipleZoneOption)
    OgreBotAPI:TravelSpires["igw:${Me.Name}","${destination}",FALSE,"LAST_ENTRY"]
    wait 20

    ; Wait for zoning to complete
    call Cmd_WaitForZoned
}

function Cmd_TravelDruid(string destination)
{
    echo ${Time}: [TravelDruid] Traveling to: ${destination}

    ; Use OgreBot API for druid ring travel
    ; Parameters: (who, zoneName, exactMatch, multipleZoneOption)
    OgreBotAPI:TravelDruid["igw:${Me.Name}","${destination}",FALSE,"LAST_ENTRY"]
    wait 20

    ; Wait for zoning to complete
    call Cmd_WaitForZoned
}

function Cmd_UseEverporter(string destination)
{
    echo ${Time}: [Everporter] Traveling to: ${destination}

    variable string GHActor = "Guild Portal Mage"

    ; Check if we're in guild hall
    if !${Zone.ShortName.Find["guildhall"]}
    {
        echo ${Time}: [Everporter] ERROR: Not in guild hall
        return
    }

    ; Check if everporter exists
    if !${Actor[Query, Name == "${GHActor}"](exists)}
    {
        echo ${Time}: [Everporter] ERROR: Everporter not found
        return
    }

    call move_to_actor ${Actor[Query, Name == "${GHActor}"].ID}
    wait 5
    oc !ci -Actor_Click igw:${Me.Name} ${Actor[Query, Name == "${GHActor}"].ID} TRUE
    wait 15
    oc !ci -ZoneDoorForWho igw:${Me.Name} "${destination}"
    wait 20

    call Cmd_WaitForZoned
}

function Cmd_ZoneDoor(string doorNumber)
{
    echo ${Time}: [ZoneDoor] Using door ${doorNumber}
    oc !ci -ZoneDoor igw:${Me.Name} ${doorNumber}
    wait 20
    call Cmd_WaitForZoned
}

function Cmd_Door(string optionNumber)
{
    echo ${Time}: [Door] Clicking door option ${optionNumber}
    oc !ci -OptNum igw:${Me.Name} ${optionNumber}
    wait 10
}

/*
 * =====================================================
 * QUEST INTERACTION IMPLEMENTATIONS
 * =====================================================
 */

/*
 * =====================================================
 * HAIL WITH OPTIONAL DIALOG SELECTIONS
 * =====================================================
 * Usage: Hail actor and optionally select conversation/reply options
 *
 * Simple hail:
 *   call Cmd_Hail "Scout Malachi"
 *
 * Hail with conversation bubble selections:
 *   call Cmd_Hail "Scout Malachi,1,2,3"
 *   (Hails, then clicks conversation bubbles 1, 2, 3)
 *
 * Hail with mixed conversation (c) and reply (r) options:
 *   call Cmd_Hail "Scout Malachi,c1,c2,r1"
 *   (Hails, clicks conversation 1, conversation 2, reply dialog 1)
 */

function Cmd_Hail(string params)
{
    variable string actorName = "${params.Token[1,","]}"
    variable int actorID = ${Actor["${actorName}"].ID}

    ; First, hail the actor
    if ${actorID}
    {
        echo ${Time}: [Hail] ${actorName}
        Actor[${actorID}]:DoTarget
        wait 5
        eq2execute /hail
        wait 10
    }
    else
    {
        echo ${Time}: [Hail] ERROR: Actor not found: ${actorName}
        return
    }

    ; If no additional parameters, we're done
    if !${params.Token[2,","](exists)}
        return

    ; Process conversation/reply options
    variable string option
    variable string optionType
    variable int optionNum
    variable int tokenCount = 2

    while ${params.Token[${tokenCount},","](exists)}
    {
        option:Set["${params.Token[${tokenCount},","]}"]

        ; Check if it's conversation (c) or reply (r)
        if ${option.Left[1].Equal["c"]}
        {
            optionNum:Set[${option.Right[-1]}]
            echo ${Time}: [Hail] Selecting conversation bubble ${optionNum}
            OgreBotAPI:ConversationBubble["igw:${Me.Name}","${optionNum}"]
            wait 15
        }
        elseif ${option.Left[1].Equal["r"]}
        {
            optionNum:Set[${option.Right[-1]}]
            echo ${Time}: [Hail] Selecting reply dialog ${optionNum}
            OgreBotAPI:ReplyDialog["igw:${Me.Name}","${optionNum}"]
            wait 15
        }
        else
        {
            ; Assume it's a conversation bubble if no prefix
            optionNum:Set[${option}]
            echo ${Time}: [Hail] Selecting conversation bubble ${optionNum}
            OgreBotAPI:ConversationBubble["igw:${Me.Name}","${optionNum}"]
            wait 15
        }

        tokenCount:Inc
    }
}

; Legacy function names for backwards compatibility
function Cmd_HailAndTalk(string params)
{
    call Cmd_Hail "${params}"
}

function Cmd_HailWithOptions(string params)
{
    ; Legacy wrapper - now just calls Cmd_Hail
    call Cmd_Hail "${params}"
}

function Cmd_DoubleClick(string actorName)
{
    variable int actorID = ${Actor["${actorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [DoubleClick] ${actorName}
        Actor[${actorID}]:DoubleClick
        wait 10
    }
    else
    {
        echo ${Time}: [DoubleClick] ERROR: Actor not found: ${actorName}
    }
}

function Cmd_ApplyVerb(string params)
{
    ; Parameters: actorName,verbName
    variable string actorName = "${params.Token[1,","]}"
    variable string verbName = "${params.Token[2,","]}"
    variable int actorID = ${Actor["${actorName}"].ID}

    if ${actorID}
    {
        echo ${Time}: [ApplyVerb] ${verbName} to ${actorName}
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}].Verb["${verbName}"]:Execute
        wait 10
    }
    else
    {
        echo ${Time}: [ApplyVerb] ERROR: Actor not found: ${actorName}
    }
}

function Cmd_UseItem(string itemName)
{
    if ${Me.Inventory["${itemName}"](exists)}
    {
        echo ${Time}: [UseItem] ${itemName}
        Me.Inventory["${itemName}"]:Use
        wait 10
    }
    else
    {
        echo ${Time}: [UseItem] ERROR: Item not found: ${itemName}
    }
}

function Cmd_Target(string targetName)
{
    if ${targetName.Equal["None"]} || ${targetName.Equal["none"]}
    {
        echo ${Time}: [Target] Clearing target
        eq2execute /target_none
    }
    else
    {
        echo ${Time}: [Target] Targeting: ${targetName}
        Actor["${targetName}"]:DoTarget
    }
    wait 5
}

function Cmd_Special(string actorName)
{
    echo ${Time}: [Special] ${actorName}
    oc !c -Special igw:${Me.Name} "${actorName}"
    wait 20
}

/*
 * =====================================================
 * WAIT/ZONE COMMAND IMPLEMENTATIONS
 * =====================================================
 */

function Cmd_Wait(string seconds)
{
    variable int waitTime = ${seconds}
    echo ${Time}: [Wait] ${waitTime} seconds
    wait ${Math.Calc[${waitTime}*10]}
}

function Cmd_WaitForZone(string zoneName)
{
    echo ${Time}: [WaitForZone] Waiting for: ${zoneName}

    variable int timeout = 600
    variable int counter = 0

    while !${Zone.Name.Find["${zoneName}"]} && !${Zone.ShortName.Find["${zoneName}"]} && ${counter} < ${timeout}
    {
        wait 10
        counter:Inc[1]
    }

    if ${Zone.Name.Find["${zoneName}"]} || ${Zone.ShortName.Find["${zoneName}"]}
    {
        echo ${Time}: [WaitForZone] Arrived at: ${Zone.Name}
    }
    else
    {
        echo ${Time}: [WaitForZone] WARNING: Timeout waiting for ${zoneName}
    }
}

function Cmd_WaitForZoned()
{
    echo ${Time}: [WaitForZoned] Waiting for zoning to complete

    ; Wait for zoning flag to clear and player to exist
    while ${EQ2.Zoning} || !${Me(exists)}
    {
        waitframe
    }

    wait 20
    echo ${Time}: [WaitForZoned] Zoning complete: ${Zone.Name}
}

function Cmd_WaitForCombat(string timeout="30")
{
    variable int maxWait = ${Math.Calc[${timeout}*10]}
    variable int counter = 0

    echo ${Time}: [WaitForCombat] Waiting up to ${timeout} seconds

    while !${Me.InCombat} && ${counter} < ${maxWait}
    {
        wait 10
        counter:Inc[1]
    }

    if ${Me.InCombat}
    {
        echo ${Time}: [WaitForCombat] Combat started
    }
    else
    {
        echo ${Time}: [WaitForCombat] WARNING: Timeout waiting for combat
    }
}

function Cmd_WaitWhileCombat()
{
    echo ${Time}: [WaitWhileCombat] Waiting for combat to end

    while ${Me.InCombat}
    {
        wait 10
    }

    echo ${Time}: [WaitWhileCombat] Combat ended
    wait 20
}

function Cmd_WaitForActor(string params)
{
    ; Parameters: actorName,timeout
    variable string actorName = "${params.Token[1,","]}"
    variable int timeout = 30

    if ${params.Token[2,","](exists)}
        timeout:Set[${params.Token[2,","]}]

    variable int maxWait = ${Math.Calc[${timeout}*10]}
    variable int counter = 0

    echo ${Time}: [WaitForActor] Waiting for: ${actorName}

    while !${Actor["${actorName}"](exists)} && ${counter} < ${maxWait}
    {
        wait 10
        counter:Inc[1]
    }

    if ${Actor["${actorName}"](exists)}
    {
        echo ${Time}: [WaitForActor] Found: ${actorName}
    }
    else
    {
        echo ${Time}: [WaitForActor] WARNING: Timeout waiting for ${actorName}
    }
}

function Cmd_ConfirmZone(string expectedZone)
{
    variable string currentZone = "${Zone.Name}"

    ; Clean zone name (remove parentheses content)
    if ${currentZone.Find["("]}
    {
        currentZone:Set["${currentZone.Left[${Math.Calc[${currentZone.Find["("]}]}]}"]
        currentZone:Set["${currentZone.Trim}"]
    }

    if !${currentZone.Find["${expectedZone}"]}
    {
        echo ${Time}: ================================================
        echo ${Time}: ZONE MISMATCH ERROR
        echo ${Time}: Expected: ${expectedZone}
        echo ${Time}: Actual: ${currentZone}
        echo ${Time}: ================================================
    }
    else
    {
        echo ${Time}: [ConfirmZone] Verified: ${currentZone}
    }
}

/*
 * =====================================================
 * HELPER FUNCTIONS
 * =====================================================
 */

function move_to_actor(int ActorID, float minDistance=7.0)
{
    variable uint StartTime
    variable float lastDistance = 999.0
    variable int stuckCount = 0
    variable int loopCount = 0
    variable int maxLoops = 30

    ; Check if actor exists
    if !${Actor[Query, ID == ${ActorID}](exists)}
    {
        echo ${Time}: [MoveToActor] ERROR: Actor ID ${ActorID} does not exist
        return FALSE
    }

    ; Check distance - if already close enough, don't move
    variable float currentDist = ${Actor[Query, ID == ${ActorID}].Distance2D}
    if ${currentDist} <= ${minDistance}
    {
        echo ${Time}: [MoveToActor] Already at actor (${currentDist}m <= ${minDistance}m) - skipping movement
        return TRUE
    }

    echo ${Time}: [MoveToActor] Moving to actor ID ${ActorID} (distance: ${currentDist}m, threshold: ${minDistance}m)

    oc !ci -Resume igw:${Me.Name}
    oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_movetoarea true
    oc !ci -campspot igw:${Me.Name}
    wait 5
    oc !ci -campspot igw:${Me.Name} 3

    StartTime:Set[${System.TickCount}]
    variable uint maxTime = 60000

    while ${Actor[Query, ID == ${ActorID}].Distance2D} > ${minDistance} && ${loopCount} < ${maxLoops}
    {
        currentDist:Set[${Actor[Query, ID == ${ActorID}].Distance2D}]

        ; Timeout check (60 seconds max)
        if (${System.TickCount} - ${StartTime}) > ${maxTime}
        {
            echo ${Time}: [MoveToActor] TIMEOUT after 60 seconds - stopping movement
            oc !ci -CS_ClearCampSpot igw:${Me.Name}
            return FALSE
        }

        ; Stuck detection - if distance hasn't improved in 3 loops, bail out
        if ${Math.Calc[${lastDistance} - ${currentDist}]} < 0.5
        {
            stuckCount:Inc
            if ${stuckCount} >= 3
            {
                echo ${Time}: [MoveToActor] STUCK DETECTED - distance not improving (${currentDist}m) - ABORTING
                oc !ci -CS_ClearCampSpot igw:${Me.Name}
                return FALSE
            }
        }
        else
        {
            stuckCount:Set[0]
        }

        ; Emergency: if we're close enough (within 10m), accept it
        if ${currentDist} <= 10
        {
            echo ${Time}: [MoveToActor] Close enough (${currentDist}m) - accepting position
            oc !ci -CS_ClearCampSpot igw:${Me.Name}
            return TRUE
        }

        lastDistance:Set[${currentDist}]
        loopCount:Inc

        oc !ci -ChangeCampSpotWho igw:${Me.Name} ${Actor[Query, ID == ${ActorID}].Loc.XYZ[" "]}
        wait 10
    }

    ; Check if we hit max loops
    if ${loopCount} >= ${maxLoops}
    {
        echo ${Time}: [MoveToActor] Max loops (${maxLoops}) reached - stopping
        oc !ci -CS_ClearCampSpot igw:${Me.Name}
        return FALSE
    }

    StartTime:Set[${System.TickCount}]
    while ${Me.IsMoving} && ((${System.TickCount} - ${StartTime}) < 5000)
        wait 10
    wait 10

    oc !ci -CS_ClearCampSpot igw:${Me.Name}

    currentDist:Set[${Actor[Query, ID == ${ActorID}].Distance2D}]
    echo ${Time}: [MoveToActor] Movement complete (final distance: ${currentDist}m)

    return TRUE
}

/*
 * =====================================================
 * QUEST STEP TRACKING (QuestJournalWindow API)
 * =====================================================
 */

; Get current step info for a quest using QuestJournalWindow API
; Returns: collection with StepText, Completed, Total, StepIndex
function:collection GetQuestStepInfo(string questName)
{
    variable collection stepInfo
    variable collection Details
    variable iterator DetailsIterator
    variable int DetailsCounter = 0
    variable string sText
    variable int iCompleted
    variable int iTotal

    ; Initialize with defaults
    stepInfo:Set["Found", FALSE]
    stepInfo:Set["StepText", ""]
    stepInfo:Set["Completed", 0]
    stepInfo:Set["Total", 0]
    stepInfo:Set["StepIndex", 0]

    ; Check if quest exists
    if !${QuestJournalWindow.ActiveQuest["${questName}"](exists)}
    {
        echo ${Time}: [QuestStepInfo] Quest '${questName}' not found in active quests
        return ${stepInfo}
    }

    ; Select the quest in the journal
    QuestJournalWindow.ActiveQuest["${questName}"]:Click
    wait 5

    ; Get quest details (steps)
    QuestJournalWindow.CurrentQuest:GetDetails[Details]
    Details:GetIterator[DetailsIterator]

    if ${DetailsIterator:First(exists)}
    {
        do
        {
            ; Get step text
            sText:Set["${DetailsIterator.Value.Get[LocalText].GetProperty["LocalText"]}"]

            ; Parse completed/total counts if present (e.g., "5/10 wolves killed")
            iCompleted:Set[0]
            iTotal:Set[0]

            ; Check if text contains "X/Y" pattern
            if ${sText.Find["/"]} > 0
            {
                variable string countStr = "${sText.Left[${sText.Find["/"]}]}"
                variable string totalStr = "${sText.Mid[${Math.Calc[${sText.Find["/"]}+1]},10]}"

                ; Extract numbers
                variable int i
                for (i:Set[${countStr.Length}]; ${i} > 0; i:Dec)
                {
                    if ${countStr.Mid[${i},1].IsDigit}
                    {
                        iCompleted:Set[${countStr.Right[-${Math.Calc[${i}-1]}]}]
                        break
                    }
                }

                for (i:Set[1]; ${i} <= ${totalStr.Length}; i:Inc)
                {
                    if ${totalStr.Mid[${i},1].IsDigit}
                    {
                        ; Get all consecutive digits
                        variable int j = ${i}
                        while ${j} <= ${totalStr.Length} && ${totalStr.Mid[${j},1].IsDigit}
                        {
                            j:Inc
                        }
                        iTotal:Set[${totalStr.Mid[${i},${Math.Calc[${j}-${i}]}]}]
                        break
                    }
                }
            }

            ; Store the first (current) step
            if ${DetailsCounter} == 0
            {
                stepInfo:Set["Found", TRUE]
                stepInfo:Set["StepText", "${sText}"]
                stepInfo:Set["Completed", ${iCompleted}]
                stepInfo:Set["Total", ${iTotal}]
                stepInfo:Set["StepIndex", ${DetailsCounter}]
                return ${stepInfo}
            }

            DetailsCounter:Inc
        }
        while ${DetailsIterator:Next(exists)}
    }

    return ${stepInfo}
}

; Check if quest step changed (more accurate than checking quest existence)
function:bool QuestStepChanged(string questName, string previousStepText)
{
    variable collection currentStep
    currentStep:Set[${GetQuestStepInfo["${questName}"]}]

    ; Quest not found = completed or failed
    if !${currentStep.Element["Found"]}
    {
        echo ${Time}: [QuestStepChanged] Quest '${questName}' no longer active
        return TRUE
    }

    ; Step text changed = step completed
    if !${currentStep.Element["StepText"].Equal["${previousStepText}"]}
    {
        echo ${Time}: [QuestStepChanged] Step changed from '${previousStepText}' to '${currentStep.Element["StepText"]}'
        return TRUE
    }

    ; If we have counts, check if objective complete (completed == total)
    if ${currentStep.Element["Total"]} > 0 && ${currentStep.Element["Completed"]} >= ${currentStep.Element["Total"]}
    {
        echo ${Time}: [QuestStepChanged] Objective complete (${currentStep.Element["Completed"]}/${currentStep.Element["Total"]})
        return TRUE
    }

    return FALSE
}

/*
 * =====================================================
 * CRAFTING FUNCTIONS (OgreCraft Integration)
 * =====================================================
 */

function Cmd_Craft_AddRecipe(string params)
{
    ; Parameters: quantity,recipeName
    variable int quantity = 1
    variable string recipeName = ""

    if ${params.Token[1,","](exists)}
        quantity:Set[${params.Token[1,","]}]
    if ${params.Token[2,","](exists)}
        recipeName:Set["${params.Token[2,","]}"]

    echo ${Time}: [Craft] Adding recipe: ${recipeName} x${quantity}
    OgreCraft:AddRecipeNameForWho["igw:${Me.Name}",${quantity},"${recipeName}"]
    wait 5
}

function Cmd_Craft_Start()
{
    echo ${Time}: [Craft] Starting craft queue
    OgreCraft:Start["igw:${Me.Name}"]
    wait 10
}

function Cmd_Craft_ScribeRecipe(string recipeName)
{
    echo ${Time}: [Craft] Scribing recipe: ${recipeName}
    OgreCraft:ScribeRecipe["igw:${Me.Name}","${recipeName}"]
    wait 10
}

function Cmd_Craft_AddLastScribed(string quantity="1")
{
    variable int qty = ${quantity}
    echo ${Time}: [Craft] Adding last scribed recipe x${qty}
    OgreCraft:AddLastScribedRecipe["igw:${Me.Name}",${qty}]
    wait 5
}

function Cmd_Craft_Wait()
{
    echo ${Time}: [Craft] Waiting for craft completion
    ; Wait while crafting window is open
    ; This could check OgreCraft status when that API is available
    wait 50
}

/*
 * =====================================================
 * QUEST FUNCTIONS (OgreBotAPI Integration)
 * =====================================================
 */

function Cmd_AcceptQuest(string questName="")
{
    echo ${Time}: [Quest] Accepting quest: ${questName}
    OgreBotAPI:AcceptQuest["igw:${Me.Name}","${questName}"]
    wait 10
}

/*
 * =====================================================
 * FACTION CHECKING
 * =====================================================
 * Usage: Check if you have reached a certain faction level
 * Example: if ${Get_Faction["Riliss","Get_Value"]} >= 40000
 */

function:string Get_Faction(string factionName, string objectType="Get_Value")
{
    ; Returns faction value or status
    ; objectType can be "Get_Value" (numeric) or "Get_SpewStat" (string status)

    if ${objectType.Equal["Get_Value"]}
    {
        ; Return numeric faction value
        if ${Me.Faction["${factionName}"](exists)}
            return ${Me.Faction["${factionName}"].Value}
        else
            return 0
    }
    elseif ${objectType.Equal["Get_SpewStat"]}
    {
        ; Return faction status string (e.g., "Amiably", "Warmly", etc.)
        if ${Me.Faction["${factionName}"](exists)}
            return ${Me.Faction["${factionName}"].Standing}
        else
            return "Unknown"
    }

    return "0"
}

/*
 * =====================================================
 * QUEST LOOPING WITH FACTION GOAL
 * =====================================================
 * Usage: Repeat a quest until reaching a faction threshold
 *
 * Example Call:
 *   call Cmd_RepeatQuestUntilFaction "Gathering Silk,Riliss,40000"
 *
 * This will:
 * 1. Accept quest "Gathering Silk"
 * 2. Wait for quest completion
 * 3. Check faction with "Riliss"
 * 4. Repeat until Riliss faction >= 40000
 */

function Cmd_RepeatQuestUntilFaction(string params)
{
    ; Parameters: questName,factionName,targetFactionValue
    variable string questName = "${params.Token[1,","]}"
    variable string factionName = "${params.Token[2,","]}"
    variable int targetFaction = 0
    variable int currentFaction = 0
    variable int loopCount = 0

    if ${params.Token[3,","](exists)}
        targetFaction:Set[${params.Token[3,","]}]

    echo ${Time}: [QuestLoop] Starting quest loop: ${questName}
    echo ${Time}: [QuestLoop] Faction goal: ${factionName} >= ${targetFaction}

    ; Check current faction
    if ${Me.Faction["${factionName}"](exists)}
        currentFaction:Set[${Me.Faction["${factionName}"].Value}]

    echo ${Time}: [QuestLoop] Current ${factionName} faction: ${currentFaction}

    while ${currentFaction} < ${targetFaction}
    {
        loopCount:Inc
        echo ${Time}: [QuestLoop] Loop #${loopCount} - Current faction: ${currentFaction}/${targetFaction}

        ; Accept the quest
        echo ${Time}: [QuestLoop] Accepting quest: ${questName}
        OgreBotAPI:AcceptQuest["igw:${Me.Name}","${questName}"]
        wait 20

        ; Wait for quest to complete (check quest journal)
        variable int questTimeout = 0
        variable bool questFound = FALSE

        while ${questTimeout} < 600
        {
            ; Check if quest exists in journal
            if ${Me.Quest["${questName}"](exists)}
            {
                questFound:Set[TRUE]
                wait 10
                questTimeout:Inc[1]
            }
            else
            {
                ; Quest no longer in journal, likely completed
                if ${questFound}
                {
                    echo ${Time}: [QuestLoop] Quest completed
                    break
                }
            }

            ; Safety: break if quest never appeared after 60 seconds
            if !${questFound} && ${questTimeout} >= 60
            {
                echo ${Time}: [QuestLoop] WARNING: Quest not found in journal
                break
            }

            wait 10
            questTimeout:Inc[1]
        }

        ; Update faction value
        wait 20
        if ${Me.Faction["${factionName}"](exists)}
            currentFaction:Set[${Me.Faction["${factionName}"].Value}]

        echo ${Time}: [QuestLoop] Updated faction: ${currentFaction}

        ; Safety check: if no faction gain after 10 loops, something is wrong
        if ${loopCount} >= 10
        {
            variable int initialFaction = ${Math.Calc[${targetFaction} - (${loopCount} * 100)]}
            if ${currentFaction} <= ${initialFaction}
            {
                echo ${Time}: [QuestLoop] ERROR: No faction gain detected after ${loopCount} loops
                echo ${Time}: [QuestLoop] Stopping to prevent infinite loop
                return
            }
        }
    }

    echo ${Time}: [QuestLoop] Faction goal reached! ${factionName}: ${currentFaction}/${targetFaction}
    echo ${Time}: [QuestLoop] Total loops: ${loopCount}
}

function Cmd_Overseer_CheckQuests()
{
    echo ${Time}: [Overseer] Checking overseer quests
    OgreBotAPI:Overseer_CheckQuests["igw:${Me.Name}"]
    wait 10
}

function Cmd_Overseer_AutoAdd()
{
    echo ${Time}: [Overseer] Auto-adding overseer quests
    OgreBotAPI:Overseer_AutoAddOverseerQuests["igw:${Me.Name}"]
    wait 10
}

function Cmd_ShowWikiForQuest(string questName)
{
    echo ${Time}: [Quest] Opening wiki for: ${questName}
    OgreBotAPI:ShowWikiForQuest["is1","${questName}"]
}

/*
 * =====================================================
 * ADDITIONAL UTILITY FUNCTIONS
 * =====================================================
 */

function Cmd_FastTravel(string destination)
{
    echo ${Time}: [FastTravel] Fast traveling to: ${destination}
    ; FastTravel uses bells, druid rings, spires, etc. automatically
    OgreBotAPI:FastTravel["igw:${Me.Name}","${destination}"]
    wait 20
    call Cmd_WaitForZoned
}

function Cmd_ResetActorsLooted()
{
    echo ${Time}: [Loot] Resetting looted actors list
    OgreBotAPI:ResetActorsLooted["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * DIALOG/CONVERSATION COMMANDS
 * =====================================================
 */

/*
 * =====================================================
 * REPLY DIALOG WITH OPTIONAL MULTIPLE SELECTIONS
 * =====================================================
 * Usage: Select one or more reply dialog options in sequence
 *
 * Single option:
 *   call Cmd_ReplyDialog "1"
 *
 * Multiple options in sequence:
 *   call Cmd_ReplyDialog "1,2,3"
 *   (Clicks reply dialog 1, then 2, then 3)
 *
 * Repeat options:
 *   call Cmd_ReplyDialog "1,3,1"
 *   (Clicks reply dialog 1, then 3, then 1 again)
 */

function Cmd_ReplyDialog(string params)
{
    ; Parameters: option1,option2,option3,...
    ; Each option is a reply dialog number to select in sequence
    variable int optionNum
    variable int tokenCount = 1
    variable int selectCount = 0

    echo ${Time}: [ReplyDialog] Processing reply dialog selections

    ; Process each reply dialog option in sequence
    while ${params.Token[${tokenCount},","](exists)}
    {
        optionNum:Set[${params.Token[${tokenCount},","]}]
        echo ${Time}: [ReplyDialog] Selecting reply dialog option ${optionNum}
        OgreBotAPI:ReplyDialog["igw:${Me.Name}","${optionNum}"]
        wait 15
        tokenCount:Inc
        selectCount:Inc
    }

    echo ${Time}: [ReplyDialog] Completed ${selectCount} reply dialog selections
}

; Legacy function name for backwards compatibility
function Cmd_ReplyDialogSequence(string params)
{
    call Cmd_ReplyDialog "${params}"
}

function Cmd_ReplyDialogClose()
{
    echo ${Time}: [Dialog] Closing reply dialog
    OgreBotAPI:ReplyDialogClose["igw:${Me.Name}"]
    wait 5
}

function Cmd_OK_Button()
{
    echo ${Time}: [Dialog] Clicking OK button
    OgreBotAPI:OK_Button["igw:${Me.Name}"]
    wait 5
}

function Cmd_ConversationBubble(string bubbleNum="1")
{
    variable int num = ${bubbleNum}
    echo ${Time}: [Dialog] Selecting conversation bubble: ${num}
    OgreBotAPI:ConversationBubble["igw:${Me.Name}","${num}"]
    wait 10
}

function Cmd_OptNum(string optionNum="1")
{
    variable int num = ${optionNum}
    echo ${Time}: [Dialog] Selecting option number: ${num}
    OgreBotAPI:OptNum["${num}"]
    wait 10
}

function Cmd_InputTextWindow_AddText(string text)
{
    echo ${Time}: [Input] Adding text to input window: ${text}
    OgreBotAPI:InputTextWindow_AddText["igw:${Me.Name}","${text}"]
    wait 5
}

function Cmd_InputTextWindow_ClearText()
{
    echo ${Time}: [Input] Clearing text from input window
    OgreBotAPI:InputTextWindow_ClearText["igw:${Me.Name}"]
    wait 5
}

function Cmd_InputTextWindow_Accept()
{
    echo ${Time}: [Input] Accepting input window
    OgreBotAPI:InputTextWindow_Accept["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * MERCHANT COMMANDS
 * =====================================================
 */

function Cmd_OpenAndBuyFromMerchant(string params)
{
    ; Parameters: merchantName,itemName,quantity
    variable string merchantName = "${params.Token[1,","]}"
    variable string itemName = "${params.Token[2,","]}"
    variable int quantity = 1

    if ${params.Token[3,","](exists)}
        quantity:Set[${params.Token[3,","]}]

    echo ${Time}: [Merchant] Opening and buying from ${merchantName}: ${itemName} x${quantity}
    OgreBotAPI:OpenAndBuyFromMerchant["igw:${Me.Name}","${merchantName}","${itemName}",${quantity}]
    wait 20
}

function Cmd_BuyFromMerchant(string params)
{
    ; Parameters: itemName,quantity
    variable string itemName = "${params.Token[1,","]}"
    variable int quantity = 1

    if ${params.Token[2,","](exists)}
        quantity:Set[${params.Token[2,","]}]

    echo ${Time}: [Merchant] Buying: ${itemName} x${quantity}
    OgreBotAPI:BuyFromMerchant["igw:${Me.Name}","${itemName}",${quantity}]
    wait 10
}

function Cmd_SellToMerchant(string params)
{
    ; Parameters: itemName,quantity
    variable string itemName = "${params.Token[1,","]}"
    variable int quantity = 1

    if ${params.Token[2,","](exists)}
        quantity:Set[${params.Token[2,","]}]

    echo ${Time}: [Merchant] Selling: ${itemName} x${quantity}
    OgreBotAPI:SellToMerchant["igw:${Me.Name}","${itemName}",${quantity}]
    wait 10
}

/*
 * =====================================================
 * ACTOR INTERACTION COMMANDS
 * =====================================================
 */

function Cmd_Actor_Click(string params)
{
    ; Parameters: actorName,exactMatch
    variable string actorName = "${params.Token[1,","]}"
    variable bool exactMatch = FALSE

    if ${params.Token[2,","](exists)}
        exactMatch:Set[${Bool["${params.Token[2,","]}"]}]

    echo ${Time}: [Actor] Clicking actor: ${actorName} (exact: ${exactMatch})
    OgreBotAPI:Actor_Click["igw:${Me.Name}","${actorName}",${exactMatch}]
    wait 10
}

function Cmd_Actor_ClickQueued(string params)
{
    ; Parameters: actorName,exactMatch
    variable string actorName = "${params.Token[1,","]}"
    variable bool exactMatch = FALSE

    if ${params.Token[2,","](exists)}
        exactMatch:Set[${Bool["${params.Token[2,","]}"]}]

    echo ${Time}: [Actor] Clicking actor (queued): ${actorName} (exact: ${exactMatch})
    OgreBotAPI:Actor_ClickQueued["igw:${Me.Name}","${actorName}",${exactMatch}]
    wait 10
}

function Cmd_HailNPC(string actorNameID="0")
{
    echo ${Time}: [Hail] Hailing NPC: ${actorNameID}
    OgreBotAPI:HailNPC["igw:${Me.Name}","${actorNameID}"]
    wait 10
}

function Cmd_FaceActor(string actorNameID="0")
{
    echo ${Time}: [Face] Facing actor: ${actorNameID}
    OgreBotAPI:FaceActor["igw:${Me.Name}","${actorNameID}"]
    wait 5
}

function Cmd_FaceAngle(string angle="0")
{
    variable int angleNum = ${angle}
    echo ${Time}: [Face] Facing angle: ${angleNum}
    OgreBotAPI:FaceAngle["igw:${Me.Name}","${angleNum}"]
    wait 5
}

function Cmd_FaceLoc(string params)
{
    ; Parameters: x,y,z
    ; Example: call Cmd_FaceLoc "833.051270,3.236206,-42.215736"

    echo ${Time}: [Face] Facing location: ${params}
    eq2execute /face_loc ${params}
    wait 5
}

function Cmd_Waypoint(string params)
{
    ; Parameters: x,y,z
    variable float x = ${params.Token[1,","]}
    variable float y = ${params.Token[2,","]}
    variable float z = ${params.Token[3,","]}

    echo ${Time}: [Waypoint] Moving to: ${x},${y},${z}
    OgreBotAPI:Waypoint["igw:${Me.Name}","${x}","${y}","${z}"]
    wait 10
}

/*
 * =====================================================
 * EXAMINE/INVENTORY COMMANDS
 * =====================================================
 */

function Cmd_ExamineInventoryItem(string itemName)
{
    echo ${Time}: [Examine] Examining item: ${itemName}
    OgreBotAPI:ExamineInventoryItem["igw:${Me.Name}","${itemName}"]
    wait 10
}

function Cmd_CloseExamineWindow()
{
    echo ${Time}: [Examine] Closing examine window
    OgreBotAPI:CloseExamineWindow["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT/TARGET COMMANDS
 * =====================================================
 */

function Cmd_CancelDetrimental(string params="0,0")
{
    ; Parameters: mainID,backDropID
    variable int mainID = ${params.Token[1,","]}
    variable int backDropID = 0

    if ${params.Token[2,","](exists)}
        backDropID:Set[${params.Token[2,","]}]

    echo ${Time}: [Combat] Canceling detrimental: ${mainID},${backDropID}
    OgreBotAPI:CancelDetrimental["igw:${Me.Name}",${mainID},${backDropID}]
    wait 5
}

function Cmd_NoTarget()
{
    echo ${Time}: [Target] Clearing target
    OgreBotAPI:NoTarget["igw:${Me.Name}"]
    wait 2
}

function Cmd_PetAttack()
{
    echo ${Time}: [Pet] Pet attack
    OgreBotAPI:PetAttack["igw:${Me.Name}"]
    wait 5
}

function Cmd_PetOff()
{
    echo ${Time}: [Pet] Pet off
    OgreBotAPI:PetOff["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * CURE/BUFF COMMANDS
 * =====================================================
 */

function Cmd_GroupCure()
{
    echo ${Time}: [Cure] Group cure
    OgreBotAPI:GroupCure["igw:${Me.Name}"]
    wait 10
}

function Cmd_AutoCure(string params)
{
    ; Parameters: toonName,...additionalParams
    variable string toonName = "${params.Token[1,","]}"
    echo ${Time}: [Cure] Auto cure: ${toonName}
    ; This would need full param parsing for all options
    OgreBotAPI:AutoCure["igw:${Me.Name}","${toonName}"]
    wait 10
}

function Cmd_AutoGroupCure(string params)
{
    ; Parameters: toonName,...additionalParams
    variable string toonName = "${params.Token[1,","]}"
    echo ${Time}: [Cure] Auto group cure: ${toonName}
    OgreBotAPI:AutoGroupCure["igw:${Me.Name}","${toonName}"]
    wait 10
}

function Cmd_AutoItemCure()
{
    echo ${Time}: [Cure] Auto item cure
    OgreBotAPI:AutoItemCure["igw:${Me.Name}"]
    wait 10
}

/*
 * =====================================================
 * AUTOTARGET COMMANDS
 * =====================================================
 */

function Cmd_AutoTarget_Enable(string key="")
{
    echo ${Time}: [AutoTarget] Enabling autotarget
    OgreBotAPI:AutoTarget_Enable["igw:${Me.Name}","${key}"]
    wait 5
}

function Cmd_AutoTarget_Disable(string key="")
{
    echo ${Time}: [AutoTarget] Disabling autotarget
    OgreBotAPI:AutoTarget_Disable["igw:${Me.Name}","${key}"]
    wait 5
}

function Cmd_AutoTarget_Clear()
{
    echo ${Time}: [AutoTarget] Clearing autotarget
    OgreBotAPI:AutoTarget_Clear["igw:${Me.Name}"]
    wait 5
}

function Cmd_AutoTarget_ClearActors()
{
    echo ${Time}: [AutoTarget] Clearing autotarget actors
    OgreBotAPI:AutoTarget_ClearActors["igw:${Me.Name}"]
    wait 5
}

function Cmd_AutoTarget_AddActor(string params)
{
    ; Parameters: actorName,hp,maxhp,checkCollision,aggroOnGroupOnly,aggroOnNonFighterOnly,aggroOnNotMe
    variable string actorName = "${params.Token[1,","]}"
    variable int hp = 0
    variable int maxhp = 0
    variable bool checkCollision = FALSE
    variable bool aggroOnGroupOnly = TRUE

    if ${params.Token[2,","](exists)}
        hp:Set[${params.Token[2,","]}]
    if ${params.Token[3,","](exists)}
        maxhp:Set[${params.Token[3,","]}]
    if ${params.Token[4,","](exists)}
        checkCollision:Set[${Bool["${params.Token[4,","]}"]}]
    if ${params.Token[5,","](exists)}
        aggroOnGroupOnly:Set[${Bool["${params.Token[5,","]}"]}]

    echo ${Time}: [AutoTarget] Adding actor: ${actorName}
    OgreBotAPI:AutoTarget_AddActor["igw:${Me.Name}","${actorName}",${hp},${maxhp},${checkCollision},${aggroOnGroupOnly}]
    wait 5
}

function Cmd_AutoTarget_SetScanRadius(string radius="50")
{
    variable int rad = ${radius}
    echo ${Time}: [AutoTarget] Setting scan radius: ${rad}
    OgreBotAPI:AutoTarget_SetScanRadius["igw:${Me.Name}",${rad}]
    wait 5
}

function Cmd_AutoTarget_SetScanHeight(string height="5")
{
    variable int h = ${height}
    echo ${Time}: [AutoTarget] Setting scan height: ${h}
    OgreBotAPI:AutoTarget_SetScanHeight["igw:${Me.Name}",${h}]
    wait 5
}

function Cmd_AutoTarget_SetRescanTime(string time="50")
{
    variable int t = ${time}
    echo ${Time}: [AutoTarget] Setting rescan time: ${t}
    OgreBotAPI:AutoTarget_SetRescanTime["igw:${Me.Name}",${t}]
    wait 5
}

/*
 * =====================================================
 * TEXT-TO-SPEECH (TTS) COMMAND
 * =====================================================
 */

function Cmd_TTS(string message)
{
    echo ${Time}: [TTS] Speaking: ${message}
    OgreBotAPI:TTS["igw:${Me.Name}","${message}"]
    wait 5
}

/*
 * =====================================================
 * UNPACK/CONTAINER COMMANDS
 * =====================================================
 */

function Cmd_Unpack(string params)
{
    ; Parameters: itemName,unpackOption
    variable string itemName = "${params.Token[1,","]}"
    variable string unpackOption = ""

    if ${params.Token[2,","](exists)}
        unpackOption:Set["${params.Token[2,","]}"]

    echo ${Time}: [Unpack] Unpacking: ${itemName}
    OgreBotAPI:Unpack["igw:${Me.Name}","${itemName}","${unpackOption}"]
    wait 10
}

function Cmd_Unpack_Quantity(string params)
{
    ; Parameters: itemName,quantity,unpackOption
    variable string itemName = "${params.Token[1,","]}"
    variable int quantity = 1
    variable string unpackOption = ""

    if ${params.Token[2,","](exists)}
        quantity:Set[${params.Token[2,","]}]
    if ${params.Token[3,","](exists)}
        unpackOption:Set["${params.Token[3,","]}"]

    echo ${Time}: [Unpack] Unpacking ${quantity}x ${itemName}
    OgreBotAPI:Unpack_Quantity["igw:${Me.Name}","${itemName}",${quantity},"${unpackOption}"]
    wait 10
}

/*
 * =====================================================
 * CAMPSPOT POSITIONING COMMANDS
 * =====================================================
 */

function Cmd_SetCS_BehindNPC(string params)
{
    ; Parameters: nameOrID,distance,skipIfAggro
    variable string nameOrID = "${params.Token[1,","]}"
    variable float distance = 3
    variable bool skipIfAggro = FALSE

    if ${params.Token[2,","](exists)}
        distance:Set[${params.Token[2,","]}]
    if ${params.Token[3,","](exists)}
        skipIfAggro:Set[${Bool["${params.Token[3,","]}"]}]

    echo ${Time}: [CampSpot] Setting behind NPC: ${nameOrID} at ${distance}m
    OgreBotAPI:SetCS_BehindNPC["igw:${Me.Name}","${nameOrID}",${distance},${skipIfAggro}]
    wait 10
}

function Cmd_SetCS_PositionNPC(string params)
{
    ; Parameters: nameOrID,distance,skipIfAggro
    variable string nameOrID = "${params.Token[1,","]}"
    variable float distance = 3
    variable bool skipIfAggro = FALSE

    if ${params.Token[2,","](exists)}
        distance:Set[${params.Token[2,","]}]
    if ${params.Token[3,","](exists)}
        skipIfAggro:Set[${Bool["${params.Token[3,","]}"]}]

    echo ${Time}: [CampSpot] Setting at NPC position: ${nameOrID} at ${distance}m
    OgreBotAPI:SetCS_PositionNPC["igw:${Me.Name}","${nameOrID}",${distance},${skipIfAggro}]
    wait 10
}

/*
 * =====================================================
 * ADVANCED CASTING COMMANDS
 * =====================================================
 */

function Cmd_CastAbilityOnNPC(string params)
{
    ; Parameters: abilityName,mobNameID
    variable string abilityName = "${params.Token[1,","]}"
    variable string mobNameID = "0"

    if ${params.Token[2,","](exists)}
        mobNameID:Set["${params.Token[2,","]}"]

    echo ${Time}: [Cast] Casting ${abilityName} on NPC: ${mobNameID}
    OgreBotAPI:CastAbilityOnNPC["igw:${Me.Name}","${abilityName}","${mobNameID}"]
    wait 10
}

function Cmd_CastAbilityNoChecks(string abilityName)
{
    echo ${Time}: [Cast] Casting (no checks): ${abilityName}
    OgreBotAPI:CastAbilityNoChecks["igw:${Me.Name}","${abilityName}"]
    wait 5
}

function Cmd_CastAbilityOnPlayerNoChecks(string params)
{
    ; Parameters: abilityName,playerName
    variable string abilityName = "${params.Token[1,","]}"
    variable string playerName = "DoesNotExist"

    if ${params.Token[2,","](exists)}
        playerName:Set["${params.Token[2,","]}"]

    echo ${Time}: [Cast] Casting ${abilityName} on ${playerName} (no checks)
    OgreBotAPI:CastAbilityOnPlayerNoChecks["igw:${Me.Name}","${abilityName}","${playerName}"]
    wait 10
}

function Cmd_CastAbilityInSeconds(string params)
{
    ; Parameters: abilityName,seconds
    variable string abilityName = "${params.Token[1,","]}"
    variable float seconds = 1

    if ${params.Token[2,","](exists)}
        seconds:Set[${params.Token[2,","]}]

    echo ${Time}: [Cast] Casting ${abilityName} in ${seconds} seconds
    OgreBotAPI:CastAbilityInSeconds["igw:${Me.Name}","${abilityName}",${seconds}]
    wait 5
}

function Cmd_CastAbilityOnPlayerInSeconds(string params)
{
    ; Parameters: abilityName,playerName,seconds
    variable string abilityName = "${params.Token[1,","]}"
    variable string playerName = "${Me.Name}"
    variable float seconds = 1

    if ${params.Token[2,","](exists)}
        playerName:Set["${params.Token[2,","]}"]
    if ${params.Token[3,","](exists)}
        seconds:Set[${params.Token[3,","]}]

    echo ${Time}: [Cast] Casting ${abilityName} on ${playerName} in ${seconds} seconds
    OgreBotAPI:CastAbilityOnPlayerInSeconds["igw:${Me.Name}","${abilityName}","${playerName}",${seconds}]
    wait 10
}

/*
 * =====================================================
 * MOUNT COMMANDS
 * =====================================================
 */

function Cmd_Force_MountOn()
{
    echo ${Time}: [Mount] Forcing mount on
    OgreBotAPI:Force_MountOn["igw:${Me.Name}"]
    wait 10
}

function Cmd_LandFlyingMount()
{
    echo ${Time}: [Mount] Landing flying mount
    OgreBotAPI:LandFlyingMount["igw:${Me.Name}"]
    wait 10
}

function Cmd_CheckMountTraining(string forceCheck="FALSE")
{
    variable bool force = ${Bool["${forceCheck}"]}
    echo ${Time}: [Mount] Checking mount training
    OgreBotAPI:CheckMountTraining["igw:${Me.Name}",${force}]
    wait 10
}

function Cmd_Summon_Familiar()
{
    echo ${Time}: [Familiar] Summoning familiar
    OgreBotAPI:Summon_Familiar["igw:${Me.Name}"]
    wait 10
}

/*
 * =====================================================
 * OGREBOT CONTROL COMMANDS
 * =====================================================
 */

function Cmd_Pause()
{
    echo ${Time}: [OgreBot] Pausing
    OgreBotAPI:Pause["igw:${Me.Name}"]
    wait 5
}

function Cmd_Resume()
{
    echo ${Time}: [OgreBot] Resuming
    OgreBotAPI:Resume["igw:${Me.Name}"]
    wait 5
}

function Cmd_End_Bot()
{
    echo ${Time}: [OgreBot] Ending bot
    OgreBotAPI:End_Bot["igw:${Me.Name}"]
    wait 10
}

function Cmd_Reload_Bot()
{
    echo ${Time}: [OgreBot] Reloading bot
    OgreBotAPI:Reload_Bot["igw:${Me.Name}"]
    wait 30
}

/*
 * =====================================================
 * LOOT AND AUTO-CONSUME COMMANDS
 * =====================================================
 */

function Cmd_SetAutoLootMode(string mode="0")
{
    variable int lootMode = ${mode}
    echo ${Time}: [Loot] Setting auto-loot mode: ${lootMode}
    OgreBotAPI:SetAutoLootMode["igw:${Me.Name}","${lootMode}"]
    wait 5
}

function Cmd_SmartLoot_ReloadDataFromFile()
{
    echo ${Time}: [Loot] Reloading SmartLoot data from file
    OgreBotAPI:SmartLoot_ReloadDataFromFile["igw:${Me.Name}"]
    wait 10
}

function Cmd_AutoConsumeTemporaryFamiliarExperience()
{
    echo ${Time}: [Consumable] Auto-consuming temporary familiar experience
    OgreBotAPI:AutoConsumeTemporaryFamiliarExperience["igw:${Me.Name}"]
    wait 5
}

function Cmd_AutoConsumeTemporaryMountTrainingReduction()
{
    echo ${Time}: [Consumable] Auto-consuming temporary mount training reduction
    OgreBotAPI:AutoConsumeTemporaryMountTrainingReduction["igw:${Me.Name}"]
    wait 5
}

function Cmd_AutoConsumeTemporaryResearchReduction()
{
    echo ${Time}: [Consumable] Auto-consuming temporary research reduction
    OgreBotAPI:AutoConsumeTemporaryResearchReduction["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * GROUP/BUFF UTILITY COMMANDS
 * =====================================================
 */

function Cmd_CastGroupWaterBreathing()
{
    echo ${Time}: [Group] Casting group water breathing
    OgreBotAPI:CastGroupWaterBreathing["igw:${Me.Name}"]
    wait 10
}

function Cmd_CancelGroupWaterBreathing()
{
    echo ${Time}: [Group] Canceling group water breathing
    OgreBotAPI:CancelGroupWaterBreathing["igw:${Me.Name}"]
    wait 5
}

function Cmd_ApplyTempAdorn(string params="auto,both")
{
    ; Parameters: adornName,slot
    variable string adornName = "auto"
    variable string slot = "both"

    if ${params.Token[1,","](exists)}
        adornName:Set["${params.Token[1,","]}"]
    if ${params.Token[2,","](exists)}
        slot:Set["${params.Token[2,","]}"]

    echo ${Time}: [Adorn] Applying temp adorn: ${adornName} to ${slot}
    OgreBotAPI:ApplyTempAdorn["igw:${Me.Name}","${adornName}","${slot}"]
    wait 10
}

function Cmd_ResolveBuffCheck()
{
    echo ${Time}: [Buff] Resolving buff check
    OgreBotAPI:ResolveBuffCheck["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * GROUP/RAID INVITE COMMANDS
 * =====================================================
 */

function Cmd_Invite(string params)
{
    ; Parameters: inviteWho,raidInvite
    variable string inviteWho = "${Me.Name}"
    variable bool raidInvite = FALSE

    if ${params.Token[1,","](exists)}
        inviteWho:Set["${params.Token[1,","]}"]
    if ${params.Token[2,","](exists)}
        raidInvite:Set[${Bool["${params.Token[2,","]}"]}]

    echo ${Time}: [Group] Inviting ${inviteWho} (raid: ${raidInvite})
    OgreBotAPI:Invite["igw:${Me.Name}","${inviteWho}",${raidInvite}]
    wait 10
}

/*
 * =====================================================
 * DISPEL/DEBUFF COMMANDS
 * =====================================================
 */

function Cmd_DispellNPCWithSpell(string spellName)
{
    echo ${Time}: [Dispel] Dispelling NPC with: ${spellName}
    OgreBotAPI:DispellNPCWithSpell["igw:${Me.Name}","${spellName}"]
    wait 10
}

/*
 * =====================================================
 * DETRIMENTAL INFO CHECKING (For Raid Mechanics)
 * =====================================================
 * Use this to check debuff stacks on mobs for mechanics
 * Example: Check Lavatar stacks, move when stacks high/low
 */

function:int Get_DetrimentalStacks(int mainID, int backDropID, int64 actorID)
{
    ; Returns current increment count of detrimental on actor
    variable int stacks = 0
    stacks:Set[${OgreBotAPI.DetrimentalInfo[${mainID},${backDropID},${actorID},"CurrentIncrements"]}]
    return ${stacks}
}

function Cmd_CheckDetrimentalStacks(string params)
{
    ; Parameters: actorName,mainID,backDropID,highStacks,lowStacks
    ; Example usage for raid mechanics where you track debuff stacks
    variable string actorName = "${params.Token[1,","]}"
    variable int mainID = ${params.Token[2,","]}
    variable int backDropID = ${params.Token[3,","]}
    variable int highStacks = ${params.Token[4,","]}
    variable int lowStacks = ${params.Token[5,","]}

    if !${Actor["${actorName}"].ID(exists)}
    {
        echo ${Time}: [Detrimental] Actor not found: ${actorName}
        return
    }

    variable int64 actorID = ${Actor["${actorName}"].ID}
    variable int currentStacks
    currentStacks:Set[${OgreBotAPI.DetrimentalInfo[${mainID},${backDropID},${actorID},"CurrentIncrements"]}]

    echo ${Time}: [Detrimental] ${actorName} has ${currentStacks} stacks (High: ${highStacks}, Low: ${lowStacks})
}

/*
 * =====================================================
 * DIRECT AUTOTARGET OBJECT ACCESS (For Complex Mechanics)
 * =====================================================
 * These use Ob_AutoTarget object directly for immediate control
 */

function Cmd_Ob_AutoTarget_Clear()
{
    echo ${Time}: [Ob_AutoTarget] Clearing all targets
    Ob_AutoTarget:Clear
    wait 5
}

function Cmd_Ob_AutoTarget_AddActor(string params)
{
    ; Parameters: actorName,priority,checkCollision,aggroOnGroupOnly
    variable string actorName = "${params.Token[1,","]}"
    variable int priority = 0
    variable bool checkCollision = FALSE
    variable bool aggroOnGroupOnly = FALSE

    if ${params.Token[2,","](exists)}
        priority:Set[${params.Token[2,","]}]
    if ${params.Token[3,","](exists)}
        checkCollision:Set[${Bool["${params.Token[3,","]}"]}]
    if ${params.Token[4,","](exists)}
        aggroOnGroupOnly:Set[${Bool["${params.Token[4,","]}"]}]

    echo ${Time}: [Ob_AutoTarget] Adding actor: ${actorName} (priority: ${priority})
    Ob_AutoTarget:AddActor["${actorName}",${priority},${checkCollision},${aggroOnGroupOnly}]
    wait 2
}

/*
 * =====================================================
 * CAMPSPOT NPC POSITIONING COMMANDS
 * =====================================================
 */

function Cmd_SetCS_NPC(string params)
{
    ; Parameters: angle,nameOrID,distance,skipIfAggro
    variable int angle = 0
    variable string nameOrID = "0"
    variable float distance = 3
    variable bool skipIfAggro = FALSE

    if ${params.Token[1,","](exists)}
        angle:Set[${params.Token[1,","]}]
    if ${params.Token[2,","](exists)}
        nameOrID:Set["${params.Token[2,","]}"]
    if ${params.Token[3,","](exists)}
        distance:Set[${params.Token[3,","]}]
    if ${params.Token[4,","](exists)}
        skipIfAggro:Set[${Bool["${params.Token[4,","]}"]}]

    echo ${Time}: [CampSpot] Setting at NPC ${nameOrID} at ${angle} degrees, ${distance}m
    OgreBotAPI:SetCS_NPC["igw:${Me.Name}",${angle},"${nameOrID}",${distance},${skipIfAggro}]
    wait 10
}

/*
 * =====================================================
 * SCRIPT CONTROL COMMANDS
 * =====================================================
 */

function Cmd_EndScript(string scriptName)
{
    ; End a running script by name
    variable string baseName = "${scriptName}"

    ; Get base name if OgreBot exists
    if ${Script[OgreBot](exists)}
        baseName:Set["${OgreBotAPI.Get_ScriptBaseName["${scriptName}"]}"]

    if ${Script["${baseName}"](exists)}
    {
        echo ${Time}: [Script] Ending script: ${baseName}
        Script["${baseName}"]:End
        wait 10
    }
    else
    {
        echo ${Time}: [Script] Script not running: ${baseName}
    }
}

/*
 * =====================================================
 * GUILD HALL / ZONE TRAVEL COMMANDS
 * =====================================================
 */

function Cmd_PortalToGuildHall()
{
    echo ${Time}: [Portal] Portaling to guild hall
    OgreBotAPI:PortalToGuildHall["igw:${Me.Name}"]
    wait 20
    call Cmd_WaitForZoned
}

function Cmd_ChangeZoneTo(string zoneName)
{
    echo ${Time}: [Zone] Changing zone to: ${zoneName}
    OgreBotAPI:ChangeZoneTo["igw:${Me.Name}","${zoneName}"]
    wait 20
}

/*
 * =====================================================
 * ZONE DETECTION HELPER FUNCTIONS
 * =====================================================
 */

function:bool Is_InGuildHallZone()
{
    ; Returns TRUE if in a guild hall zone
    return ${Zone.ShortName.Find["guildhall"]}
}

function:bool Is_InHouseZone()
{
    ; Returns TRUE if in a player house zone
    if ${Zone.ShortName.Find["room_"]}
        return TRUE
    if ${Zone.ShortName.Find["house_"]}
        return TRUE
    return FALSE
}

function:bool Is_InHouseAccessZone()
{
    ; Returns TRUE if in a zone with house access (cities, etc.)
    ; This checks for zones where you can access housing
    if ${Zone.ShortName.Find["qeynos"]}
        return TRUE
    if ${Zone.ShortName.Find["freeport"]}
        return TRUE
    if ${Zone.ShortName.Find["kelethin"]}
        return TRUE
    if ${Zone.ShortName.Find["gorowyn"]}
        return TRUE
    if ${Zone.ShortName.Find["neriak"]}
        return TRUE
    if ${Zone.ShortName.Find["halas"]}
        return TRUE
    return FALSE
}

/*
 * =====================================================
 * VERB APPLICATION COMMANDS
 * =====================================================
 */

function Cmd_ApplyVerbIDQueued(string params)
{
    ; Parameters: actorID,verbName
    variable int64 actorID = 0
    variable string verbName = "all"

    if ${params.Token[1,","](exists)}
        actorID:Set[${params.Token[1,","]}]
    if ${params.Token[2,","](exists)}
        verbName:Set["${params.Token[2,","]}"]

    if ${actorID} > 0 && ${Actor[${actorID}](exists)}
    {
        echo ${Time}: [Verb] Applying verb (queued): ${verbName} to actor ${actorID}
        Actor[${actorID}].Verb["${verbName}"]:ExecuteQueued
        wait 10
    }
    else
    {
        echo ${Time}: [Verb] ERROR: Invalid actor ID: ${actorID}
    }
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - INTERCEPT
 * =====================================================
 */

function Cmd_SetUpFor_Intercept()
{
    echo ${Time}: [Combat] Setting up for intercept
    OgreBotAPI:SetUpFor_Intercept["igw:${Me.Name}"]
    wait 5
}

function Cmd_ResetFor_Intercept()
{
    echo ${Time}: [Combat] Resetting intercept
    OgreBotAPI:ResetFor_Intercept["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - DISPELS
 * =====================================================
 */

function Cmd_SetUpFor_Dispells()
{
    echo ${Time}: [Combat] Setting up for dispels
    OgreBotAPI:SetUpFor_Dispells["igw:${Me.Name}"]
    wait 5
}

function Cmd_ResetFor_Dispells()
{
    echo ${Time}: [Combat] Resetting dispels
    OgreBotAPI:ResetFor_Dispells["igw:${Me.Name}"]
    wait 5
}

function Cmd_Enable_Dispells()
{
    echo ${Time}: [Combat] Enabling dispels
    OgreBotAPI:Enable_Dispells["igw:${Me.Name}"]
    wait 5
}

function Cmd_Disable_Dispells()
{
    echo ${Time}: [Combat] Disabling dispels
    OgreBotAPI:Disable_Dispells["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - CURES
 * =====================================================
 */

function Cmd_Enable_Cures()
{
    echo ${Time}: [Combat] Enabling cures
    OgreBotAPI:Enable_Cures["igw:${Me.Name}"]
    wait 5
}

function Cmd_Disable_Cures()
{
    echo ${Time}: [Combat] Disabling cures
    OgreBotAPI:Disable_Cures["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - STUNS
 * =====================================================
 */

function Cmd_Enable_Stuns()
{
    echo ${Time}: [Combat] Enabling stuns
    OgreBotAPI:Enable_Stuns["igw:${Me.Name}"]
    wait 5
}

function Cmd_Disable_Stuns()
{
    echo ${Time}: [Combat] Disabling stuns
    OgreBotAPI:Disable_Stuns["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - INTERRUPTS
 * =====================================================
 */

function Cmd_Enable_Interrupts()
{
    echo ${Time}: [Combat] Enabling interrupts
    OgreBotAPI:Enable_Interrupts["igw:${Me.Name}"]
    wait 5
}

function Cmd_Disable_Interrupts()
{
    echo ${Time}: [Combat] Disabling interrupts
    OgreBotAPI:Disable_Interrupts["igw:${Me.Name}"]
    wait 5
}

/*
 * =====================================================
 * COMBAT CONTROL COMMANDS - AOE
 * =====================================================
 */

function Cmd_Set_DisableAllAOEs(string params="TRUE")
{
    ; Parameters: disableAEs
    variable bool disableAEs = TRUE

    if ${params.Token[1,","](exists)}
        disableAEs:Set[${Bool["${params.Token[1,","]}"]}]

    echo ${Time}: [Combat] Setting disable all AOEs: ${disableAEs}
    OgreBotAPI:Set_DisableAllAOEs["igw:${Me.Name}",${disableAEs}]
    wait 5
}

/*
 * =====================================================
 * COMPLEX RAID MECHANIC EXAMPLE FUNCTION
 * =====================================================
 * Example: Lavatar stack management
 * This shows how to combine multiple commands for raid mechanics
 */

function Example_ManageLavatarStacks(string namedNPC, string landSpot, string lavaSpot, int highStacks, int lowStacks)
{
    ; This is an example of complex raid mechanic automation
    ; Checks Lavatar stacks and moves between land/lava spots
    ; mainID: 273, backDropID: 33085 for Fiery Effigy of Clotl'thoa debuff

    echo ${Time}: [Mechanic] Managing Lavatar stacks for ${namedNPC}
    echo ${Time}: [Mechanic] Land spot: ${landSpot}, Lava spot: ${lavaSpot}
    echo ${Time}: [Mechanic] High threshold: ${highStacks}, Low threshold: ${lowStacks}

    variable int currentStacks = 0
    variable int64 actorID

    while ${Actor["${namedNPC}"].ID(exists)}
    {
        actorID:Set[${Actor["${namedNPC}"].ID}]
        currentStacks:Set[${OgreBotAPI.DetrimentalInfo[273,33085,${actorID},"CurrentIncrements"]}]

        if ${currentStacks} >= ${highStacks}
        {
            echo ${Time}: [Mechanic] Stacks at ${currentStacks}. Moving to land.
            oc !ci -ChangeCampSpotWho igw:${Me.Name} ${landSpot}
            wait 50

            ; Clear and set adds as targets
            Ob_AutoTarget:Clear
            wait 5
            Ob_AutoTarget:AddActor["a fanatic Allu'thoa",0,FALSE,FALSE]
            Ob_AutoTarget:AddActor["an Allu'thoa lavacrafter",0,FALSE,FALSE]
            Ob_AutoTarget:AddActor["an Allu'thoa hunter",0,FALSE,FALSE]
            wait 20
        }
        elseif ${currentStacks} <= ${lowStacks}
        {
            echo ${Time}: [Mechanic] Stacks at ${currentStacks}. Moving to lava.
            oc !ci -ChangeCampSpotWho igw:${Me.Name} ${lavaSpot}
            wait 50

            ; Clear and set boss as target
            Ob_AutoTarget:Clear
            wait 5
            Ob_AutoTarget:AddActor["${namedNPC}",0,FALSE,FALSE]
            wait 20
        }

        wait 10
    }

    echo ${Time}: [Mechanic] ${namedNPC} defeated or despawned
}

/*
 * =====================================================
 * SIMPLIFIED QUEST & CRAFTING COMMANDS
 * =====================================================
 * These are simplified versions of complex patterns from old EQ2 systems
 * Designed to make quest/craft automation easier to write and read
 */

/*
 * HailAndAcceptQuest - Combines hail + accept quest
 * OLD: HailActorGetQuest -Actor "Hydona"
 * NEW: call Cmd_HailAndAcceptQuest "Hydona"
 * XML: <Command Type="HailAndAcceptQuest" Value="Hydona" />
 */
function Cmd_HailAndAcceptQuest(string actorName)
{
    echo ${Time}: [HailAndAcceptQuest] Hailing and accepting quest from: ${actorName}

    ; First hail the actor
    variable int actorID = ${Actor["${actorName}"].ID}
    if ${actorID}
    {
        Actor[${actorID}]:DoTarget
        wait 5
        eq2execute /hail
        wait 15

        ; Accept any quest offered
        OgreBotAPI:AcceptQuest["igw:${Me.Name}",""]
        wait 10
    }
    else
    {
        echo ${Time}: [HailAndAcceptQuest] ERROR: Actor '${actorName}' not found
    }
}

/*
 * CraftItem - Simplified crafting command
 * OLD: CraftIt "Preening Oil" 1
 * NEW: call Cmd_CraftItem "Preening Oil,1"
 * XML: <Command Type="CraftItem" Value="Preening Oil,1" />
 *
 * Parameters: recipeName,quantity (quantity optional, defaults to 1)
 */
function Cmd_CraftItem(string params)
{
    variable string recipeName = "${params.Token[1,","]}"
    variable int quantity = 1

    if ${params.Token[2,","](exists)}
        quantity:Set[${params.Token[2,","]}]

    echo ${Time}: [CraftItem] Crafting: ${recipeName} x${quantity}

    ; Add recipe to queue
    OgreCraft:AddRecipeNameForWho["igw:${Me.Name}",${quantity},"${recipeName}"]
    wait 10

    ; Start crafting
    OgreCraft:Start["igw:${Me.Name}"]
    wait 20

    ; Wait for crafting to complete
    ; TODO: Add proper OgreCraft completion check
    wait 100
}

/*
 * ScribeRecipe - Simplified recipe scribing
 * OLD: ScribeBook "Invisibility Potion for Burnish"
 * NEW: call Cmd_ScribeRecipe "Invisibility Potion for Burnish"
 * XML: <Command Type="ScribeRecipe" Value="Invisibility Potion for Burnish" />
 */
function Cmd_ScribeRecipe(string recipeName)
{
    echo ${Time}: [ScribeRecipe] Scribing: ${recipeName}
    OgreCraft:ScribeRecipe["igw:${Me.Name}","${recipeName}"]
    wait 15
}

/*
 * ScribeAndCraft - Scribe a recipe then craft it
 * Useful for quests that require scribing first
 *
 * Example: call Cmd_ScribeAndCraft "Invisibility Potion for Burnish,1"
 * XML: <Command Type="ScribeAndCraft" Value="Invisibility Potion for Burnish,1" />
 */
function Cmd_ScribeAndCraft(string params)
{
    variable string recipeName = "${params.Token[1,","]}"
    variable int quantity = 1

    if ${params.Token[2,","](exists)}
        quantity:Set[${params.Token[2,","]}]

    echo ${Time}: [ScribeAndCraft] Scribing then crafting: ${recipeName} x${quantity}

    ; First scribe the recipe
    call Cmd_ScribeRecipe "${recipeName}"
    wait 10

    ; Then craft it
    call Cmd_CraftItem "${recipeName},${quantity}"
}

/*
 * ClickActor - Click an actor (for quest items, doors, etc)
 * OLD: ClickActor Brine Jar
 * NEW: call Cmd_ClickActor "Brine Jar"
 * XML: <Command Type="ClickActor" Value="Brine Jar" />
 *
 * This is different from DoubleClick - ClickActor targets then right-clicks
 * DoubleClick uses the item/actor directly without targeting
 */
function Cmd_ClickActor(string actorName)
{
    echo ${Time}: [ClickActor] Clicking actor: ${actorName}

    variable int actorID = ${Actor["${actorName}"].ID}
    if ${actorID}
    {
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}]:DoubleClick
        wait 10
    }
    else
    {
        echo ${Time}: [ClickActor] WARNING: Actor '${actorName}' not found
    }
}

/*
 * GatherNode - Harvest/gather from a node (single attempt)
 * Useful for harvesting quests
 *
 * Example: call Cmd_GatherNode "aether roots"
 * XML: <Command Type="GatherNode" Value="aether roots" />
 *
 * NOTE: This only attempts to gather ONCE. For repeated gathering
 * until quest objectives are met, use GatherNodeUntilUpdate instead.
 */
function Cmd_GatherNode(string nodeName)
{
    echo ${Time}: [GatherNode] Gathering from: ${nodeName}

    variable int nodeID = ${Actor["${nodeName}"].ID}
    if ${nodeID}
    {
        Actor[${nodeID}]:DoTarget
        wait 5
        Actor[${nodeID}]:DoubleClick
        wait 30
    }
    else
    {
        echo ${Time}: [GatherNode] WARNING: Node '${nodeName}' not found
    }
}

/*
 * GatherNodeUntilUpdate - Repeatedly gather nodes until quest updates
 * This replicates the old Path -QA behavior
 *
 * Parameters: nodeName,questName,maxAttempts (optional)
 *
 * Example: call Cmd_GatherNodeUntilUpdate "aether roots,Test Your Mettle: Where?,10"
 * XML: <Command Type="GatherNodeUntilUpdate" Value="aether roots,Test Your Mettle: Where?,10" />
 *
 * How it works:
 * 1. Searches for nearest node matching nodeName
 * 2. Clicks the node and waits for harvest
 * 3. Checks if quest still exists (if gone, step completed!)
 * 4. Repeats until quest updates or maxAttempts reached
 */
function Cmd_GatherNodeUntilUpdate(string params)
{
    variable string nodeName = "${params.Token[1,","]}"
    variable string questName = "${params.Token[2,","]}"
    variable int maxAttempts = 10
    variable int gatherCount = 0
    variable int searchRadius = 50
    variable bool stepComplete = FALSE
    variable collection initialStep
    variable collection currentStep

    if ${params.Token[3,","](exists)}
        maxAttempts:Set[${params.Token[3,","]}]

    echo ${Time}: [GatherNodeUntilUpdate] Starting gather loop for: ${nodeName}
    echo ${Time}: [GatherNodeUntilUpdate] Quest: ${questName} (max ${maxAttempts} attempts)

    ; Get initial quest step info
    initialStep:Set[${GetQuestStepInfo["${questName}"]}]

    if !${initialStep.Element["Found"]}
    {
        echo ${Time}: [GatherNodeUntilUpdate] Quest '${questName}' not found in journal
        return
    }

    echo ${Time}: [GatherNodeUntilUpdate] Initial step: ${initialStep.Element["StepText"]}
    if ${initialStep.Element["Total"]} > 0
        echo ${Time}: [GatherNodeUntilUpdate] Progress: ${initialStep.Element["Completed"]}/${initialStep.Element["Total"]}

    while ${gatherCount} < ${maxAttempts} && !${stepComplete}
    {
        gatherCount:Inc

        ; Search for nearest node within radius
        variable int nodeID = ${Actor["${nodeName}"].ID}

        if !${nodeID}
        {
            echo ${Time}: [GatherNodeUntilUpdate] Attempt ${gatherCount}/${maxAttempts}: No '${nodeName}' found nearby
            wait 20
            continue
        }

        echo ${Time}: [GatherNodeUntilUpdate] Attempt ${gatherCount}/${maxAttempts}: Gathering from ${nodeName} (ID: ${nodeID})

        ; Move to and click the node
        Actor[${nodeID}]:DoTarget
        wait 5

        ; Check distance - if too far, move closer
        if ${Math.Distance[${Me.Loc},${Actor[${nodeID}].Loc}]} > 5
        {
            echo ${Time}: [GatherNodeUntilUpdate] Moving closer to node (${Math.Distance[${Me.Loc},${Actor[${nodeID}].Loc}]}m away)
            call move_to_actor ${nodeID}
            wait 10
        }

        ; Click the node
        Actor[${nodeID}]:DoubleClick
        wait 30

        ; Check if quest step changed (more accurate than checking quest existence!)
        if ${QuestStepChanged["${questName}","${initialStep.Element["StepText"]}"]}
        {
            echo ${Time}: [GatherNodeUntilUpdate] Quest step completed!
            stepComplete:Set[TRUE]
            break
        }

        ; Show progress if available
        currentStep:Set[${GetQuestStepInfo["${questName}"]}]
        if ${currentStep.Element["Total"]} > 0
            echo ${Time}: [GatherNodeUntilUpdate] Progress: ${currentStep.Element["Completed"]}/${currentStep.Element["Total"]}

        ; Wait between gather attempts
        wait 10
    }

    if ${gatherCount} >= ${maxAttempts}
    {
        echo ${Time}: [GatherNodeUntilUpdate] Reached max attempts (${maxAttempts}). Check if quest updated.
    }

    echo ${Time}: [GatherNodeUntilUpdate] Finished gathering ${nodeName} (${gatherCount} nodes gathered)
}

/*
 * GatherMultipleNodes - Gather from multiple node types until quest updates
 * Useful for quests that require gathering various resources
 *
 * Parameters: questName,node1;node2;node3,maxAttempts
 *
 * Example: call Cmd_GatherMultipleNodes "Test Your Mettle,aether roots;rough ore;animal den,15"
 * XML: <Command Type="GatherMultipleNodes" Value="Test Your Mettle,aether roots;rough ore;animal den,15" />
 */
function Cmd_GatherMultipleNodes(string params)
{
    variable string questName = "${params.Token[1,","]}"
    variable string nodeList = "${params.Token[2,","]}"
    variable int maxAttempts = 15
    variable int gatherCount = 0
    variable int currentNodeIndex = 1
    variable string currentNode

    if ${params.Token[3,","](exists)}
        maxAttempts:Set[${params.Token[3,","]}]

    echo ${Time}: [GatherMultipleNodes] Quest: ${questName}
    echo ${Time}: [GatherMultipleNodes] Node types: ${nodeList}

    ; Check if quest exists
    if !${Me.Quest["${questName}"](exists)}
    {
        echo ${Time}: [GatherMultipleNodes] Quest '${questName}' not found in journal
        return
    }

    while ${gatherCount} < ${maxAttempts}
    {
        ; Cycle through node types (separated by semicolon)
        currentNode:Set["${nodeList.Token[${currentNodeIndex},";"]}"]

        if !${currentNode.Length}
        {
            ; Reached end of node list, start over
            currentNodeIndex:Set[1]
            currentNode:Set["${nodeList.Token[${currentNodeIndex},";"]}"]
        }

        echo ${Time}: [GatherMultipleNodes] Attempt ${gatherCount}/${maxAttempts}: Looking for ${currentNode}

        ; Search for this node type
        variable int nodeID = ${Actor["${currentNode}"].ID}

        if ${nodeID}
        {
            gatherCount:Inc

            Actor[${nodeID}]:DoTarget
            wait 5

            ; Move closer if needed
            if ${Math.Distance[${Me.Loc},${Actor[${nodeID}].Loc}]} > 5
            {
                call move_to_actor ${nodeID}
                wait 10
            }

            Actor[${nodeID}]:DoubleClick
            wait 30

            ; Check if quest completed
            if !${Me.Quest["${questName}"](exists)}
            {
                echo ${Time}: [GatherMultipleNodes] Quest '${questName}' complete!
                return
            }
        }

        ; Move to next node type
        currentNodeIndex:Inc
        wait 10
    }

    echo ${Time}: [GatherMultipleNodes] Finished gathering (${gatherCount} nodes gathered)
}

/*
 * =====================================================
 * UNTIL UPDATE PATTERN - QUEST OBJECTIVE COMMANDS
 * =====================================================
 * These commands repeat actions until quest objectives are met
 * Pattern: Check quest exists → Perform action → Check if quest still active → Repeat
 */

/*
 * KillUntilUpdate - Kill NPCs repeatedly until quest updates
 *
 * Parameters: actorName,questName,maxKills (optional)
 *
 * Example: call Cmd_KillUntilUpdate "a gnoll scout,Gnoll Slayer,15"
 * XML: <Command Type="KillUntilUpdate" Value="a gnoll scout,Gnoll Slayer,15" />
 *
 * How it works:
 * 1. Uses OgreBot autotarget to find and kill NPCs
 * 2. After each kill, checks if quest still exists
 * 3. If quest disappears from journal, objective complete!
 * 4. Repeats until quest updates or maxKills reached
 */
function Cmd_KillUntilUpdate(string params)
{
    variable string actorName = "${params.Token[1,","]}"
    variable string questName = "${params.Token[2,","]}"
    variable int maxKills = 20
    variable int killCount = 0
    variable bool questStillActive = TRUE

    if ${params.Token[3,","](exists)}
        maxKills:Set[${params.Token[3,","]}]

    echo ${Time}: [KillUntilUpdate] Starting kill loop for: ${actorName}
    echo ${Time}: [KillUntilUpdate] Quest: ${questName} (max ${maxKills} kills)

    ; Check if quest exists initially
    if !${Me.Quest["${questName}"](exists)}
    {
        echo ${Time}: [KillUntilUpdate] Quest '${questName}' not found in journal
        return
    }

    ; Set up autotarget for this mob
    Ob_AutoTarget:Clear
    wait 5
    Ob_AutoTarget:AddActor["${actorName}",0,FALSE,FALSE]
    wait 10

    while ${killCount} < ${maxKills} && ${questStillActive}
    {
        ; Search for the target
        variable int targetID = ${Actor["${actorName}"].ID}

        if !${targetID}
        {
            echo ${Time}: [KillUntilUpdate] Attempt ${killCount}/${maxKills}: No '${actorName}' found nearby
            wait 30
            continue
        }

        echo ${Time}: [KillUntilUpdate] Kill ${killCount}/${maxKills}: Engaging ${actorName} (ID: ${targetID})

        ; Target and attack
        Actor[${targetID}]:DoTarget
        wait 5

        ; Wait for mob to die or timeout (2 minutes max per mob)
        variable int combatTimeout = 0
        while ${Actor[${targetID}](exists)} && ${Actor[${targetID}].Health} > 0 && ${combatTimeout} < 1200
        {
            wait 10
            combatTimeout:Inc[1]
        }

        ; Check if mob died
        if !${Actor[${targetID}](exists)} || ${Actor[${targetID}].Health} <= 0
        {
            killCount:Inc
            echo ${Time}: [KillUntilUpdate] ${actorName} killed (${killCount}/${maxKills})
            wait 20

            ; Check if quest still exists (if quest disappears, objective complete!)
            if !${Me.Quest["${questName}"](exists)}
            {
                echo ${Time}: [KillUntilUpdate] Quest '${questName}' no longer in journal - objective complete!
                questStillActive:Set[FALSE]
                break
            }
        }
        else
        {
            echo ${Time}: [KillUntilUpdate] Combat timeout - moving on
        }

        ; Wait between kills
        wait 15
    }

    if ${killCount} >= ${maxKills}
    {
        echo ${Time}: [KillUntilUpdate] Reached max kills (${maxKills}). Check if quest updated.
    }

    echo ${Time}: [KillUntilUpdate] Finished killing ${actorName} (${killCount} mobs killed)
}

/*
 * ClickActorUntilUpdate - Click actors repeatedly until quest updates
 * Useful for quests requiring multiple clicks on objects
 *
 * Parameters: actorName,questName,maxClicks (optional)
 *
 * Example: call Cmd_ClickActorUntilUpdate "Brine Jar,Despite the challenge,10"
 * XML: <Command Type="ClickActorUntilUpdate" Value="Brine Jar,Despite the challenge,10" />
 */
function Cmd_ClickActorUntilUpdate(string params)
{
    variable string actorName = "${params.Token[1,","]}"
    variable string questName = "${params.Token[2,","]}"
    variable int maxClicks = 10
    variable int clickCount = 0
    variable bool questStillActive = TRUE

    if ${params.Token[3,","](exists)}
        maxClicks:Set[${params.Token[3,","]}]

    echo ${Time}: [ClickActorUntilUpdate] Starting click loop for: ${actorName}
    echo ${Time}: [ClickActorUntilUpdate] Quest: ${questName} (max ${maxClicks} clicks)

    ; Check if quest exists initially
    if !${Me.Quest["${questName}"](exists)}
    {
        echo ${Time}: [ClickActorUntilUpdate] Quest '${questName}' not found in journal
        return
    }

    while ${clickCount} < ${maxClicks} && ${questStillActive}
    {
        ; Search for the actor
        variable int actorID = ${Actor["${actorName}"].ID}

        if !${actorID}
        {
            echo ${Time}: [ClickActorUntilUpdate] Attempt ${clickCount}/${maxClicks}: No '${actorName}' found nearby
            wait 20
            continue
        }

        echo ${Time}: [ClickActorUntilUpdate] Click ${clickCount}/${maxClicks}: Clicking ${actorName} (ID: ${actorID})

        ; Move to actor if too far
        if ${Math.Distance[${Me.Loc},${Actor[${actorID}].Loc}]} > 5
        {
            echo ${Time}: [ClickActorUntilUpdate] Moving closer (${Math.Distance[${Me.Loc},${Actor[${actorID}].Loc}]}m away)
            call move_to_actor ${actorID}
            wait 10
        }

        ; Click the actor
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}]:DoubleClick
        wait 15

        clickCount:Inc

        ; Check if quest still exists
        if !${Me.Quest["${questName}"](exists)}
        {
            echo ${Time}: [ClickActorUntilUpdate] Quest '${questName}' no longer in journal - objective complete!
            questStillActive:Set[FALSE]
            break
        }

        ; Wait between clicks
        wait 10
    }

    if ${clickCount} >= ${maxClicks}
    {
        echo ${Time}: [ClickActorUntilUpdate] Reached max clicks (${maxClicks}). Check if quest updated.
    }

    echo ${Time}: [ClickActorUntilUpdate] Finished clicking ${actorName} (${clickCount} clicks)
}

/*
 * CraftUntilUpdate - Craft items repeatedly until quest updates
 *
 * Parameters: recipeName,questName,maxCrafts (optional)
 *
 * Example: call Cmd_CraftUntilUpdate "Rough Linen Tunic,Crafting Tutorial,10"
 * XML: <Command Type="CraftUntilUpdate" Value="Rough Linen Tunic,Crafting Tutorial,10" />
 *
 * NOTE: This adds items to craft queue and waits for completion
 * Make sure you're at a crafting station!
 */
function Cmd_CraftUntilUpdate(string params)
{
    variable string recipeName = "${params.Token[1,","]}"
    variable string questName = "${params.Token[2,","]}"
    variable int maxCrafts = 10
    variable int craftCount = 0
    variable bool questStillActive = TRUE

    if ${params.Token[3,","](exists)}
        maxCrafts:Set[${params.Token[3,","]}]

    echo ${Time}: [CraftUntilUpdate] Starting craft loop for: ${recipeName}
    echo ${Time}: [CraftUntilUpdate] Quest: ${questName} (max ${maxCrafts} crafts)

    ; Check if quest exists initially
    if !${Me.Quest["${questName}"](exists)}
    {
        echo ${Time}: [CraftUntilUpdate] Quest '${questName}' not found in journal
        return
    }

    while ${craftCount} < ${maxCrafts} && ${questStillActive}
    {
        craftCount:Inc

        echo ${Time}: [CraftUntilUpdate] Craft ${craftCount}/${maxCrafts}: Adding ${recipeName} to queue

        ; Add recipe and start crafting
        OgreCraft:AddRecipeNameForWho["igw:${Me.Name}",1,"${recipeName}"]
        wait 10
        OgreCraft:Start["igw:${Me.Name}"]
        wait 20

        ; Wait for crafting to complete (check OgreCraft status)
        ; TODO: Add proper OgreCraft completion check
        wait 100

        ; Check if quest still exists
        if !${Me.Quest["${questName}"](exists)}
        {
            echo ${Time}: [CraftUntilUpdate] Quest '${questName}' no longer in journal - objective complete!
            questStillActive:Set[FALSE]
            break
        }

        ; Wait between crafts
        wait 10
    }

    if ${craftCount} >= ${maxCrafts}
    {
        echo ${Time}: [CraftUntilUpdate] Reached max crafts (${maxCrafts}). Check if quest updated.
    }

    echo ${Time}: [CraftUntilUpdate] Finished crafting ${recipeName} (${craftCount} items crafted)
}

/*
 * WaitForQuestStep - Wait until a specific quest step completes
 * Useful for quests that auto-complete after collecting items
 *
 * Parameters: questName,stepText
 * stepText is text that appears in the quest step (partial match ok)
 *
 * Example: call Cmd_WaitForQuestStep "Despite the challenge,crates"
 * This waits until the step containing "crates" is completed
 *
 * XML: <Command Type="WaitForQuestStep" Value="Despite the challenge,crates" />
 */
function Cmd_WaitForQuestStep(string params)
{
    variable string questName = "${params.Token[1,","]}"
    variable string stepText = "${params.Token[2,","]}"
    variable int timeout = 0
    variable int maxTimeout = 600

    echo ${Time}: [WaitForQuestStep] Waiting for quest step: ${questName} (${stepText})

    while ${timeout} < ${maxTimeout}
    {
        ; Check if quest still exists (if not, it's complete)
        if !${Me.Quest["${questName}"](exists)}
        {
            echo ${Time}: [WaitForQuestStep] Quest '${questName}' completed or not in journal
            return
        }

        ; TODO: Add proper quest step checking when API is available
        ; For now just wait for quest to disappear from journal

        wait 10
        timeout:Inc[1]
    }

    echo ${Time}: [WaitForQuestStep] Timeout waiting for quest step
}

/*
 * GatherAlongPath - Path through waypoints while gathering nodes
 * This is a simplified version of the old Path -QA command
 *
 * OLD SYNTAX:
 * Path -PL 115 -QA "-A|aether roots|-T|QSC:harvested the root|-E|H"
 *
 * NEW SYNTAX:
 * Just use regular waypoints and add GatherNode commands where needed
 *
 * XML Example:
 * <Waypoint X="100" Y="50" Z="-200" />
 * <Command Type="GatherNode" Value="aether roots" />
 * <Waypoint X="150" Y="55" Z="-250" />
 * <Command Type="GatherNode" Value="rough ore" />
 *
 * This is much cleaner and easier to read than the old -QA flag syntax
 */
