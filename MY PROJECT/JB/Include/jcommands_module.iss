
variable(global) string J_Commands_Version = "2.0.0"

function JCmd_AuthorMessage(string message)
{
    echo ${Time}: ================================================
    echo ${Time}: [AUTHOR] ${message}
    echo ${Time}: ================================================
}

function JCmd_Echo(string message)
{
    oc ${message}
}

function JCmd_Announce(string message)
{
    relay all "echo ${message}"
}

function JCmd_IRC(string message)
{
    relay all "echo [IRC] ${message}"
}

function JCmd_Checkpoint(string message)
{
    echo ${Time}: ================================================
    echo ${Time}: [CHECKPOINT] ${message}
    echo ${Time}: ================================================
    relay all "echo [CHECKPOINT] ${message}"
    wait 10
}

function JCmd_Summon()
{
    eq2execute summon
    wait 5
}

function JCmd_ConfirmZone(string expectedZone)
{
    variable string currentZone = "${Zone.Name}"
    
    ; Clean zone name
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
        echo ${Time}: Please zone into ${expectedZone} before running
        Script:End
    }
    
    echo ${Time}: Zone confirmed: ${currentZone}
}

function JCmd_WaitForZone(string zoneShortName, string timeout="60")
{
    variable int startTime = ${Time.Timestamp}
    variable int maxTime = ${timeout}
    
    echo ${Time}: [WaitForZone] Waiting for: ${zoneShortName}
    
    while (!${Zone.ShortName.Find[${zoneShortName}]} || ${EQ2.Zoning}) && ${Math.Calc[${Time.Timestamp}-${startTime}]} < ${maxTime}
    {
        waitframe
    }
    
    wait 20
    
    if ${Zone.ShortName.Find[${zoneShortName}]}
    {
        echo ${Time}: Zone loaded: ${Zone.ShortName}
    }
    else
    {
        echo ${Time}: Zone timeout - expected ${zoneShortName}, got ${Zone.ShortName}
    }
}

function JCmd_Zone(string who)
{
    oc !ci -Zone ${who}
    wait 50
}

function JCmd_ZoneDoor(string who, string doorNum)
{
    oc !ci -ZoneDoor ${doorNum}
    wait 50
}

function JCmd_Evac(string who)
{
    oc !ci -cfw ${who} -Evac
    wait 30
    while ${EQ2.Zoning}
        waitframe
    wait 20
}

function JCmd_Revive(string who)
{
    oc !ci -Revive ${who}
    wait 100
}

function JCmd_Wait(string seconds)
{
    echo ${Time}: [Wait] ${seconds} seconds...
    wait ${Math.Calc[${seconds}*10]}
}

function JCmd_WaitWhileInCombat()
{
    echo ${Time}: [Wait] Waiting for combat to end...
    
    while ${Me.InCombat}
    {
        wait 10
    }
    
    echo ${Time}: Combat ended
}

function JCmd_WaitForCombat(string timeout="30")
{
    variable int startTime = ${Time.Timestamp}
    
    echo ${Time}: [Wait] Waiting for combat to start...
    
    while !${Me.InCombat} && ${Math.Calc[${Time.Timestamp}-${startTime}]} < ${timeout}
    {
        wait 10
    }
    
    if ${Me.InCombat}
    {
        echo ${Time}: Combat started
    }
    else
    {
        echo ${Time}: Combat timeout
    }
}

function JCmd_WaitForActorExists(string actorName, string timeout="30")
{
    variable int startTime = ${Time.Timestamp}
    
    echo ${Time}: [Wait] Waiting for actor: ${actorName}
    
    while !${Actor["${actorName}"](exists)} && ${Math.Calc[${Time.Timestamp}-${startTime}]} < ${timeout}
    {
        wait 10
    }
    
    if ${Actor["${actorName}"](exists)}
    {
        echo ${Time}: Actor found: ${actorName}
    }
    else
    {
        echo ${Time}: Actor timeout: ${actorName}
    }
}

function JCmd_WaitForActorDead(string actorName, string timeout="300")
{
    variable int startTime = ${Time.Timestamp}
    
    echo ${Time}: [Wait] Waiting for actor death: ${actorName}
    
    while (${Actor["${actorName}"](exists)} && !${Actor["${actorName}"].IsDead}) && ${Math.Calc[${Time.Timestamp}-${startTime}]} < ${timeout}
    {
        wait 10
    }
    
    if !${Actor["${actorName}"](exists)} || ${Actor["${actorName}"].IsDead}
    {
        echo ${Time}: Actor dead: ${actorName}
    }
    else
    {
        echo ${Time}: Actor death timeout: ${actorName}
    }
}

