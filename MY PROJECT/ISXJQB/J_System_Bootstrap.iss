; =====================================================
; J SYSTEM BOOTSTRAP - Master Integration Script
; =====================================================

variable(global) string J_System_Version = "3.0.1"
variable(global) string J_System_ReleaseDate = "2025-10-19"
variable(global) bool J_System_Initialized = FALSE

; Component status flags
variable(global) bool J_Movement_Loaded = FALSE
variable(global) bool J_Instance_Loaded = FALSE
variable(global) bool J_QuestBot_Loaded = FALSE
variable(global) bool J_Navigation_Loaded = FALSE
variable(global) bool J_Config_Loaded = FALSE

; Shared paths
variable(global) string J_BaseDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/"
variable(global) string J_MovementDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/"
variable(global) string J_InstanceDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/"
variable(global) string J_QuestBotDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/"

function main(string component="auto")
{
    echo ================================================
    echo J System Bootstrap v${J_System_Version}
    echo ================================================

    call CheckFirstTimeSetup

    switch ${component}
    {
        case auto
        case all
            call LoadAllComponents
            break
        case movement
            call LoadMovementOnly
            break
        case instance
            call LoadInstanceOnly
            break
        case ui
            call LoadUI
            break
        default
        echo Unknown component: ${component}
        return
    }

    J_System_Initialized:Set[TRUE]
    call ShowSystemStatus
}

; ================================================================================
; COMPONENT LOADING
; ================================================================================

function LoadAllComponents()
{
    call LoadConfigurationSystem
    call LoadNavigationSystem
    call LoadMovementSystem
    call LoadInstanceSystem
    call LoadQuestBotSystem
    call LoadUI
}

function LoadMovementOnly()
{
    call LoadConfigurationSystem
    call LoadMovementSystem
}

function LoadInstanceOnly()
{
    call LoadConfigurationSystem
    call LoadNavigationSystem
    call LoadInstanceSystem
}

; ================================================================================
; INDIVIDUAL SYSTEM LOADERS
; ================================================================================

function LoadConfigurationSystem()
{
    variable filepath configDir = "${J_MovementDir}config/"

    if !${configDir.FileExists}
    {
        call InitializeJMovement
    }

    if ${Script[JMovement](exists)} || ${Script[Buffer:JMovement](exists)} || ${Script[jmovement_main](exists)}
    {
        J_Config_Loaded:Set[TRUE]
    }
    else
    {
        J_Config_Loaded:Set[TRUE]
    }
}

function LoadNavigationSystem()
{
    if ${Obj_JNav(exists)}
    {
        J_Navigation_Loaded:Set[TRUE]
        return
    }

    variable filepath navPath1 = "${J_InstanceDir}JNavigation.iss"
    variable filepath navPath2 = "${J_InstanceDir}JNavigation"
    variable string foundPath = ""

    if ${navPath1.FileExists}
    foundPath:Set["${J_InstanceDir}JNavigation.iss"]
    elseif ${navPath2.FileExists}
    foundPath:Set["${J_InstanceDir}JNavigation"]

    if ${foundPath.Length}
    {
        runscript "${foundPath}"
        wait 10

        if ${Obj_JNav(exists)}
        J_Navigation_Loaded:Set[TRUE]
        else
        J_Navigation_Loaded:Set[FALSE]
    }
    else
    {
        J_Navigation_Loaded:Set[FALSE]
    }
}

function LoadMovementSystem()
{
    if ${Script[JMovement](exists)} || ${Script[Buffer:JMovement](exists)} || ${Script[jmovement_main](exists)}
    {
        J_Movement_Loaded:Set[TRUE]
        return
    }

    variable filepath movePath1 = "${J_MovementDir}JMovement.iss"
    variable filepath movePath2 = "${J_MovementDir}JMovement"
    variable filepath movePath3 = "${J_MovementDir}jmovement_main.iss"
    variable filepath movePath4 = "${J_MovementDir}jmovement_main"
    variable string foundPath = ""

    if ${movePath1.FileExists}
    foundPath:Set["${J_MovementDir}JMovement.iss"]
    elseif ${movePath2.FileExists}
    foundPath:Set["${J_MovementDir}JMovement"]
    elseif ${movePath3.FileExists}
    foundPath:Set["${J_MovementDir}jmovement_main.iss"]
    elseif ${movePath4.FileExists}
    foundPath:Set["${J_MovementDir}jmovement_main"]

    if ${foundPath.Length}
    {
        runscript "${foundPath}"
        wait 10

        if ${Script[JMovement](exists)} || ${Script[Buffer:JMovement](exists)} || ${Script[jmovement_main](exists)}
        J_Movement_Loaded:Set[TRUE]
        else
        J_Movement_Loaded:Set[FALSE]
    }
    else
    {
        J_Movement_Loaded:Set[FALSE]
    }
}

