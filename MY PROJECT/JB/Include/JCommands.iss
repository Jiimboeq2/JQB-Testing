
function JCmd_Navigate(string pathName, string reverse, string preBuff, string ignoreAggro)
{
    echo JCmd_Navigate stub

    echo ${Time}: [JCommands] Shared command library loaded
    variable bool bReverse = FALSE
    variable bool bPreBuff = FALSE
    variable bool bIgnoreAggro = FALSE

    if ${reverse.Equal[true]} || ${reverse.Equal[TRUE]} || ${reverse.Equal[1]}
    bReverse:Set[TRUE]

    if ${preBuff.Equal[true]} || ${preBuff.Equal[TRUE]} || ${preBuff.Equal[1]}
    bPreBuff:Set[TRUE]

    if ${ignoreAggro.Equal[true]} || ${ignoreAggro.Equal[TRUE]} || ${ignoreAggro.Equal[1]}
    bIgnoreAggro:Set[TRUE]

    ; This requires J_Instance_CurrentTask or J_QuestBot_CurrentTask to be available
    if ${J_Instance_CurrentTask(exists)}
    {
        call Obj_JNav.NavigatePathFromInstance "${pathName}" "${J_Instance_CurrentTask}" ${bReverse} ${bPreBuff} ${bIgnoreAggro}
    }
    elseif ${J_QuestBot_CurrentTask(exists)}
    {
        ; Check if QuestBot task has navigation paths
        if ${J_QuestBot_CurrentTask.Has[navigation_paths]}
        {
            call Obj_JNav.NavigatePathFromInstance "${pathName}" "${J_QuestBot_CurrentTask}" ${bReverse} ${bPreBuff} ${bIgnoreAggro}
        }
        else
        {
            echo ${Time}: ERROR: Task missing navigation_paths section
        }
    }
    else
    {
        echo ${Time}: ERROR: No active task found for navigation
    }
}

; =====================================================
; OGREBOT INTEGRATION COMMANDS
; =====================================================

function JCmd_SetCampSpot(string Who, int Range, int Mode)
{
    relay "${Who}" "oc !c -CampSpot ${Mode} ${Range}"
    wait 5
}

function JCmd_ChangeCampSpot(string Who, string Location)
{
    relay "${Who}" "oc !c -ChangeCampSpot ${Who} ${Location}"
    wait 5
}

function JCmd_Waypoint(string Who, string Location)
{
    relay "${Who}" "EQ2EXECUTE waypoint ${Location}"
    wait 5
}

function JCmd_EnableMoveToArea(string Who)
{
    if !${UIElement[checkbox_settings_movetoarea@frame_TabColumn1Button1@uiXML].Checked}
    relay "${Who}" "UIElement[checkbox_settings_movetoarea@frame_TabColumn1Button1@uiXML]:LeftClick"
    wait 5
}

function JCmd_DisableMoveToArea(string Who)
{
    if ${UIElement[checkbox_settings_movetoarea@frame_TabColumn1Button1@uiXML].Checked}
    relay "${Who}" "UIElement[checkbox_settings_movetoarea@frame_TabColumn1Button1@uiXML]:LeftClick"
    wait 5
}

function JCmd_EnableMoveBehind(string Who)
{
    if !${UIElement[${OBUI_checkbox_settings_movebehind}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_movebehind}]:LeftClick"
    wait 5
}

function JCmd_DisableMoveBehind(string Who)
{
    if ${UIElement[${OBUI_checkbox_settings_movebehind}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_movebehind}]:LeftClick"
    wait 5
}

; =====================================================
; AUTO-TARGET COMMANDS
; =====================================================

function JCmd_ClearAutoTarget(string Who)
{
    relay "${Who}" "Ob_AutoTarget:Clear"
    wait 5
}

function JCmd_AddAutoTarget(string Who, string ActorName, int Priority)
{
    relay "${Who}" "Ob_AutoTarget:AddActor[\"${ActorName}\",${Priority}]"
    wait 5
}

function JCmd_SetAutoTargetRadius(string Who, int Radius)
{
    relay "${Who}" "UIElement[${OBUI_slider_autotarget_scanradius}]:SetValue[${Radius}]"
    wait 5
}

function JCmd_EnableAutoTarget(string Who)
{
    if !${UIElement[${OBUI_checkbox_autotarget_enabled}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_autotarget_enabled}]:LeftClick"
    wait 5
}

function JCmd_DisableAutoTarget(string Who)
{
    if ${UIElement[${OBUI_checkbox_autotarget_enabled}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_autotarget_enabled}]:LeftClick"
    wait 5
}

; =====================================================
; JOUST COMMANDS
; =====================================================

function JCmd_JoustOut(string Who)
{
    relay "${Who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustOut]"
    wait 5
}