function JCmd_OgreBot_LetsGo(string who)
{
    oc !ci -letsgo ${who}
    wait 5
}

function JCmd_OgreBot_Assist(string assistTarget, string who="all")
{
    oc !ci -Assist ${assistTarget}
    wait 5
}

function JCmd_OgreBot_CS(string who, string mode, string radius)
{
    oc !ci -CS-Dft ${who} ${mode} ${radius}
    wait 5
}

function JCmd_OgreBot_Campspot(string who, string x, string y, string z)
{
    oc !ci -ChangeCampSpotWho ${who} ${x} ${y} ${z}
    wait 5
}

function JCmd_OgreBot_SetCampspot()
{
    oc !ci -campspot igw:${Me.Name}
    oc !ci -ChangeCampSpotWho igw:${Me.Name} ${Me.X} ${Me.Y} ${Me.Z}
    wait 5
}

function JCmd_OgreBot_ClearCampspot(string who="all")
{
    oc !ci -ClearCampSpot ${who}
    wait 5
}

function JCmd_OgreBot_OFol(string target, string followTarget, string followDistance, string maxDistance, string strict)
{
    oc !ci -OgreFollow ${target} ${followTarget} ${followDistance} ${maxDistance} ${strict}
    wait 5
}

function JCmd_OgreBot_ReLd_Bot(string who="all")
{
    oc !ci -ReLd_Bot ${who}
    wait 30
    while !${OgreBotAPI.IsReady}
        waitframe
    wait 150
    echo ${Time}: Bot reloaded
}

function JCmd_OgreBot_UplinkOption(string who, string option, string value)
{
    oc !ci -Uplinkoption_change ${who} ${option} ${value}
    wait 5
}

function JCmd_OgreBot_Pause(string who)
{
    oc !ci -Pause ${who}
    wait 5
}

function JCmd_OgreBot_Resume(string who)
{
    oc !ci -Resume ${who}
    wait 5
}

function JCmd_OgreBot_PetOff(string who)
{
    oc !ci -PetOff ${who}
    wait 10
}

function JCmd_OgreBot_PetAssist(string who)
{
    oc !ci -PetAssist ${who}
    wait 10
}

function JCmd_OgreBot_Attack(string who="all")
{
    oc !ci -Attack ${who}
    wait 5
}

function JCmd_OgreBot_EndCombat(string who="all")
{
    oc !ci -EndCombat ${who}
    wait 5
}

function JCmd_AutoTarget_AddActor(string who, string actorName, string priority="0")
{
    oc !ci -AutoTarget_AddActor ${who} "${actorName}" ${priority} FALSE TRUE
    wait 5
}

function JCmd_AutoTarget_Clear(string who)
{
    oc !ci -cfw ${who} -AutoTarget_ClearActors
    wait 5
}

function JCmd_AutoTarget_Enable(string who)
{
    oc !ci -ChangeOgreBotUIOption ${who} checkbox_autotarget_enabled TRUE TRUE
    wait 5
}

function JCmd_AutoTarget_Disable(string who)
{
    oc !ci -ChangeOgreBotUIOption ${who} checkbox_autotarget_enabled FALSE TRUE
    wait 5
}

function JCmd_AutoTarget_ScanRadius(string who, string radius)
{
    OgreBotAPI:AutoTarget_SetScanRadius[${who},"${radius}"]
    wait 5
}

; ================================================================================
; ABILITY / CASTING COMMANDS
; ================================================================================

function JCmd_CastAbility(string who, string abilityName)
{
    oc !ci -CastAbility ${who} "${abilityName}"
    wait 5
}

function JCmd_CastAbilityNoChecks(string who, string abilityName)
{
    oc !ci -CastAbilityNoChecks ${who} "${abilityName}"
    wait 5
}

function JCmd_CancelCasting(string who)
{
    oc !ci -CancelCasting ${who}
    wait 5
}

function JCmd_AbilityTag(string who, string tagName, string duration, string action)
{
    oc !c -AbilityTag ${who} ${tagName} ${duration} ${action}
    wait 5
}

function JCmd_UseItem(string who, string itemName)
{
    oc !ci -UseItem ${who} "${itemName}"
    wait 10
}

; ================================================================================
; UI COMMANDS
; ================================================================================

function JCmd_ChangeUI(string who, string control, string value)
{
    oc !ci -ChangeOgreBotUIOption ${who} ${control} ${value} TRUE
    wait 5
}