function LoadInstanceSystem()
{
    variable filepath instancePath1 = "${J_InstanceDir}JInstanceRunner.iss"
    variable filepath instancePath2 = "${J_InstanceDir}JInstanceRunner"
    variable filepath instancePath3 = "${J_InstanceDir}jinstance_runner.iss"
    variable filepath instancePath4 = "${J_InstanceDir}jinstance_runner"
    variable filepath instancePath5 = "${J_InstanceDir}Instance/jinstance_runner.iss"
    variable filepath instancePath6 = "${J_InstanceDir}Instance/JInstanceRunner.iss"

    if ${instancePath1.FileExists} || ${instancePath2.FileExists} || ${instancePath3.FileExists} || ${instancePath4.FileExists} || ${instancePath5.FileExists} || ${instancePath6.FileExists}
    J_Instance_Loaded:Set[TRUE]
    else
    J_Instance_Loaded:Set[FALSE]
}

function LoadQuestBotSystem()
{
    variable filepath questPath1 = "${J_QuestBotDir}JQuestBot.iss"
    variable filepath questPath2 = "${J_QuestBotDir}JQuestBot"
    variable filepath questPath3 = "${J_QuestBotDir}jquestbot.iss"
    variable filepath questPath4 = "${J_QuestBotDir}jquestbot"

    if ${questPath1.FileExists} || ${questPath2.FileExists} || ${questPath3.FileExists} || ${questPath4.FileExists}
    J_QuestBot_Loaded:Set[TRUE]
    else
    J_QuestBot_Loaded:Set[FALSE]
}

function LoadUI()
{
    echo "Loading UI..."

    variable filepath miniUIPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMini.xml"
    variable filepath mainUIPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMain.xml"
    variable filepath functionsPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JB_UI_Functions.iss"
    variable filepath skinPath = "${LavishScript.HomeDirectory}/Scripts/Interface/Skins/EQ2-Green/EQ2-Green.xml"

    ; Unload existing UI if it exists
    if ${UIElement[JBUI_Mini_Window](exists)}
    {
        ui -unload "${miniUIPath}"
        wait 10
    }
    if ${UIElement[JBUI_Main_Window](exists)}
    {
        ui -unload "${mainUIPath}"
        wait 10
    }

    ; Check if UI files exist
    if !${miniUIPath.FileExists} || !${mainUIPath.FileExists}
    {
        echo "\ayERROR: UI files not found\ax"
        return
    }

    ; Load UI helper functions
    if ${functionsPath.FileExists}
    {
        echo "Loading UI functions: ${functionsPath}"
        runscript "${functionsPath}"
        wait 10
    }

    ; Load skin if it exists
    if ${skinPath.FileExists}
    {
        echo "Loading skin: ${skinPath}"
        ui -reload "${skinPath}"
        wait 10

        ; Load UI with skin
        echo "Loading Mini UI with EQ2-Green skin: ${miniUIPath}"
        ui -load -skin EQ2-Green "${miniUIPath}"
        wait 20

        echo "Loading Main UI with EQ2-Green skin: ${mainUIPath}"
        ui -load -skin EQ2-Green "${mainUIPath}"
        wait 20
    }
    else
    {
        ; Fallback: load without skin
        echo "\ayWARNING: EQ2-Green skin not found, loading without skin\ax"
        ui -load "${miniUIPath}"
        wait 20
        ui -load "${mainUIPath}"
        wait 20
    }

    ; Verify UI loaded
    if ${UIElement[JBUI_Mini_Window](exists)}
    {
        echo "UI loaded successfully."
        return TRUE
    }
    else
    {
        echo "\ayERROR: Failed to load UI.\ax"
        return FALSE
    }
}