function JCmd_JoustIn(string Who)
{
    relay "${Who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustIn]"
    wait 5
}

; =====================================================
; CAST STACK MANAGEMENT
; =====================================================

function JCmd_DisableCastStack(string Who)
{
    if !${UIElement[${OBUI_checkbox_settings_disablecaststack}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_disablecaststack}]:LeftClick"
    wait 5
}

function JCmd_EnableCastStack(string Who)
{
    if ${UIElement[${OBUI_checkbox_settings_disablecaststack}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_disablecaststack}]:LeftClick"
    wait 5
}

; =====================================================
; ENCOUNTER SETUP HELPERS
; =====================================================

function JCmd_SetupEncounter(string Who, string Location, int CampRange, int CampMode)
{
    call JCmd_EnableMoveToArea "${Who}"
    call JCmd_SetCampSpot "${Who}" ${CampRange} ${CampMode}
    call JCmd_Waypoint "${Who}" "${Location}"
    call JCmd_JoustOut "${Who}"
    call JCmd_ChangeCampSpot "${Who}" "${Location}"
}

function JCmd_SetupEncounterWithTarget(string Who, string Location, string TargetName, int ScanRadius, int CampRange)
{
    call JCmd_ClearAutoTarget "${Who}"
    call JCmd_AddAutoTarget "${Who}" "${TargetName}" 0
    call JCmd_SetAutoTargetRadius "${Who}" ${ScanRadius}
    call JCmd_EnableAutoTarget "${Who}"
    call JCmd_SetupEncounter "${Who}" "${Location}" ${CampRange} 2
}

; =====================================================
; RELAY COMMANDS
; =====================================================

function JCmd_IRC(string Message)
{
    relay all "echo J IRC: ${Message}"
}

function JCmd_Announce(string Message)
{
    relay all "oc ${Message}"
}

; =====================================================
; DEBUG HELPERS
; =====================================================

function JCmd_DebugPosition()
{
    echo Current Position: ${Me.Loc}
    echo Current Heading: ${Me.Heading}
    echo Current Zone: ${Zone.Name}
    echo Zone ShortName: ${Zone.ShortName}
}

function JCmd_DebugTarget()
{
    if ${Target(exists)}
    {
        echo Target: ${Target.Name}
        echo Target ID: ${Target.ID}
        echo Target Distance: ${Target.Distance}
        echo Target Loc: ${Target.Loc}
    }
    else
    {
        echo No target selected
    }
}

; =====================================================
; QUEST/TASK SPECIFIC HELPERS
; =====================================================

function JCmd_HailActor(string ActorName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        Actor[${actorID}]:DoTarget
        wait 5
        eq2execute /hail
        wait 10
    }
    else
    {
        echo ERROR: Actor not found: ${ActorName}
    }
}

function JCmd_DoubleClickActor(string ActorName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        Actor[${actorID}]:DoubleClick
        wait 10
    }
    else
    {
        echo ERROR: Actor not found: ${ActorName}
    }
}

function JCmd_ApplyVerb(string ActorName, string VerbName)
{
    variable int actorID = ${Actor["${ActorName}"].ID}

    if ${actorID}
    {
        Actor[${actorID}]:DoTarget
        wait 5
        Actor[${actorID}].Verb["${VerbName}"]:Execute
        wait 10
    }
    else
    {
        echo ERROR: Actor not found: ${ActorName}
    }
}

function JCmd_UseItem(string ItemName)
{
    if ${Me.Inventory["${ItemName}"](exists)}
    {
        Me.Inventory["${ItemName}"]:Use
        wait 10
    }
    else
    {
        echo ERROR: Item not found: ${ItemName}
    }
}

function JCmd_WaitForCombat(int TimeoutSeconds=30)
{
    variable int timeout = ${Math.Calc[${TimeoutSeconds}*10]}
    variable int counter = 0

    while !${Me.InCombat} && ${counter} < ${timeout}
    {
        wait 10
        counter:Inc
    }

    if !${Me.InCombat}
    {
        echo WARNING: Combat did not start within ${TimeoutSeconds} seconds
    }
}

function JCmd_WaitWhileCombat()
{
    while ${Me.InCombat}
    {
        wait 10
    }

    wait 20
}

function JCmd_WaitForZone(string ZoneName, int TimeoutSeconds=60)
{
    variable int timeout = ${Math.Calc[${TimeoutSeconds}*10]}
    variable int counter = 0

    while !${Zone.Name.Equal["${ZoneName}"]} && ${counter} < ${timeout}
    {
        wait 10
        counter:Inc
    }

    if !${Zone.Name.Equal["${ZoneName}"]}
    {
        echo WARNING: Did not enter ${ZoneName} within ${TimeoutSeconds} seconds
    }
}