function JCmd_EnableCheckbox(string who, string checkboxName)
{
    variable string fullName
    
    if ${checkboxName.Find["@"]}
    {
        fullName:Set["${checkboxName}"]
    }
    else
    {
        fullName:Set["${checkboxName}@frame_TabColumn1Button1@uiXML"]
    }
    
    relay "${who}" "QB_OgreBotCustomCommand Ogre_Change_UI \"${who}\" \"${fullName}\" SetChecked \"\""
    wait 2
}

function JCmd_DisableCheckbox(string who, string checkboxName)
{
    variable string fullName
    
    if ${checkboxName.Find["@"]}
    {
        fullName:Set["${checkboxName}"]
    }
    else
    {
        fullName:Set["${checkboxName}@frame_TabColumn1Button1@uiXML"]
    }
    
    relay "${who}" "QB_OgreBotCustomCommand Ogre_Change_UI \"${who}\" \"${fullName}\" SetUnchecked \"\""
    wait 2
}

; ================================================================================
; MOVEMENT COMMANDS
; ================================================================================

function JCmd_EnableMoveToArea(string who)
{
    call JCmd_EnableCheckbox "${who}" "checkbox_settings_movetoarea"
}

function JCmd_DisableMoveToArea(string who)
{
    call JCmd_DisableCheckbox "${who}" "checkbox_settings_movetoarea"
}

function JCmd_EnableMoveBehind(string who)
{
    call JCmd_EnableCheckbox "${who}" "checkbox_settings_movebehind"
}

function JCmd_DisableMoveBehind(string who)
{
    call JCmd_DisableCheckbox "${who}" "checkbox_settings_movebehind"
}

function JCmd_JoustOut(string who)
{
    relay "${who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustOut]"
    wait 5
}

function JCmd_JoustIn(string who)
{
    relay "${who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustIn]"
    wait 5
}

; ================================================================================
; INTERACTION COMMANDS
; ================================================================================

function JCmd_Hail(string who, string npcName)
{
    variable int npcID = ${Actor["${npcName}"].ID}
    
    if ${npcID}
    {
        echo ${Time}: [Hail] ${npcName}
        Actor[${npcID}]:DoTarget
        wait 5
        eq2execute /hail
        wait 10
    }
    else
    {
        echo ${Time}:  NPC not found: ${npcName}
    }
}

function JCmd_ApplyVerb(string who, string actorName, string verbName)
{
    variable int actorID = ${Actor["${actorName}"].ID}
    
    if ${actorID}
    {
        echo ${Time}: [ApplyVerb] '${verbName}' → ${actorName}
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}].Verb["${verbName}"]:Execute
        wait 10
    }
    else
    {
        echo ${Time}:  Actor not found: ${actorName}
    }
}

function JCmd_DoubleClick(string actorName)
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
        echo ${Time}:  Actor not found: ${actorName}
    }
}

function JCmd_Special(string who, string actorName="")
{
    if ${actorName.Length}
    {
        oc !c -Special ${who} "${actorName}"
    }
    else
    {
        oc !c -Special ${who}
    }
    wait 20
}

function JCmd_Target(string targetName)
{
    if ${targetName.Equal["None"]} || ${targetName.Equal["none"]}
    {
        eq2execute /target_none
    }
    else
    {
        Actor["${targetName}"]:DoTarget
    }
    wait 5
}

; ================================================================================
; QUEST COMMANDS
; ================================================================================

function JCmd_QuestCheck(string questName, string stepText, string expectedState="unchecked")
{
    echo ${Time}: [QuestCheck] ${questName} → ${stepText}
    
    ; This would call the quest checking function from JCommandExecutor
    ; For now, placeholder
    echo ${Time}: [QuestCheck] Feature implemented in JCommandExecutor
}

function JCmd_AcceptReward(string who, string rewardNum="1")
{
    oc !ci -AcceptReward ${who} "${rewardNum}"
    wait 20
}

function JCmd_OptNum(string optionNumber)
{
    oc !ci -OptNum ${optionNumber}
    wait 20
}

; ================================================================================
; NAVIGATION COMMANDS
; ================================================================================