; ================================================================================
; FIRST-TIME SETUP
; ================================================================================

function CheckFirstTimeSetup()
{
    ; Don't auto-create folders - they should come from the repo
    ; This was creating malformed folder names like "JBconfig" instead of "JB\config"

    echo NOTE: If folders are missing they should be copied from the git repository
    echo Do not rely on auto-creation as it may create incorrect folder structures
}

function InitializeJMovement()
{
    ; Folder initialization removed - use git repo folder structure instead
    echo NOTE: JMovement folders should be copied from git repository
}

; ================================================================================
; INTEGRATION HELPERS
; ================================================================================

function RunInstance(string instanceName)
{
    if !${J_Instance_Loaded}
    {
        echo ERROR: Instance system not loaded
        return
    }

    if !${J_Navigation_Loaded}
    call LoadNavigationSystem

    runscript "${J_InstanceDir}JInstanceRunner.iss" "${instanceName}"
}

function RunQuestTask(string taskName)
{
    if !${J_QuestBot_Loaded}
    {
        echo ERROR: Quest bot system not loaded
        return
    }

    if !${J_Navigation_Loaded}
    call LoadNavigationSystem

    runscript "${J_QuestBotDir}JQuestBot.iss" "${taskName}"
}

function RunQuestQueue(string queueName)
{
    if !${J_QuestBot_Loaded}
    {
        echo ERROR: Quest bot system not loaded
        return
    }

    if !${J_Navigation_Loaded}
    call LoadNavigationSystem

    runscript "${J_QuestBotDir}JQuestBot.iss" "" "${queueName}"
}

function StartMovement()
{
    if !${J_Movement_Loaded}
    call LoadMovementSystem
}

function ReloadConfigs()
{
    if ${Script[JMovement](exists)} || ${Script[Buffer:JMovement](exists)} || ${Script[jmovement_main](exists)}
    {
        relay all "_obJZoneManager:LoadZonesConfig"
        relay all "_obJConfig:LoadZoneConfig"
    }
}

; ================================================================================
; STATUS & DIAGNOSTICS
; ================================================================================

function ShowSystemStatus()
{
    echo ================================================
    echo SYSTEM STATUS:
    echo ================================================

    if ${J_Config_Loaded}
    echo Configuration: OK
    else
    echo Configuration: NOT LOADED

    if ${J_Navigation_Loaded}
    echo Navigation: OK
    else
    echo Navigation: NOT LOADED

    if ${J_Movement_Loaded}
    echo Movement: OK
    else
    echo Movement: NOT LOADED

    if ${J_Instance_Loaded}
    echo Instance Runner: OK
    else
    echo Instance Runner: NOT AVAILABLE

    if ${J_QuestBot_Loaded}
    echo Quest Bot: OK
    else
    echo Quest Bot: NOT AVAILABLE

    echo ================================================
}

; ================================================================================
; CONSOLE COMMANDS
; ================================================================================

atom(global) J_Status()
{
    call ShowSystemStatus
}

atom(global) J_Reload()
{
    call ReloadConfigs
}

atom(global) J_RunInstance(string instanceName)
{
    call RunInstance "${instanceName}"
}

atom(global) J_RunTask(string taskName)
{
    call RunQuestTask "${taskName}"
}

atom(global) J_RunQueue(string queueName)
{
    call RunQuestQueue "${queueName}"
}

atom(global) J_StartMovement()
{
    call StartMovement
}

atom(global) J_LoadUI()
{
    ExecuteQueued "call LoadUI"
}

atom(global) J_RebootSystem()
{
    if ${Script[JMovement](exists)}
    endscript JMovement
    if ${Script[Buffer:JMovement](exists)}
    endscript Buffer:JMovement
    if ${Script[jmovement_main](exists)}
    endscript jmovement_main
    if ${Script[JInstanceRunner](exists)}
    endscript JInstanceRunner
    if ${Script[JQuestBot](exists)}
    endscript JQuestBot

    runscript "Eq2JCommon/J_System_Bootstrap"
}

; ================================================================================
; EXIT HANDLER
; ================================================================================

function atexit()
{
}
