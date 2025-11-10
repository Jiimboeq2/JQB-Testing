/*
* Common movement command functions
* Reusable commands for all encounters
*/

; Camp spot management
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

; Waypoint navigation
function JCmd_Waypoint(string Who, string Location)
{
    relay "${Who}" "oc !c -WayPoint ${Location}"
    wait 5
}
; Movement toggles
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

; Auto-target management
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

; Joust commands
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

; Cast stack management
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

function JCmd_DisableCastStackCombat(string Who)
{
    if !${UIElement[${OBUI_checkbox_settings_disablecaststack_combat}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_disablecaststack_combat}]:LeftClick"
    wait 5
}

function JCmd_DisableCastStackCA(string Who)
{
    if !${UIElement[${OBUI_checkbox_settings_disablecaststack_ca}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_disablecaststack_ca}]:LeftClick"
    wait 5
}

function JCmd_DisableCastStackNamedCA(string Who)
{
    if !${UIElement[${OBUI_checkbox_settings_disablecaststack_namedca}].Checked}
    relay "${Who}" "UIElement[${OBUI_checkbox_settings_disablecaststack_namedca}]:LeftClick"
    wait 5
}

; Encounter setup helpers
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

; Group role based positioning
function JCmd_PositionByRole(int Role, string FighterLoc, string GroupLoc)
{
    if ${Role} == 1
    {
        call JCmd_SetupEncounter "${Me.Name}" "${FighterLoc}" 300 2
    }
    else
    {
        call JCmd_SetupEncounter "all" "${GroupLoc}" 300 2
    }
}

; Common encounter patterns
function JCmd_AddPhaseEncounter(string Who, string BossName, int Phase, string Location)
{
    echo ${Time}: ${BossName} Phase ${Phase} - Moving to ${Location}
    call JCmd_ChangeCampSpot "${Who}" "${Location}"
    wait 10
}

function JCmd_ToggleAddMode(bool Enable)
{
    if ${Enable}
    {
        call JCmd_EnableAutoTarget "all"
    }
    else
    {
        call JCmd_DisableAutoTarget "all"
    }
}

; IRC / Relay commands
function JCmd_IRC(string Message)
{
    relay all "echo J IRC: ${Message}"
}

function JCmd_Announce(string Message)
{
    relay all "oc ${Message}"
}

; Debug helpers
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