function JCmd_Navigate(string pathName, string reverse="false", string preBuff="false", string ignoreAggro="false")
{
    variable bool bReverse = FALSE
    variable bool bPreBuff = FALSE
    variable bool bIgnoreAggro = FALSE
    
    if ${reverse.Equal[true]} || ${reverse.Equal[TRUE]} || ${reverse.Equal[1]}
        bReverse:Set[TRUE]
    if ${preBuff.Equal[true]} || ${preBuff.Equal[TRUE]} || ${preBuff.Equal[1]}
        bPreBuff:Set[TRUE]
    if ${ignoreAggro.Equal[true]} || ${ignoreAggro.Equal[TRUE]} || ${ignoreAggro.Equal[1]}
        bIgnoreAggro:Set[TRUE]
    
    call Obj_J.NavigatePath "${pathName}" ${bReverse} ${bPreBuff} ${bIgnoreAggro}
}

function JCmd_GoTo(string x, string y, string z, string tolerance="3")
{
    Obj_J:NavigateToWaypoint ${x} ${y} ${z} ${tolerance}
}

function JCmd_Waypoint(string who, string x, string y, string z)
{
    OgreBotAPI:Waypoint["${who}",${x},${y},${z}]
}

; ================================================================================
; COLLECTIBLES / LOOT
; ================================================================================

function JCmd_SearchCollectibles(string radius="10")
{
    variable int searchRadius = ${radius}
    
    echo ${Time}: [Collectibles] Searching within ${searchRadius}m...
    
    ; Basic implementation - can be enhanced
    variable index:actor collectibles
    variable iterator collectibleIter
    
    EQ2:GetActors[collectibles,Collectible,range,${searchRadius}]
    collectibles:GetIterator[collectibleIter]
    
    if ${collectibleIter:First(exists)}
    {
        echo ${Time}: [Collectibles] Found ${collectibles.Used} collectibles
        
        do
        {
            if ${collectibleIter.Value.Distance} <= ${searchRadius}
            {
                echo ${Time}: [Collectibles] → ${collectibleIter.Value.Name}
                
                ; Move to it
                while ${Math.Distance[${Me.Loc},${collectibleIter.Value.Loc}]} > 3
                {
                    face ${collectibleIter.Value.X} ${collectibleIter.Value.Z}
                    press -hold w
                    wait 1
                }
                press -release w
                
                ; Click it
                collectibleIter.Value:DoubleClick
                wait 10
            }
        }
        while ${collectibleIter:Next(exists)}
    }
    else
    {
        echo ${Time}: [Collectibles] None found
    }
}

; ================================================================================
; SCRIPT CONTROL
; ================================================================================

function JCmd_RunScript(string scriptPath)
{
    echo ${Time}: [RunScript] ${scriptPath}
    run "${scriptPath}"
}

function JCmd_EndScript()
{
    echo ${Time}: [EndScript] Stopping execution
    J_Instance_Running:Set[FALSE]
    J_QuestBot_TaskRunning:Set[FALSE]
}

function JCmd_BJ_Command(string target, string command)
{
    relay "${target}" "${command}"
    wait 5
}

; ================================================================================
; DEBUG / UTILITY
; ================================================================================

function JCmd_DebugPosition()
{
    echo ${Time}: ================================================
    echo ${Time}: [Debug] Current Position
    echo ${Time}: ================================================
    echo ${Time}: Position: ${Me.Loc}
    echo ${Time}: Heading: ${Me.Heading}
    echo ${Time}: Zone: ${Zone.Name}
    echo ${Time}: ShortName: ${Zone.ShortName}
    echo ${Time}: ================================================
}

function JCmd_DebugTarget()
{
    if ${Target(exists)}
    {
        echo ${Time}: ================================================
        echo ${Time}: [Debug] Current Target
        echo ${Time}: ================================================
        echo ${Time}: Name: ${Target.Name}
        echo ${Time}: ID: ${Target.ID}
        echo ${Time}: Distance: ${Target.Distance}
        echo ${Time}: Location: ${Target.Loc}
        echo ${Time}: Health: ${Target.Health}%
        echo ${Time}: ================================================
    }
    else
    {
        echo ${Time}: [Debug] No target selected
    }
}

function JCmd_ShowStats()
{
    echo ${Time}: ================================================
    echo ${Time}: [Stats] Character Status
    echo ${Time}: ================================================
    echo ${Time}: Health: ${Me.Health}%
    echo ${Time}: Power: ${Me.Power}%
    echo ${Time}: In Combat: ${Me.InCombat}
    echo ${Time}: Moving: ${Me.IsMoving}
    echo ${Time}: Zoning: ${EQ2.Zoning}
    if ${Me.InGroup}
    {
        echo ${Time}: Group Size: ${Me.GroupCount}
    }
    echo ${Time}: ================================================
}