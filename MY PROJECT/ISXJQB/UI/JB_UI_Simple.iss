; =====================================================
; JB UI Loader - Simple Version (No JSON parsing)
; Path: ${LavishScript.HomeDirectory}/Scripts/Eq2Jcommon/UI/JB_UI_Simple.iss
; Usage: run Eq2Jcommon/UI/JB_UI_Simple
; =====================================================

; Include playback command library (legacy - keeping for backwards compatibility)
; Using relative paths from Script.CurrentDirectory to avoid case sensitivity issues
#include "${Script.CurrentDirectory}/../JB/Commands/JB_PlaybackCommands.iss"

; Include NEW object-based command system
#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandRegistry.iss"

; Include event system for advanced automation
#include "${Script.CurrentDirectory}/../JB/Core/JB_EventSystem.iss"

; Include permission manager
#include "${Script.CurrentDirectory}/../JB/Core/JB_PermissionManager.iss"

; Movement key definitions
#define MOVEFORWARD w
#define MOVEBACKWARD s
#define STRAFELEFT q
#define STRAFERIGHT e

; Calculate base directory from Script.CurrentDirectory
; Script.CurrentDirectory should be: .../Eq2JCommon/UI
; We need to get parent: .../Eq2JCommon
variable(global) string PATH_UI = "${Script.CurrentDirectory}"
variable(global) string PATH_BASE
variable(global) string PATH_JB

; =====================================================
; MASTER DEBUG FLAGS
; =====================================================
; Set to TRUE to enable ALL debug output from startup (for troubleshooting)
variable(global) bool JBUI_VerboseStartup = FALSE

; Debug mode - set by checkbox in UI Settings tab
variable(global) bool JBUI_DebugMode = FALSE

; System debug - controls command registry initialization spam
variable(global) bool JBUI_Debug_System = FALSE

; Movement thread communication globals
variable(global) float JBUI_Movement_TargetX = 0
variable(global) float JBUI_Movement_TargetY = 0
variable(global) float JBUI_Movement_TargetZ = 0
variable(global) bool JBUI_Movement_Active = FALSE
variable(global) bool JBUI_Movement_Arrived = FALSE
variable(global) bool JBUI_Movement_Stuck = FALSE
variable(global) bool JBUI_Movement_IsFinalWaypoint = FALSE

; Next waypoint for lookahead (smooth curved paths)
variable(global) float JBUI_Movement_NextX = 0
variable(global) float JBUI_Movement_NextY = 0
variable(global) float JBUI_Movement_NextZ = 0
variable(global) bool JBUI_Movement_HasNext = FALSE

; Stuck location blacklist (up to 10 stuck locations)
variable(global) int JBUI_Stuck_Count = 0
variable(global) float JBUI_Stuck_X[10]
variable(global) float JBUI_Stuck_Y[10]
variable(global) float JBUI_Stuck_Z[10]
variable(global) float JBUI_Stuck_Blacklist_Radius = 3.0

; =====================================================
; DEBUG OUTPUT HELPER
; =====================================================
; Usage: call JBUI_DebugEcho "[Component] Message"
; - Respects JBUI_DebugMode flag
; - Optionally broadcasts to group via oc command if JBUI_DebugToOC is enabled
; =====================================================
function JBUI_DebugEcho(string message)
{
    if !${JBUI_DebugMode}
        return

    ; Always echo to console
    echo ${message}

    ; Broadcast to group if enabled
    if ${JBUI_DebugToOC}
    {
        oc [${Me.Name}] ${message}
    }
}

; Extract parent directory by removing last path component
; Convert backslashes to forward slashes and tokenize
function:string GetParentPath(string fullPath)
{
    variable string result = "${fullPath}"
    variable string normalized = "${result.Replace["\\","/"]}"
    variable int tokenCount
    variable int i
    variable string rebuilt = ""

    echo [GetParentPath Debug] Input: ${fullPath}
    echo [GetParentPath Debug] Normalized: ${normalized}

    ; Count tokens
    tokenCount:Set[${normalized.Count["/"]}]
    tokenCount:Inc
    echo [GetParentPath Debug] Token count: ${tokenCount}

    ; Rebuild path without last component
    if ${tokenCount} > 1
    {
        for (i:Set[1] ; ${i} < ${tokenCount} ; i:Inc)
        {
            if ${i} > 1
                rebuilt:Concat["/"]
            rebuilt:Concat["${normalized.Token[${i},"/"].Escape}"]
        }
        echo [GetParentPath Debug] Rebuilt: ${rebuilt}
        return "${rebuilt}"
    }

    echo [GetParentPath Debug] Returning original (only 1 component)
    return "${normalized}"
}

; Paths will be initialized in LoadUI()

variable(global) string JBUI_SelectedFolderPath = ""
; Tracks current category for hierarchical navigation
variable(global) string JBUI_CurrentCategory = ""

; ================================================================================
; ACTOR CATALOG DATABASE - Global Variables
; ================================================================================
variable(global) string JBUI_Catalog_CurrentZone = ""
variable(global) bool JBUI_Catalog_AutoSave = TRUE
variable(global) int JBUI_Catalog_TotalActors = 0

; ================================================================================
; MODE SWITCHING
; ================================================================================

atom(script) JB_UI_SwitchMode(string mode)
{
    ; Hide all frames
    UIElement[${JBUI_Instances_Frame}]:Hide
    UIElement[${JBUI_Tasks_Frame}]:Hide
    UIElement[${JBUI_Queues_Frame}]:Hide
    UIElement[${JBUI_Progress_Frame}]:Hide
    UIElement[${JBUI_Settings_Frame}]:Hide
    UIElement[${JBUI_Mapper_Frame}]:Hide

    ; Reset all button colors
    UIElement[${JBUI_Mode_Instances_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Tasks_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Queues_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Progress_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Settings_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Mapper_Button}].Font:SetColor[FFFFFFFF]

    ; Show selected frame and highlight button
    switch ${mode}
    {
        case Instances
            UIElement[${JBUI_Instances_Frame}]:Show
            UIElement[${JBUI_Mode_Instances_Button}].Font:SetColor[FF00FF00]
            break
        case Tasks
            UIElement[${JBUI_Tasks_Frame}]:Show
            UIElement[${JBUI_Mode_Tasks_Button}].Font:SetColor[FF00FF00]
            break
        case Queues
            UIElement[${JBUI_Queues_Frame}]:Show
            UIElement[${JBUI_Mode_Queues_Button}].Font:SetColor[FF00FF00]
            break
        case Progress
            UIElement[${JBUI_Progress_Frame}]:Show
            UIElement[${JBUI_Mode_Progress_Button}].Font:SetColor[FF00FF00]
            break
        case Settings
            UIElement[${JBUI_Settings_Frame}]:Show
            UIElement[${JBUI_Mode_Settings_Button}].Font:SetColor[FF00FF00]
            break
        case Mapper
            UIElement[${JBUI_Mapper_Frame}]:Show
            UIElement[${JBUI_Mode_Mapper_Button}].Font:SetColor[FF00FF00]
            break
    }

    _sJB_CurrentMode:Set["${mode}"]
}

; ================================================================================
; PLACEHOLDER FUNCTIONS - No filelist/iterator or JSON parsing
; ================================================================================

atom(script) JB_UI_RefreshInstances()
{
    call JBUI_DebugEcho "Refresh: Check ${PATH_JB}/instances/"
}

atom(script) JB_UI_RefreshTasks()
{
    call JBUI_DebugEcho "Refresh: Check ${PATH_BASE}/JQuestBot/tasks/"
}

atom(script) JB_UI_RefreshQueues()
{
    call JBUI_DebugEcho "Refresh: Check ${PATH_BASE}/JQuestBot/queues/"
}

atom(script) JB_UI_LoadInstancePreview()
{
    echo Preview: ${_sJB_SelectedInstance}
}

atom(script) JB_UI_LoadTaskPreview()
{
    echo Preview: ${_sJB_SelectedTask}
}

atom(script) JB_UI_LoadQueuePreview()
{
    echo Preview: ${_sJB_SelectedQueue}
}

; ================================================================================
; PROGRESS UPDATE ATOMS
; ================================================================================

atom(global) JB_UI_UpdateProgress(int currentStep, int maxSteps, string command, string description)
{
    echo Progress: Step ${currentStep} / ${maxSteps} - ${command}
}

atom(global) JB_UI_UpdateStats(int completed, int failed, int duration)
{
    echo Stats: Completed ${completed}, Failed ${failed}, Duration ${duration}s
}

atom(global) JB_UI_LogMessage(string message)
{
    echo Log: ${message}
}

; ================================================================================
; MAIN FUNCTION
; ================================================================================

function main()
{
    ; Initialize paths BEFORE echoing them
    variable string currentDir = "${Script.CurrentDirectory}"

    ; Simple approach: replace "/UI" at end with "/JB"
    if ${currentDir.Find["/UI"]}
    {
        PATH_BASE:Set["${currentDir.Left[${Math.Calc[${currentDir.Length}-3]}]}"]
        PATH_JB:Set["${PATH_BASE}/JB"]
    }
    elseif ${currentDir.Find["\\UI"]}
    {
        PATH_BASE:Set["${currentDir.Left[${Math.Calc[${currentDir.Length}-3]}]}"]
        PATH_JB:Set["${PATH_BASE}/JB"]
    }
    else
    {
        PATH_BASE:Set["${currentDir}"]
        PATH_JB:Set["${currentDir}/JB"]
    }

    ; Show path information only if System Debug enabled
    if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
    {
        echo [JB UI] PATH_UI: ${PATH_UI}
        echo [JB UI] PATH_BASE: ${PATH_BASE}
        echo [JB UI] PATH_JB: ${PATH_JB}
        echo [JB UI] Script.CurrentDirectory: ${Script.CurrentDirectory}
        echo [JB UI] LavishScript.HomeDirectory: ${LavishScript.HomeDirectory}
    }

    ; Enable all debug flags if verbose startup is enabled
    if ${JBUI_VerboseStartup}
    {
        echo
        echo [JB UI] ====== VERBOSE STARTUP MODE ENABLED ======
        echo [JB UI] All debug output will be shown
        echo [JB UI] Setting all debug flags to TRUE...

        ; Declare and enable all debug flags
        declarevariable JBUI_Debug_Waypoints bool global TRUE
        declarevariable JBUI_Debug_Navigation bool global TRUE
        declarevariable JBUI_Debug_Movement bool global TRUE
        declarevariable JBUI_Debug_Commands bool global TRUE
        declarevariable JBUI_Debug_Events bool global TRUE
        declarevariable JBUI_Debug_Playback bool global TRUE
        declarevariable JBUI_Debug_System bool global TRUE
        declarevariable JBUI_DebugToOC bool global FALSE
        echo [JB UI] =========================================
        echo
    }

    ; Initialize command registry and manager (silent unless debug enabled)
    JBCmdRegistry:Initialize
    JBCmdManager:Initialize
    JBCmdRegistry:PrintSummary

    ; Initialize permission manager
    JBPermManager:Initialize

    if ${JBUI_VerboseStartup}
        echo [JB UI] Loading UI files...

    call LoadUI

    if ${JBUI_VerboseStartup}
        echo [JB UI] UI files loaded successfully

    ; Launch movement thread (separate script so wait/waitframe work)
    if ${JBUI_VerboseStartup}
        echo [JB UI] Launching movement thread...

    ; End any existing movement thread first
    if ${Script[JB_UI_Movement](exists)}
    {
        if ${JBUI_VerboseStartup}
            echo [JB UI] Ending existing movement thread...
        Script[JB_UI_Movement]:End
        wait 10
    }

    runscript "${PATH_UI}/JB_UI_Movement"
    wait 10

    ; Verify it launched successfully
    if !${Script[JB_UI_Movement](exists)}
    {
        echo [JB UI] ERROR: Movement thread failed to start!
        echo [JB UI] Shutting down...
        Script:End
        return
    }

    if ${JBUI_VerboseStartup}
        echo [JB UI] Movement thread launched successfully

    ; Keep script running
    do
    {
        if !${UIElement[JB_Mini_Window](exists)}
        {
            echo Mini window closed - exiting
            Script:End
        }

        ; Process queued commands from UI
        if ${QueuedCommands}
        ExecuteQueued

        ; Check for auto-recording waypoints if mapper is active
        if ${_sJB_CurrentMode.Equal[Mapper]}
        {
            call JBUI_Mapper_CheckDistance
            call JBUI_Mapper_UpdateActorInfo

            ; Playback processing moved to Thread #3 (JB_UI_Playback.iss)
            ; No longer blocks UI thread - playback runs independently!
        }

        wait 5
    }
    while 1
}

function LoadUI()
{
    if ${JBUI_VerboseStartup}
        echo Loading UI...

    ; Paths are already initialized in main()

    ; Unload existing UI if it exists
    if ${UIElement[JB_Mini_Window](exists)}
    {
        if ${JBUI_VerboseStartup}
            echo Unloading existing UI...
        ui -unload "${PATH_UI}/JBMini.xml"
        wait 10
    }

    ; Load EQ2-Green skin
    if ${JBUI_VerboseStartup}
        echo Loading EQ2-Green skin...
    if ${JBUI_VerboseStartup}
        echo [JB UI] Skin path: ${LavishScript.HomeDirectory}/Interface/Skins/EQ2-Green/EQ2-Green.xml
    ui -reload "${LavishScript.HomeDirectory}/Interface/Skins/EQ2-Green/EQ2-Green.xml"
    wait 10

    ; Load JBMini UI with EQ2-Green skin
    if ${JBUI_VerboseStartup}
        echo Loading JBMini UI...
    if ${JBUI_VerboseStartup}
        echo [JB UI] JBMini path: ${PATH_UI}/JBMini.xml
    ui -load -skin EQ2-Green "${PATH_UI}/JBMini.xml"
    wait 20

    if ${UIElement[JB_Mini_Window](exists)}
    {
        if ${JBUI_VerboseStartup}
            echo UI loaded successfully!
        if ${JBUI_VerboseStartup}
            echo [JB UI] JBMini window ID: ${JBUI_Mini_Window}
    }
    else
    {
        echo ERROR: Failed to load UI
        echo PATH_UI: ${PATH_UI}
        if ${JBUI_VerboseStartup}
        {
            echo [JB UI] DEBUG: Checking if file exists...
            if ${System.FileExists["${PATH_UI}/JBMini.xml"]}
                echo [JB UI] DEBUG: JBMini.xml file EXISTS
            else
                echo [JB UI] DEBUG: JBMini.xml file NOT FOUND
        }
        return
    }

    ; Unload existing JBMain if it exists (from previous session)
    if ${UIElement[JB_Main_Window](exists)}
    {
        if ${JBUI_VerboseStartup}
            echo [JB UI] WARNING: JB_Main_Window already exists - cleaning up from previous session
        ui -unload "${PATH_UI}/JBMain.xml"
        wait 10
    }

    ; Load JBMain UI (after JBMini is confirmed loaded)
    if ${JBUI_VerboseStartup}
        echo Loading JBMain UI...
    if ${JBUI_VerboseStartup}
        echo [JB UI] JBMain path: ${PATH_UI}/JBMain.xml
    ui -load -skin EQ2-Green "${PATH_UI}/JBMain.xml"
    wait 20

    ; Check both if window exists AND if ID was properly set
    ; Also verify the window is visible or can be made visible (not in error state)
    if ${UIElement[JB_Main_Window](exists)} && ${JBUI_Main_Window(exists)} && ${JBUI_Main_Window} > 0
    {
        ; Window appears to exist, but let's verify it's functional
        ; Try to access a property - if this fails, window is in error state
        variable bool windowValid = TRUE

        ; Test if we can access window properties
        if !${UIElement[JB_Main_Window].X(exists)}
        {
            windowValid:Set[FALSE]
            echo [ERROR] JB_Main_Window created but is non-functional (property access failed)
        }

        if ${windowValid}
        {
            if ${JBUI_VerboseStartup}
                echo Main UI loaded successfully!
            if ${JBUI_VerboseStartup}
                echo [JB UI] JBMain window ID: ${JBUI_Main_Window}
        }
        else
        {
            echo ERROR: JBMain window created but is in error state
            echo [ERROR] This usually indicates:
            echo [ERROR]   1. Missing or corrupt EQ2-Green skin
            echo [ERROR]   2. XML syntax error in JBMain.xml
            echo [ERROR]   3. Template mismatch between skin and XML
            echo [ERROR] Try: ui -reload "Interface/Skins/EQ2-Green/EQ2-Green.xml"
        }
    }
    else
    {
        echo ERROR: Failed to load Main UI
        echo [ERROR] Window exists: ${UIElement[JB_Main_Window](exists)}
        echo [ERROR] JBUI_Main_Window variable exists: ${JBUI_Main_Window(exists)}
        if ${JBUI_Main_Window(exists)}
            echo [ERROR] JBUI_Main_Window value: ${JBUI_Main_Window}
        echo [ERROR] PATH_UI: ${PATH_UI}
        echo [ERROR] File path: ${PATH_UI}/JBMain.xml
        if ${System.FileExists["${PATH_UI}/JBMain.xml"]}
            echo [ERROR] JBMain.xml file EXISTS
        else
            echo [ERROR] JBMain.xml file NOT FOUND
        echo [ERROR] Check if EQ2-Green skin is properly loaded
    }
}

function atexit()
{
    echo Shutting down JB UI...

    ; End playback thread (Thread #3) if it's still running
    if ${Script[JB_UI_Playback](exists)}
    {
        echo [JB UI] Ending playback thread (Thread #3)...
        Script[JB_UI_Playback]:End
    }

    ; End movement thread if it's still running
    if ${Script[JB_UI_Movement](exists)}
    {
        echo [JB UI] Ending movement thread...
        Script[JB_UI_Movement]:End
    }

    ui -unload "${PATH_UI}/JBMini.xml"
    ui -unload "${PATH_UI}/JBMain.xml"
    echo JB UI shut down successfully
}

; ================================================================================
; WAYPOINT MAPPER
; ================================================================================

atom(script) JBUI_Mapper_ToggleRecording()
{
    if ${JBUI_Mapper_Recording}
    {
        JBUI_Mapper_Recording:Set[FALSE]
        UIElement[${JBUI_Mapper_RecordButton}]:SetText["Start Recording"]
        UIElement[${JBUI_Mapper_RecordButton}].Font:SetColor[FF00FF00]
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Recording stopped - ${JBUI_Mapper_Count} waypoints"]
    }
    else
    {
        ; Start recording
        ; Check if we have existing data - if so, append instead of clearing
        if ${JBUI_Mapper_Count} > 0
        {
            ; APPEND MODE - continue recording from where we left off
            JBUI_Mapper_Recording:Set[TRUE]
            UIElement[${JBUI_Mapper_RecordButton}]:SetText["Stop Recording"]
            UIElement[${JBUI_Mapper_RecordButton}].Font:SetColor[FFFF0000]
            UIElement[${JBUI_Mapper_StatusText}]:SetText["Recording resumed - ${JBUI_Mapper_Count} waypoints (APPEND MODE)"]
            echo [Mapper] Resumed recording in APPEND mode (${JBUI_Mapper_Count} existing items)
        }
        else
        {
            ; FRESH START - initialize new recording
            JBUI_Mapper_Recording:Set[TRUE]
            JBUI_Mapper_Count:Set[0]
            UIElement[${JBUI_Mapper_WaypointList}]:ClearItems

            ; Get quest metadata from UI
            variable string questName = "${UIElement[${JBUI_Mapper_QuestName_TextEntry}].Text}"
            variable string questLine = "${UIElement[${JBUI_Mapper_QuestLine_TextEntry}].Text}"

            ; Initialize XML data with optional quest metadata
            JBUI_Mapper_XmlData:Set["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Waypoints"]
            if !${questName.Equal[""]}
            {
                JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData} questName=\"${questName}\""]
            }
            if !${questLine.Equal[""]}
            {
                JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData} questLine=\"${questLine}\""]
            }
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}>"]

            UIElement[${JBUI_Mapper_RecordButton}]:SetText["Stop Recording"]
            UIElement[${JBUI_Mapper_RecordButton}].Font:SetColor[FFFF0000]
            UIElement[${JBUI_Mapper_StatusText}]:SetText["Recording started..."]
            echo [Mapper] Started NEW recording

            ; Add first waypoint at current position
            call JBUI_Mapper_AddWaypointInternal
            JBUI_Mapper_LastX:Set[${Me.X}]
            JBUI_Mapper_LastY:Set[${Me.Y}]
            JBUI_Mapper_LastZ:Set[${Me.Z}]
        }
    }
}

atom(script) JBUI_Mapper_AddWaypoint()
{
    if !${JBUI_Mapper_Recording}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Start recording first!"]
        return
    }

    call JBUI_Mapper_AddWaypointInternal
    UIElement[${JBUI_Mapper_StatusText}]:SetText["Added waypoint ${JBUI_Mapper_Count}"]
}

function JBUI_Mapper_AddWaypointInternal()
{
    JBUI_Mapper_Count:Inc

    ; Add to XML data (direct interpolation)
    JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Waypoint X=\"${Me.X}\" Y=\"${Me.Y}\" Z=\"${Me.Z}\" />"]

    ; Add to listbox
    UIElement[${JBUI_Mapper_WaypointList}]:AddItem["${JBUI_Mapper_Count}. ${Me.X}, ${Me.Y}, ${Me.Z}"]

    ; Scroll to bottom
    UIElement[${JBUI_Mapper_WaypointList}].FindUsableChild[Vertical,Scrollbar]:SetValue[0]

    echo [${JBUI_Mapper_Count}] ${Me.X}, ${Me.Y}, ${Me.Z}
}

function JBUI_Mapper_CheckDistance()
{
    if !${JBUI_Mapper_Recording}
    return

    variable float dx
    variable float dy
    variable float dz
    variable float dist

    dx:Set[${Math.Calc[${Me.X} - ${JBUI_Mapper_LastX}]}]
    dy:Set[${Math.Calc[${Me.Y} - ${JBUI_Mapper_LastY}]}]
    dz:Set[${Math.Calc[${Me.Z} - ${JBUI_Mapper_LastZ}]}]

    dist:Set[${Math.Sqrt[${Math.Calc[${dx}*${dx} + ${dy}*${dy} + ${dz}*${dz}]}]}]

    if ${dist} >= ${JBUI_Mapper_Distance}
    {
        call JBUI_Mapper_AddWaypointInternal
        JBUI_Mapper_LastX:Set[${Me.X}]
        JBUI_Mapper_LastY:Set[${Me.Y}]
        JBUI_Mapper_LastZ:Set[${Me.Z}]
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Recording... ${JBUI_Mapper_Count} waypoints (${dist.Precision[1]}m)"]
    }
}

atom(script) JBUI_Mapper_ClearAll()
{
    UIElement[${JBUI_Mapper_WaypointList}]:ClearItems
    JBUI_Mapper_Count:Set[0]
    JBUI_Mapper_XmlData:Set["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Waypoints>"]
    UIElement[${JBUI_Mapper_StatusText}]:SetText["All waypoints cleared"]
}

atom(script) JBUI_Mapper_InsertCommand(string commandType)
{
    variable string param
    param:Set["${UIElement[${JBUI_Mapper_CommandParam_TextEntry}].Text}"]

    variable string commandText

    switch ${commandType}
    {
        case Wait
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter wait time in seconds"]
                return
            }
            commandText:Set["[CMD] Wait ${param} seconds"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"Wait\" Value=\"${param}\" />"]
            break
        case CatalogPath
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter scan radius in meters"]
                return
            }
            commandText:Set["[CMD] CatalogPath radius=${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"CatalogPath\" Value=\"${param}\" />"]
            break
        case ClickActor
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter actor name"]
                return
            }
            commandText:Set["[CMD] Click Actor: ${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"ClickActor\" Value=\"${param}\" />"]
            break
        case HailActor
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter actor name"]
                return
            }
            commandText:Set["[CMD] Hail Actor: ${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"HailActor\" Value=\"${param}\" />"]
            break
        case Custom
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter custom command"]
                return
            }
            commandText:Set["[CMD] Custom: ${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"Custom\" Value=\"${param}\" />"]
            break
        case Reverse
            commandText:Set["[CMD] Reverse Path"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"Reverse\" />"]
            break
        case Loop
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter loop count"]
                return
            }
            commandText:Set["[CMD] Loop ${param} times"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"Loop\" Value=\"${param}\" />"]
            break
        case LoopUntilFaction
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter faction name and target amount"]
                return
            }
            commandText:Set["[CMD] LoopUntilFaction ${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"LoopUntilFaction\" Value=\"${param}\" />"]
            break
        case DumpAll
            commandText:Set["[CMD] Dump All to Depots"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"DumpAll\" />"]
            break
        case ZoneReset
            ; If param is empty, use current zone
            variable string zoneName
            if ${param.Length} == 0
            {
                zoneName:Set["${Zone.Name}"]
            }
            else
            {
                zoneName:Set["${param}"]
            }
            commandText:Set["[CMD] Zone Reset: ${zoneName}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"ZoneReset\" Value=\"${zoneName}\" />"]
            break

        ; Commands with required parameters
        case NavToLoc
        case CampSpot
        case ChangeCampSpot
        case ChangeCampSpotWho
        case MoveToPerson
        case MoveToArea
        case CampSpotAutoPosition
        case FaceActor
        case FaceLoc
        case TargetActor
        case WaitForActor
        case WaitForNPCAlive
        case ApplyVerb
        case ConversationBubble
        case ReplyDialog
        case ChoiceWindow
        case GetToZone
        case ZoneDoor
        case Door
        case TravelBell
        case TravelDruid
        case TravelSpire
        case UseEverporter
        case CastAbility
        case CastAbilityOnPlayer
        case UseItem
        case UseItemOnActor
        case CheckQuestStep
        case HaveQuest
        case HaveQuestCompleted
        case OffersQuest
        case GetSpecificQuestFromNPC
        case ChangeOgreBotUIOption
        case MoveToActor
        case OpenAndBuyFromMerchant
        case AutoTargetAddActor
        case AutoTargetRemoveActor
        case RawCommandOB
        case CheckDetriment
        case CheckDetrimentStacks
        case WaitForQuestOffered
        case CheckChoiceWindow
        case WaitForChatText
        case GoToActor
        case FindNearest
        case InteractActor
            if ${param.Length} == 0
            {
                UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: ${commandType} requires a parameter"]
                return
            }
            commandText:Set["[CMD] ${commandType}: ${param}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"${commandType}\" Value=\"${param}\" />"]
            break

        ; Commands with NO parameters
        case ClearCampSpot
        case CampSpotAutoNPC
        case CampSpotJoustOut
        case CampSpotJoustIn
        case FlyUp
        case FlyDown
        case FlyStop
        case LandFlyingMount
        case ReplyDialogClose
        case WaitForZoning
        case WaitForZoned
        case DisableCombat
        case EnableCombat
        case Resume
        case Pause
        case RepairGear
        case Mount
        case Dismount
        case Evac
        case ResetCameraAngle
        case CheckPackPony
        case CheckMercenaryTraining
        case SpewZoneDoorOptions
        case Jump
        case Special
        case CS_ClearAll
        case ClearAbilityQueue
        case CancelSpellcast
        case AutoTargetClear
        case AutoTargetEnable
        case AutoTargetDisable
        case EnableStuns
        case DisableStuns
        case EnableInterrupts
        case DisableInterrupts
        case EnableCures
        case DisableCures
        case EnableDispells
        case DisableDispells
        case DisableAllAOEs
        case EnableAllAOEs
        case HOEnableAll
        case HODisable
        case HOScoutOnly
        case HOPriestOnly
        case HOMageOnly
        case HOFighterOnly
            commandText:Set["[CMD] ${commandType}"]
            JBUI_Mapper_XmlData:Set["${JBUI_Mapper_XmlData}\n    <Command Type=\"${commandType}\" />"]
            break

        default
            UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Unknown command type: ${commandType}"]
            return
    }

    ; Add command to listbox
    UIElement[${JBUI_Mapper_WaypointList}]:AddItem["${commandText}"]

    ; Clear parameter field
    UIElement[${JBUI_Mapper_CommandParam_TextEntry}]:SetText[""]

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Command added: ${commandType}"]
    echo [Mapper] Added command: ${commandText}
}

atom(script) JBUI_Mapper_DeleteSelected()
{
    if !${UIElement[${JBUI_Mapper_WaypointList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Select an item to delete"]
        return
    }

    variable string itemText = "${UIElement[${JBUI_Mapper_WaypointList}].SelectedItem.Text}"
    UIElement[${JBUI_Mapper_WaypointList}].SelectedItem:Remove

    ; Decrement waypoint count if it was a waypoint (not a command)
    if !${itemText.Find[[CMD]]}
    {
        JBUI_Mapper_Count:Dec
    }

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Deleted: ${itemText.Left[30]}"]
    echo [Mapper] Deleted: ${itemText}
}

atom(script) JBUI_Mapper_Save()
{
    if ${JBUI_Mapper_Count} == 0
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: No waypoints to save"]
        return
    }

    variable file xmlFile
    variable string zoneName = "${Zone.Name}"
    variable filepath basePath = "${PATH_JB}"
    variable string folderType = "waypoints"

    ; Determine which save type is selected
    if ${UIElement[${JBUI_Mapper_SaveType_Quest}].Checked}
    {
        folderType:Set["quests"]
        call JBUI_DebugEcho "[Mapper Debug] Quest checkbox is CHECKED - setting folderType to quests"
    }
    elseif ${UIElement[${JBUI_Mapper_SaveType_Task}].Checked}
    {
        folderType:Set["tasks"]
        call JBUI_DebugEcho "[Mapper Debug] Task checkbox is CHECKED - setting folderType to tasks"
    }
    elseif ${UIElement[${JBUI_Mapper_SaveType_Queue}].Checked}
    {
        folderType:Set["queues"]
        call JBUI_DebugEcho "[Mapper Debug] Queue checkbox is CHECKED - setting folderType to queues"
    }
    else
    {
        call JBUI_DebugEcho "[Mapper Debug] No special type checked - defaulting to waypoints"
    }

    ; WORKAROUND: Build path using direct concatenation instead of interpolation
    ; Even variable assignment uses interpolation! Must use :Concat instead
    variable string saveFolderPath
    saveFolderPath:Set["${PATH_JB}/"]
    saveFolderPath:Concat[${folderType}]

    ; Create category folder if it doesn't exist (use concatenation!)
    variable filepath categoryFolderPath
    categoryFolderPath:Set[${PATH_JB}]
    if !${categoryFolderPath.FileExists[${folderType}]}
    {
        categoryFolderPath:MakeSubdirectory[${folderType}]
        if ${JBUI_DebugMode}
            echo [Mapper Debug] Created category folder: ${folderType}
    }

    ; For quests, use quest line as folder if provided; otherwise use zone name
    variable string subfolderName
    if ${folderType.Equal["quests"]} && ${JBUI_Mapper_QuestLine.Length} > 0
    {
        subfolderName:Set["${JBUI_Mapper_QuestLine}"]
        if ${JBUI_DebugMode}
            echo [Mapper Debug] Using quest line as folder: ${subfolderName}
    }
    else
    {
        subfolderName:Set["${zoneName}"]
        if ${JBUI_DebugMode}
            echo [Mapper Debug] Using zone name as folder: ${subfolderName}
    }

    ; Create subfolder if it doesn't exist (use already-built saveFolderPath)
    variable filepath zoneFolderPath
    zoneFolderPath:Set[${saveFolderPath}]
    if !${zoneFolderPath.FileExists[${subfolderName}]}
    {
        zoneFolderPath:MakeSubdirectory[${subfolderName}]
        if ${JBUI_DebugMode}
            echo [Mapper Debug] Created subfolder: ${subfolderName} in ${folderType}
    }

    if ${JBUI_DebugMode}
    {
        echo [Mapper Debug] Category folder: ${saveFolderPath}
        echo [Mapper Debug] Subfolder created/verified: ${subfolderName}

        echo [Mapper Debug] ========================================
        echo [Mapper Debug] RIGHT BEFORE path construction:
        echo [Mapper Debug]   folderType = ${folderType}
        echo [Mapper Debug]   saveFolderPath = ${saveFolderPath}
        echo [Mapper Debug]   PATH_JB = ${PATH_JB}
        echo [Mapper Debug]   zoneName = ${zoneName}
        echo [Mapper Debug]   JBUI_Mapper_PathName = ${JBUI_Mapper_PathName}
        echo [Mapper Debug] ========================================
    }

    ; Build paths using concatenation instead of interpolation (LavishScript bug workaround)
    variable string xmlPath
    xmlPath:Set[${saveFolderPath}]
    xmlPath:Concat["/"]
    xmlPath:Concat[${subfolderName}]
    xmlPath:Concat["/"]
    xmlPath:Concat[${JBUI_Mapper_PathName}]
    xmlPath:Concat[".xml"]

    if ${JBUI_DebugMode}
    {
        echo [Mapper Debug] Constructed paths:
        echo [Mapper Debug]   xmlPath = ${xmlPath}
    }

    ; Write XML file (close tag directly in file, don't modify XmlData)
    xmlFile:SetFilename["${xmlPath}"]
    xmlFile:Open[write]
    xmlFile:Write["${JBUI_Mapper_XmlData}\n</Waypoints>"]
    xmlFile:Close

    variable int totalItems = ${UIElement[${JBUI_Mapper_WaypointList}].Items}

    UIElement[${JBUI_Mapper_StatusText}]:SetText["SAVED as ${folderType.Upper}: ${JBUI_Mapper_Count} items to ${subfolderName}/${JBUI_Mapper_PathName}"]

    echo ================================================
    echo SUCCESS: Saved ${JBUI_Mapper_Count} waypoints as ${folderType.Upper}
    echo Total Items (waypoints + commands): ${totalItems}
    echo Type: ${folderType}
    echo Folder: ${subfolderName}
    echo Zone: ${zoneName}
    echo XML:  ${xmlPath}
    echo ================================================
}

; ============================================================================
; Actor Inspector & Cataloging Functions
; ============================================================================

function JBUI_Mapper_UpdateActorInfo()
{
    if ${Me.CursorActor(exists)}
    {
        ; Actor exists - update info and timestamp
        variable string actorInfo
        actorInfo:Set["ID: ${Me.CursorActor.ID}  Name: ${Me.CursorActor.Name}\n"]
        actorInfo:Concat["Type: ${Me.CursorActor.Type}  Dist: ${Me.CursorActor.Distance.Precision[1]}m\n"]
        actorInfo:Concat["Loc: ${Me.CursorActor.X.Precision[2]}, ${Me.CursorActor.Y.Precision[2]}, ${Me.CursorActor.Z.Precision[2]}\n"]
        actorInfo:Concat["Interactable: ${Me.CursorActor.Interactable}  Radius: ${Me.CursorActor.CollisionRadius.Precision[2]}"]

        JBUI_Mapper_LastActorInfo:Set["${actorInfo}"]
        JBUI_Mapper_LastActorTime:Set[${LavishScript.RunningTime}]
        UIElement[${JBUI_Mapper_ActorInfo_Display}]:SetText["${actorInfo.Escape}"]
    }
    else
    {
        ; No actor - check if we should hold the last info (5 seconds)
        variable int timeSince
        timeSince:Set[${Math.Calc[${LavishScript.RunningTime} - ${JBUI_Mapper_LastActorTime}]}]

        if ${timeSince} > 5000
        {
            ; More than 5 seconds passed - clear the display
            JBUI_Mapper_LastActorInfo:Set[""]
            UIElement[${JBUI_Mapper_ActorInfo_Display}]:SetText["Hover over an actor to see info..."]
        }
        ; else - keep showing the last actor info (it's already displayed)
    }
}

atom(script) JBUI_Mapper_CatalogActor()
{
    if !${Me.CursorActor(exists)}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: No actor under cursor"]
        return
    }

    ; Build detailed actor entry with location
    variable string actorEntry
    actorEntry:Set["[${Me.CursorActor.Type}] ${Me.CursorActor.Name} (ID:${Me.CursorActor.ID}) - ${Me.CursorActor.Distance.Precision[1]}m @ ${Me.CursorActor.Loc.X.Precision[1]},${Me.CursorActor.Loc.Y.Precision[1]},${Me.CursorActor.Loc.Z.Precision[1]}"]

    ; Check if already cataloged
    variable int i
    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["ID:${Me.CursorActor.ID}"]}
        {
            UIElement[${JBUI_Mapper_StatusText}]:SetText["Actor already cataloged"]
            return
        }
    }

    UIElement[${JBUI_Mapper_ActorCatalog}]:AddItem["${actorEntry}"]

    ; Save detailed actor info to catalog database
    call JBUI_Catalog_SaveActor "${Me.CursorActor.ID}"

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Cataloged: ${Me.CursorActor.Name}"]
    echo [Mapper] Cataloged actor: ${actorEntry}

    ; Auto-save catalog to file
    if ${JBUI_Catalog_AutoSave}
        call JBUI_Catalog_SaveToFile
}

atom(script) JBUI_Mapper_UseSelectedActor()
{
    if !${UIElement[${JBUI_Mapper_ActorCatalog}].SelectedItem(exists)}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Select an actor first"]
        return
    }

    variable string actorText = "${UIElement[${JBUI_Mapper_ActorCatalog}].SelectedItem.Text}"

    ; Extract actor name from format: [Type] Name (ID:123)
    variable string actorName
    variable int startIdx
    variable int endIdx

    startIdx:Set[${actorText.Find["] "]}]
    startIdx:Inc[2]
    endIdx:Set[${actorText.Find[" (ID:"]}]

    if ${startIdx} > 0 && ${endIdx} > ${startIdx}
    {
        actorName:Set["${actorText.Mid[${startIdx},${Math.Calc[${endIdx}-${startIdx}]}]}"]
        UIElement[${JBUI_Mapper_CommandParam_TextEntry}]:SetText["${actorName}"]
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Using actor: ${actorName}"]
    }
    else
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Could not parse actor name"]
    }
}

atom(script) JBUI_Mapper_ClearActors()
{
    UIElement[${JBUI_Mapper_ActorCatalog}]:ClearItems
    UIElement[${JBUI_Mapper_StatusText}]:SetText["Actor catalog cleared"]
    echo [Mapper] Actor catalog cleared
}

; ============================================================================
; Command Library System
; ============================================================================

atom(script) JBUI_Mapper_PopulateCommands()
{
    ; ============================================
    ; NEW: Load commands from registry (object-based)
    ; ============================================

    ; Quest Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- QUEST ---"]
    call AddCategoryCommands "Quest"

    ; Gathering Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- GATHERING ---"]
    call AddCategoryCommands "Gathering"

    ; Crafting Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- CRAFTING ---"]
    call AddCategoryCommands "Crafting"

    ; Combat Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- COMBAT ---"]
    call AddCategoryCommands "Combat"

    ; Travel Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- TRAVEL ---"]
    call AddCategoryCommands "Travel"

    ; Utility Commands
    UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- UTILITY ---"]
    call AddCategoryCommands "Utility"

    if ${JBUI_DebugMode}
        echo [Mapper] Populated ${UIElement[${JBUI_Mapper_CommandList}].Items} commands from registry
}

; Helper function to add commands from registry category
function AddCategoryCommands(string category)
{
    variable string commandList
    variable int cmdCount
    variable int i
    variable string cmdName

    commandList:Set["${JBCmdRegistry.GetCommandsByCategory["${category}"]}"]

    if ${commandList.Length} > 0
    {
        cmdCount:Set[${commandList.Count[";"]}]
        cmdCount:Inc

        for (i:Set[1]; ${i} <= ${cmdCount}; i:Inc)
        {
            cmdName:Set["${commandList.Token[${i},";"]}"]
            if ${cmdName.Length} > 0
            {
                UIElement[${JBUI_Mapper_CommandList}]:AddItem["${cmdName}"]
            }
        }
    }
}

atom(script) JBUI_Mapper_FilterCommands()
{
    ; Get filter states
    variable bool showMovement = ${UIElement[${JBUI_Filter_Movement}].Checked}
    variable bool showNPC = ${UIElement[${JBUI_Filter_NPC}].Checked}
    variable bool showDialog = ${UIElement[${JBUI_Filter_Dialog}].Checked}
    variable bool showZone = ${UIElement[${JBUI_Filter_Zone}].Checked}
    variable bool showQuest = ${UIElement[${JBUI_Filter_Quest}].Checked}
    variable bool showCombat = ${UIElement[${JBUI_Filter_Combat}].Checked}
    variable bool showBot = ${UIElement[${JBUI_Filter_Bot}].Checked}
    variable bool showUtilities = ${UIElement[${JBUI_Filter_Utilities}].Checked}
    variable bool showPath = ${UIElement[${JBUI_Filter_Path}].Checked}

    ; Clear and repopulate based on filters
    UIElement[${JBUI_Mapper_CommandList}]:ClearItems

    ; Movement & Positioning
    if ${showMovement}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- MOVEMENT ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["NavToLoc"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CampSpot"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ChangeCampSpot"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ChangeCampSpotWho"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CampSpotAutoPosition"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CampSpotAutoNPC"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CampSpotJoustOut"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CampSpotJoustIn"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ClearCampSpot"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["MoveToPerson"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["MoveToArea"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["FaceActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["FaceLoc"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["FlyUp"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["FlyDown"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["FlyStop"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["LandFlyingMount"]
    }

    ; NPC Interaction
    if ${showNPC}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- NPC INTERACTION ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ClickActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HailActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["TargetActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForNPCAlive"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ApplyVerb"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["MoveToActor"]
    }

    ; Dialog & Conversation
    if ${showDialog}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- DIALOG ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ConversationBubble"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ReplyDialog"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ReplyDialogClose"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ChoiceWindow"]
    }

    ; Zone & Travel
    if ${showZone}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- ZONE & TRAVEL ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["GetToZone"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForZoning"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForZoned"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ZoneDoor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Door"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["TravelBell"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["TravelDruid"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["TravelSpire"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["UseEverporter"]
    }

    ; Quest Management
    if ${showQuest}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- QUEST ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HaveQuest"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckQuestStep"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HaveQuestCompleted"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["OffersQuest"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["GetSpecificQuestFromNPC"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForQuestOffered"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckChoiceWindow"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["WaitForChatText"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["LoopUntilFaction"]
    }

    ; Combat & Abilities
    if ${showCombat}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- COMBAT ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CastAbility"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CastAbilityOnPlayer"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["UseItem"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["UseItemOnActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableCombat"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableCombat"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckDetriment"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckDetrimentStacks"]

        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- COMBAT TOGGLES ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableStuns"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableStuns"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableInterrupts"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableInterrupts"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableCures"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableCures"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableDispells"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableDispells"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DisableAllAOEs"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["EnableAllAOEs"]

        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- AUTOTARGET ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["AutoTargetAddActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["AutoTargetClear"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["AutoTargetRemoveActor"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["AutoTargetEnable"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["AutoTargetDisable"]

        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- HEROIC OPPORTUNITIES ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HOEnableAll"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HODisable"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HOScoutOnly"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HOPriestOnly"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HOMageOnly"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["HOFighterOnly"]
    }

    ; Bot Control
    if ${showBot}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- BOT CONTROL ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Resume"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Pause"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ChangeOgreBotUIOption"]
    }

    ; Utilities & Flow
    if ${showUtilities}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- UTILITIES ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Wait"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CatalogPath"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["DumpAll"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ZoneReset"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["RepairGear"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Mount"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Dismount"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Evac"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ResetCameraAngle"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckPackPony"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CheckMercenaryTraining"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["OpenAndBuyFromMerchant"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["SpewZoneDoorOptions"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Jump"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Special"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CS_ClearAll"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["ClearAbilityQueue"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["CancelSpellcast"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["RawCommandOB"]
    }

    ; Path Control
    if ${showPath}
    {
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["--- PATH CONTROL ---"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Loop"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Reverse"]
        UIElement[${JBUI_Mapper_CommandList}]:AddItem["Custom"]
    }
}

atom(script) JBUI_Mapper_UpdateCommandHelp()
{
    if !${UIElement[${JBUI_Mapper_CommandList}].SelectedItem(exists)}
        return

    variable string cmdName = "${UIElement[${JBUI_Mapper_CommandList}].SelectedItem.Text}"
    variable string helpText

    ; Skip category headers
    if ${cmdName.Find["---"]}
    {
        UIElement[${JBUI_Mapper_ParamHelp_Text}]:SetText["Category header - select a command"]
        return
    }

    ; ============================================
    ; NEW: Get help from registry
    ; ============================================
    if ${JBCmdRegistry.CommandExists["${cmdName}"]}
    {
        helpText:Set["${JBCmdRegistry.GetCommandHelp["${cmdName}"]}"]
        UIElement[${JBUI_Mapper_ParamHelp_Text}]:SetText["${helpText.Escape}"]
        return
    }

    ; Legacy command support (fallback for old commands not in registry)
    switch ${cmdName}
    {
        case Wait
            helpText:Set["Wait for X seconds\nParam: seconds (e.g. 5)"]
            break
        case CatalogPath
            helpText:Set["Scan and record all actors within radius while recording\nContinuously catalogs actors in range\nParam: radius in meters (e.g. 30)\nOptional: radius,minLevel,maxLevel (e.g. 30,90,100)"]
            break
        case ClickActor
            helpText:Set["Click on an actor\nParam: actor name or ID"]
            break
        case HailActor
            helpText:Set["Hail an NPC\nParam: actor name"]
            break
        case TargetActor
            helpText:Set["Target an actor\nParam: actor name"]
            break
        case WaitForActor
            helpText:Set["Wait for actor spawn\nParam: actor name"]
            break
        case ApplyVerb
            helpText:Set["Use verb on actor\nParam: verb,actor"]
            break
        case ConversationBubble
            helpText:Set["Execute dialog options in sequence\nParam: options:waitTime (e.g. 1,2,1,3,4:20 = options with 20ds wait)\nDefault wait: 20ds (2sec) between options"]
            break
        case ReplyDialog
            helpText:Set["Reply to dialog\nParam: option number"]
            break
        case ChoiceWindow
            helpText:Set["Select from window\nParam: choice number"]
            break
        case NavToLoc
            helpText:Set["Navigate to location\nParam: X,Y,Z"]
            break
        case CampSpot
            helpText:Set["Set camp position\nParam: X,Y,Z or blank"]
            break
        case ChangeCampSpot
            helpText:Set["Move camp spot\nParam: X,Y,Z"]
            break
        case ChangeCampSpotWho
            helpText:Set["Move camp spot for specific group\nParam: ForWho,X,Y,Z (e.g. priest,10,0,-50)"]
            break
        case CampSpotAutoPosition
            helpText:Set["Auto position group (ForWho option)\nParam: ForWho (e.g. all, auto, Notfighter Mage|Priest|Scout)"]
            break
        case CampSpotAutoNPC
            helpText:Set["Auto position around NPC\nTank in front, others behind\nParam: none"]
            break
        case CampSpotJoustOut
            helpText:Set["Joust out from camp spot\nParam: none"]
            break
        case CampSpotJoustIn
            helpText:Set["Joust back to camp spot\nParam: none"]
            break
        case MoveToPerson
            helpText:Set["Move to another player\nParam: WhoMoves,WhoToMoveTo,Precision (e.g. all,MainTank,5)"]
            break
        case MoveToArea
            helpText:Set["Move to XY coordinates\nParam: WhoMoves,X,Y,Precision (e.g. fighter,100,-200,5)"]
            break
        case FaceActor
            helpText:Set["Turn character to face actor\nParam: ForWho,ActorName (e.g. all,NamedBoss)"]
            break
        case FaceLoc
            helpText:Set["Turn character to face location\nParam: ForWho,X,Y,Z (e.g. mage,100,0,-200)"]
            break
        case GetToZone
            helpText:Set["Travel to zone\nParam: zone name"]
            break
        case ZoneDoor
            helpText:Set["Select zone door\nParam: zone name"]
            break
        case Door
            helpText:Set["Click door option\nParam: option number"]
            break
        case TravelBell
            helpText:Set["Use bell travel\nParam: destination"]
            break
        case TravelDruid
            helpText:Set["Use druid ring\nParam: destination"]
            break
        case TravelSpire
            helpText:Set["Use spire travel\nParam: destination"]
            break
        case WaitForZoned
            helpText:Set["Wait until fully zoned\nWaits for !${EQ2.Zoning} && ${Me(exists)}\nUse after bells, spires, druid portals, zone doors\nParam: none"]
            break
        case UseEverporter
            helpText:Set["Use everporter\nParam: destination"]
            break
        case CastAbility
            helpText:Set["Cast ability\nParam: ability name"]
            break
        case CastAbilityOnPlayer
            helpText:Set["Cast on player\nParam: ability,player"]
            break
        case UseItem
            helpText:Set["Use item\nParam: item name"]
            break
        case UseItemOnActor
            helpText:Set["Use item on actor\nParam: item,actor"]
            break
        case CheckQuestStep
            helpText:Set["Check quest step\nParam: quest,step"]
            break
        case HaveQuest
            helpText:Set["Check if have quest\nParam: quest name"]
            break
        case DumpAll
            helpText:Set["Dump to depots\nParam: none"]
            break
        case ZoneReset
            helpText:Set["Reset zone instance\nParam: zone (blank=current)"]
            break
        case Loop
            helpText:Set["Loop path N times\nParam: number"]
            break
        case LoopUntilFaction
            helpText:Set["Loop quest path until faction reaches target amount\nUses Get_Faction() to check faction level\nParam: FactionName,TargetAmount (e.g. \"Gorowyn,40000\")\nOptional: FactionName,TargetAmount,MaxLoops (e.g. \"Gorowyn,40000,50\")"]
            break
        case Reverse
            helpText:Set["Reverse path\nParam: none"]
            break
        case Custom
            helpText:Set["Custom command\nParam: any LavishScript"]
            break
        case ChangeOgreBotUIOption
            helpText:Set["Change bot setting\nParam: option,value"]
            break
        case RepairGear
            helpText:Set["Auto repair gear\nParam: none"]
            break
        case OpenAndBuyFromMerchant
            helpText:Set["Buy from merchant multiple times\nParam: ForWho,Merchant,Item,Qty,Times (e.g. all,MerchantName,ItemName,1,5)"]
            break
        case LandFlyingMount
            helpText:Set["Land flying mount\nParam: ForWho (e.g. all, mage, priest)"]
            break
        case CheckPackPony
            helpText:Set["Check pack pony status\nParam: ForWho (optional)"]
            break
        case CheckMercenaryTraining
            helpText:Set["Check merc training\nParam: ForWho (optional)"]
            break
        case SpewZoneDoorOptions
            helpText:Set["Show available zone doors\nParam: none"]
            break
        case EnableStuns
            helpText:Set["Enable stuns for group\nParam: ForWho (optional)"]
            break
        case DisableStuns
            helpText:Set["Disable stuns for group\nParam: ForWho (optional)"]
            break
        case EnableInterrupts
            helpText:Set["Enable interrupts\nParam: ForWho (optional)"]
            break
        case DisableInterrupts
            helpText:Set["Disable interrupts\nParam: ForWho (optional)"]
            break
        case EnableCures
            helpText:Set["Enable cures\nParam: ForWho (optional)"]
            break
        case DisableCures
            helpText:Set["Disable cures\nParam: ForWho (optional)"]
            break
        case EnableDispells
            helpText:Set["Enable dispells\nParam: ForWho (optional)"]
            break
        case DisableDispells
            helpText:Set["Disable dispells\nParam: ForWho (optional)"]
            break
        case DisableAllAOEs
            helpText:Set["Disable all AOE abilities\nParam: ForWho (optional)"]
            break
        case EnableAllAOEs
            helpText:Set["Enable all AOE abilities\nParam: ForWho (optional)"]
            break
        case HOEnableAll
            helpText:Set["Enable HO for all classes\nParam: none"]
            break
        case HODisable
            helpText:Set["Disable HO for all\nParam: none"]
            break
        case HOScoutOnly
            helpText:Set["Only scouts do HO\nParam: none"]
            break
        case HOPriestOnly
            helpText:Set["Only priests do HO\nParam: none"]
            break
        case HOMageOnly
            helpText:Set["Only mages do HO\nParam: none"]
            break
        case HOFighterOnly
            helpText:Set["Only fighters do HO\nParam: none"]
            break
        case WaitForNPCAlive
            helpText:Set["Wait for NPC spawn (excludes corpses)\nParam: NPCName"]
            break
        case AutoTargetAddActor
            helpText:Set["Add actor to AutoTarget list\nParam: ActorName,HP,CheckCollision,AggroOnGroup (e.g. a trash mob,0,FALSE,TRUE)"]
            break
        case AutoTargetRemoveActor
            helpText:Set["Remove actor from AutoTarget\nParam: ActorName"]
            break
        case AutoTargetClear
            helpText:Set["Clear all AutoTarget actors\nParam: none"]
            break
        case AutoTargetEnable
            helpText:Set["Enable AutoTarget system\nParam: none"]
            break
        case AutoTargetDisable
            helpText:Set["Disable AutoTarget system\nParam: none"]
            break
        case Jump
            helpText:Set["Make character jump\nParam: ForWho (optional)"]
            break
        case Special
            helpText:Set["Use Special action (zone portals)\nParam: ForWho (optional)"]
            break
        case CS_ClearAll
            helpText:Set["Clear all camp spots\nParam: ForWho (optional)"]
            break
        case ClearAbilityQueue
            helpText:Set["Clear ability queue\nParam: ForWho (optional)"]
            break
        case CancelSpellcast
            helpText:Set["Cancel current spellcast\nParam: ForWho (optional)"]
            break
        case RawCommandOB
            helpText:Set["Execute raw OgreBot command\nParam: ForWho,Command (e.g. all,eq2execute /sit)"]
            break
        case CheckDetriment
            helpText:Set["Check if actor has detriment (logs to console)\nParam: ActorName,DetrimentID (e.g. Boss Name,33085)\nUse to verify boss debuffs before proceeding\nNote: For conditional execution based on result, pair with manual monitoring"]
            break
        case CheckDetrimentStacks
            helpText:Set["Check detriment stack count in range (logs result)\nParam: ActorName,DetrimentID,MinStacks,MaxStacks\nExample: Boss,33085,1,7 for Lavatar positioning\nUse with ChangeCampSpotWho commands to position based on stacks\nNote: Manual review of logs needed for conditional execution"]
            break
        case WaitForQuestOffered
            helpText:Set["Wait for quest offered window\nParam: QuestName (optional, blank=any quest)"]
            break
        case CheckChoiceWindow
            helpText:Set["Check if choice window has specific text\nParam: TextToFind (e.g. Would you like to loot)"]
            break
        case WaitForChatText
            helpText:Set["Wait for specific chat message\nParam: TextToFind"]
            break
        case Mount
        case Dismount
        case Evac
        case Resume
        case Pause
        case FlyUp
        case FlyDown
        case FlyStop
        case ResetCameraAngle
        case ClearCampSpot
        case WaitForZoning
        case ReplyDialogClose
        case DisableCombat
        case EnableCombat
        case MoveToActor
        case OffersQuest
        case HaveQuestCompleted
        case GetSpecificQuestFromNPC
            helpText:Set["${cmdName}\nParam: none or optional"]
            break
        default
            helpText:Set["${cmdName}\nParam: varies"]
    }

    UIElement[${JBUI_Mapper_ParamHelp_Text}]:SetText["${helpText.Escape}"]
}

atom(script) JBUI_Mapper_InsertSelectedCommand()
{
    if !${UIElement[${JBUI_Mapper_CommandList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Select a command first"]
        return
    }

    variable string cmdName = "${UIElement[${JBUI_Mapper_CommandList}].SelectedItem.Text}"

    ; Skip category headers
    if ${cmdName.Find["---"]}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Select a command, not category"]
        return
    }

    ; Call the existing insert atom with the command name
    Script[JB_UI_Simple]:ExecuteAtom[JBUI_Mapper_InsertCommand,"${cmdName}"]
}

; ============================================================================
; Tab Switching Function
; ============================================================================

atom(script) JBUI_Mapper_SwitchTab(string tabName)
{
    ; Hide all tab panels
    UIElement[${JBUI_MapperControls_Frame}]:Hide
    UIElement[${JBUI_MapperCommands_Frame}]:Hide
    UIElement[${JBUI_MapperActorInspector_Frame}]:Hide
    UIElement[${JBUI_MapperPlayback_Frame}]:Hide
    UIElement[${JBUI_MapperZoneTravel_Frame}]:Hide

    ; Reset all tab button colors to white
    UIElement[${JBUI_MapperTab_Recording}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_MapperTab_Commands}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_MapperTab_Actors}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_MapperTab_Playback}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_MapperTab_ZoneTravel}].Font:SetColor[FFFFFFFF]

    ; Show the selected tab panel and highlight its button
    switch ${tabName}
    {
        case Recording
            UIElement[${JBUI_MapperControls_Frame}]:Show
            UIElement[${JBUI_MapperTab_Recording}].Font:SetColor[FF00FF00]
            break
        case Commands
            UIElement[${JBUI_MapperCommands_Frame}]:Show
            UIElement[${JBUI_MapperTab_Commands}].Font:SetColor[FF00FF00]
            break
        case Actors
            UIElement[${JBUI_MapperActorInspector_Frame}]:Show
            UIElement[${JBUI_MapperTab_Actors}].Font:SetColor[FF00FF00]
            break
        case Playback
            UIElement[${JBUI_MapperPlayback_Frame}]:Show
            UIElement[${JBUI_MapperTab_Playback}].Font:SetColor[FF00FF00]
            break
        case ZoneTravel
            UIElement[${JBUI_MapperZoneTravel_Frame}]:Show
            UIElement[${JBUI_MapperTab_ZoneTravel}].Font:SetColor[FF00FF00]
            break
    }

    JBUI_Mapper_CurrentTab:Set["${tabName}"]
    if ${JBUI_DebugMode}
        echo [Mapper] Switched to ${tabName} tab
}

; ============================================================================
; PLAYBACK SYSTEM
; ============================================================================

function JBUI_Playback_ReadAndCountFile()
{
    ; Helper function to read file and count waypoints and commands
    ; Sets global variables JBUI_Playback_WaypointCount and JBUI_Playback_CommandCount
    ; Reads from global variable JBUI_Playback_PathFile

    variable int wpCount = 0
    variable int cmdCount = 0
    variable file f
    variable string line

    ; Read XML file line by line
    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    while !${f.EOF}
    {
        ; Read line ONCE per iteration (don't check exists, just read)
        line:Set["${f.Read}"]
        if ${line.Length} > 0
        {
            ; Note: space after tag name to avoid matching <Waypoints> or <Commands>
            if ${line.Find["<Waypoint "]}
                wpCount:Inc
            if ${line.Find["<Command "]}
                cmdCount:Inc
        }
    }

    f:Close

    JBUI_Playback_WaypointCount:Set[${wpCount}]
    JBUI_Playback_CommandCount:Set[${cmdCount}]
}

function JBUI_Playback_ParseEventTriggers()
{
    ; Parse EventTrigger and Action blocks from XML file
    ; This is called after ReadAndCountFile to set up event system

    variable file f
    variable string line
    variable bool inActionBlock = FALSE
    variable string currentActionName = ""

    echo [EventSystem] Parsing event triggers and actions from: ${JBUI_Playback_PathFile}

    ; Clear any existing events/actions
    call JB_Event_Clear
    call JB_Action_Clear
    call JB_StateVar_Clear

    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    while !${f.EOF}
    {
        if !${f.Read(exists)}
            continue

        line:Set["${f.Read}"]
        if ${line.Length} == 0
            continue

        ; Parse EventTrigger tags
        if ${line.Find["<EventTrigger "]}
        {
            call JBUI_Playback_ParseEventTriggerLine "${line}"
        }

        ; Parse Action block start
        if ${line.Find["<Action "]} && ${line.Find["Name="]}
        {
            ; Extract action name
            variable int nameStart = ${line.Find["Name=\""]}
            if ${nameStart} > 0
            {
                nameStart:Set[${Math.Calc[${nameStart} + 6]}]
                variable int nameEnd = ${line.Find[nameStart,"\""]}
                currentActionName:Set["${line.Mid[${nameStart},${Math.Calc[${nameEnd} - ${nameStart}]}]}"]
                inActionBlock:Set[TRUE]
                call JB_Action_Start "${currentActionName}"
            }
        }

        ; Parse Action block end
        if ${line.Find["</Action>"]}
        {
            inActionBlock:Set[FALSE]
            currentActionName:Set[""]
        }

        ; If we're in an action block, add waypoints/commands to it
        if ${inActionBlock}
        {
            if ${line.Find["<Waypoint "]} || ${line.Find["<Command "]}
            {
                call JB_Action_AddCommand "${currentActionName}" "${line}"
            }
        }
    }

    f:Close
    echo [EventSystem] Parsed ${JB_Event_Count} event triggers and ${JB_Action_Count} action blocks
}

function JBUI_Playback_ParseEventTriggerLine(string xmlLine)
{
    ; Parse a single <EventTrigger> line and register it
    variable string eventType
    variable string matchText
    variable string actionName
    variable bool oneShot = FALSE

    ; Extract Type
    variable int typeStart = ${xmlLine.Find["Type=\""]}
    if ${typeStart} > 0
    {
        typeStart:Set[${Math.Calc[${typeStart} + 6]}]
        variable int typeEnd = ${xmlLine.Find[typeStart,"\""]}
        eventType:Set["${xmlLine.Mid[${typeStart},${Math.Calc[${typeEnd} - ${typeStart}]}]}"]
    }

    ; Extract Match (if exists)
    variable int matchStart = ${xmlLine.Find["Match=\""]}
    if ${matchStart} > 0
    {
        matchStart:Set[${Math.Calc[${matchStart} + 7]}]
        variable int matchEnd = ${xmlLine.Find[matchStart,"\""]}
        matchText:Set["${xmlLine.Mid[${matchStart},${Math.Calc[${matchEnd} - ${matchStart}]}]}"]
    }

    ; Extract Action
    variable int actionStart = ${xmlLine.Find["Action=\""]}
    if ${actionStart} > 0
    {
        actionStart:Set[${Math.Calc[${actionStart} + 8]}]
        variable int actionEnd = ${xmlLine.Find[actionStart,"\""]}
        actionName:Set["${xmlLine.Mid[${actionStart},${Math.Calc[${actionEnd} - ${actionStart}]}]}"]
    }

    ; Extract OneShot (optional)
    if ${xmlLine.Find["OneShot=\"true\""]} || ${xmlLine.Find["OneShot=\"TRUE\""]}
        oneShot:Set[TRUE]

    ; Handle different event types
    if ${eventType.Equal["ChatText"]} || ${eventType.Equal["ActorSpawn"]} || ${eventType.Equal["ActorDeath"]}
    {
        call JB_Event_Register "${eventType}" "${matchText}" "${actionName}" ${oneShot}
    }
    elseif ${eventType.Equal["DetrimentalStacks"]}
    {
        ; Extract additional parameters for DetrimentalStacks
        variable string actorName
        variable int mainID = 0
        variable int backdropID = 0
        variable int highStacks = 0
        variable int lowStacks = 0

        ; Extract Actor
        variable int actorStart = ${xmlLine.Find["Actor=\""]}
        if ${actorStart} > 0
        {
            actorStart:Set[${Math.Calc[${actorStart} + 7]}]
            variable int actorEnd = ${xmlLine.Find[actorStart,"\""]}
            actorName:Set["${xmlLine.Mid[${actorStart},${Math.Calc[${actorEnd} - ${actorStart}]}]}"]
        }

        ; Extract MainID
        variable int mainStart = ${xmlLine.Find["MainID=\""]}
        if ${mainStart} > 0
        {
            mainStart:Set[${Math.Calc[${mainStart} + 8]}]
            variable int mainEnd = ${xmlLine.Find[mainStart,"\""]}
            mainID:Set[${xmlLine.Mid[${mainStart},${Math.Calc[${mainEnd} - ${mainStart}]}]}]
        }

        ; Extract BackdropID
        variable int bdStart = ${xmlLine.Find["BackdropID=\""]}
        if ${bdStart} > 0
        {
            bdStart:Set[${Math.Calc[${bdStart} + 12]}]
            variable int bdEnd = ${xmlLine.Find[bdStart,"\""]}
            backdropID:Set[${xmlLine.Mid[${bdStart},${Math.Calc[${bdEnd} - ${bdStart}]}]}]
        }

        ; Extract HighStacks
        variable int hsStart = ${xmlLine.Find["HighStacks=\""]}
        if ${hsStart} > 0
        {
            hsStart:Set[${Math.Calc[${hsStart} + 12]}]
            variable int hsEnd = ${xmlLine.Find[hsStart,"\""]}
            highStacks:Set[${xmlLine.Mid[${hsStart},${Math.Calc[${hsEnd} - ${hsStart}]}]}]
        }

        ; Extract LowStacks
        variable int lsStart = ${xmlLine.Find["LowStacks=\""]}
        if ${lsStart} > 0
        {
            lsStart:Set[${Math.Calc[${lsStart} + 11]}]
            variable int lsEnd = ${xmlLine.Find[lsStart,"\""]}
            lowStacks:Set[${xmlLine.Mid[${lsStart},${Math.Calc[${lsEnd} - ${lsStart}]}]}]
        }

        call JB_Event_Register_DetrimentalStacks "${actorName}" ${mainID} ${backdropID} ${highStacks} ${lowStacks} "${actionName}"
    }
}

atom(script) JBUI_Playback_LoadPath()
{
    variable string pathFile = "${UIElement[${JBUI_Playback_PathFile_TextEntry}].Text}"

    if ${pathFile.Length} == 0
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Enter a path file to load"]
        return
    }

    ; Check if file is XML
    if !${pathFile.Find[".xml"]}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Only XML files are supported for playback"]
        return
    }

    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loading path file: ${pathFile}"]

    JBUI_Playback_PathFile:Set["${pathFile}"]
    call JBUI_Playback_ReadAndCountFile
    call JBUI_Playback_ParseEventTriggers

    JBUI_Playback_TotalItems:Set[${Math.Calc[${JBUI_Playback_WaypointCount} + ${JBUI_Playback_CommandCount}]}]
    JBUI_Playback_CurrentIndex:Set[0]
    JBUI_Playback_PathFile:Set["${pathFile}"]
    JBUI_Playback_Loaded:Set[TRUE]

    UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: 0 / ${JBUI_Playback_TotalItems}"]
    UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Path loaded"]
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["SUCCESS: Loaded ${JBUI_Playback_WaypointCount} waypoints and ${JBUI_Playback_CommandCount} commands"]

    if ${JB_Event_Count} > 0 || ${JB_Action_Count} > 0
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Event System: ${JB_Event_Count} triggers, ${JB_Action_Count} actions"]
    }

    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Total items: ${JBUI_Playback_TotalItems}"]

    echo [Playback] Loaded path: ${pathFile} (${JBUI_Playback_TotalItems} items)
}

atom(script) JBUI_Playback_Play()
{
    if !${JBUI_Playback_Loaded}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Load a path file first"]
        return
    }

    if ${JBUI_Playback_IsPlaying}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Playback already running"]
        return
    }

    JBUI_Playback_IsPlaying:Set[TRUE]
    JBUI_Playback_IsPaused:Set[FALSE]

    ; Clear stuck location blacklist for fresh playback
    JBUI_Stuck_Count:Set[0]
    echo [Playback] Cleared blacklist - fresh run

    ; Start event system if we have events/actions
    if ${JB_Event_Count} > 0 || ${JB_Action_Count} > 0
    {
        call JB_EventSystem_Start
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Event System: Started (${JB_Event_Count} triggers)"]
    }

    ; Launch Thread #3 - Non-blocking playback processor
    if !${Script[JB_UI_Playback](exists)}
    {
        run "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JB_UI_Playback.iss"
        echo [Playback] Launched playback thread (Thread #3) - UI will stay responsive!
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Thread #3: Started (non-blocking)"]
    }
    else
    {
        echo [Playback] Playback thread already running - resuming
    }

    ; Update button states
    UIElement[${JBUI_Playback_PlayButton}].Font:SetColor[FF888888]
    UIElement[${JBUI_Playback_PauseButton}].Font:SetColor[FFFFFF00]
    UIElement[${JBUI_Playback_StopButton}].Font:SetColor[FFFF0000]

    UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Playing..."]
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["=== PLAYBACK STARTED ==="]

    if ${UIElement[${JBUI_LoopPath_Checkbox}].Checked}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loop mode: ENABLED"]
    }

    echo [Playback] Started playback (${JBUI_Playback_TotalItems} items)
}

atom(script) JBUI_Playback_Pause()
{
    if !${JBUI_Playback_IsPlaying}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: No playback running"]
        return
    }

    if ${JBUI_Playback_IsPaused}
    {
        ; Unpause
        JBUI_Playback_IsPaused:Set[FALSE]
        UIElement[${JBUI_Playback_PauseButton}].Font:SetColor[FFFFFF00]
        UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Resumed..."]
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Playback RESUMED at item ${JBUI_Playback_CurrentIndex}"]
        echo [Playback] Resumed
    }
    else
    {
        ; Pause
        JBUI_Playback_IsPaused:Set[TRUE]
        UIElement[${JBUI_Playback_PauseButton}].Font:SetColor[FFFFA500]
        UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["PAUSED"]
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Playback PAUSED at item ${JBUI_Playback_CurrentIndex}"]
        echo [Playback] Paused at item ${JBUI_Playback_CurrentIndex}
    }
}

atom(script) JBUI_Playback_Stop()
{
    if !${JBUI_Playback_IsPlaying}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["No playback to stop"]
        return
    }

    JBUI_Playback_IsPlaying:Set[FALSE]
    JBUI_Playback_IsPaused:Set[FALSE]
    JBUI_Playback_CurrentIndex:Set[0]

    ; Stop Thread #3 - Playback processor
    if ${Script[JB_UI_Playback](exists)}
    {
        Script[JB_UI_Playback]:End
        echo [Playback] Stopped playback thread (Thread #3)
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Thread #3: Stopped"]
    }

    ; Stop event system
    if ${JB_Event_Count} > 0 || ${JB_Action_Count} > 0
    {
        call JB_EventSystem_Stop
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Event System: Stopped"]
    }

    ; Cancel any active movement and stop autorun
    JBUI_Movement_Active:Set[FALSE]

    ; Call navigation library to properly release all movement keys
    if ${Obj_JBUINav(exists)}
    {
        call Obj_JBUINav.StopMovement
        echo [Playback] Released all movement keys via JNavigation
    }

    ; Turn off autorun if character is moving
    if ${Me.IsMoving}
    {
        press "num lock"
    }

    ; Fallback: Release keys directly (in case navigation lib has issues)
    press -release w
    press -release a
    press -release s
    press -release d

    ; Reset button states
    UIElement[${JBUI_Playback_PlayButton}].Font:SetColor[FF00FF00]
    UIElement[${JBUI_Playback_PauseButton}].Font:SetColor[FFFFFF00]
    UIElement[${JBUI_Playback_StopButton}].Font:SetColor[FFFF0000]

    ; Reset progress display
    UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: 0 / ${JBUI_Playback_TotalItems}"]
    UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Stopped"]
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["=== PLAYBACK STOPPED ==="]

    echo [Playback] Stopped and reset
}

function JBUI_Playback_ProcessNext()
{
    if !${JBUI_Playback_IsPlaying} || ${JBUI_Playback_IsPaused}
        return

    ; Check events (ActorSpawn, ActorDeath, DetrimentalStacks)
    ; ChatText events are handled by the atom
    if ${JB_Event_Count} > 0
    {
        call JB_Event_CheckAll
    }

    ; Check if we've finished all items
    if ${JBUI_Playback_CurrentIndex} >= ${JBUI_Playback_TotalItems}
    {
        ; Check loop setting
        if ${UIElement[${JBUI_LoopPath_Checkbox}].Checked}
        {
            JBUI_Playback_CurrentIndex:Set[0]
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Loop: Restarting path from beginning"]
            echo [Playback] Looping path
        }
        else
        {
            ; Finished - stop playback
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["=== PLAYBACK COMPLETED ==="]
            Script[JB_UI_Simple]:ExecuteAtom[JBUI_Playback_Stop]
            return
        }
    }

    ; Read file and extract item at CurrentIndex
    variable bool foundItem = FALSE
    variable string itemType
    variable string itemData
    variable string fileContents
    variable file f
    variable string line
    variable int currentItem = 0

    ; Read XML file line by line
    f:SetFilename["${JBUI_Playback_PathFile}"]
    f:Open[readonly]

    while !${f.EOF} && !${foundItem}
    {
        ; Read line ONCE per iteration
        line:Set["${f.Read}"]
        if ${line.Length}
        {
            ; Check if this is a waypoint or command line (note the space after tag name)
            if ${line.Find["<Waypoint "]} || ${line.Find["<Command "]}
            {
                if ${currentItem} == ${JBUI_Playback_CurrentIndex}
                {
                    foundItem:Set[TRUE]
                    itemData:Set["${line}"]

                    if ${line.Find["<Waypoint "]}
                        itemType:Set["waypoint"]
                    else
                        itemType:Set["command"]
                }
                currentItem:Inc
            }
        }
    }

    f:Close

    if !${foundItem}
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Could not find item at index ${JBUI_Playback_CurrentIndex}"]
        JBUI_Playback_CurrentIndex:Inc
        return
    }

    ; Check if this is the FINAL item in the path
    ; CurrentIndex is 0-based, so if CurrentIndex+1 == TotalItems, this is the last one
    if ${Math.Calc[${JBUI_Playback_CurrentIndex}+1]} == ${JBUI_Playback_TotalItems}
    {
        JBUI_Movement_IsFinalWaypoint:Set[TRUE]
        echo [Playback] This is the FINAL waypoint - using high precision (0.5m)
    }
    else
    {
        JBUI_Movement_IsFinalWaypoint:Set[FALSE]
    }

    ; Execute the item based on type
    if ${itemType.Equal["waypoint"]}
    {
        call JBUI_Playback_ExecuteWaypoint "${itemData}"
    }
    else
    {
        call JBUI_Playback_ExecuteCommand "${itemData}"
    }

    ; Update progress display
    JBUI_Playback_CurrentIndex:Inc
    UIElement[${JBUI_CurrentWaypoint_Inline_Text}]:SetText["Waypoint: ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}"]

    echo [Playback] Processed item ${JBUI_Playback_CurrentIndex} / ${JBUI_Playback_TotalItems}
}

function JBUI_Playback_ExecuteWaypoint(string xmlLine)
{
    echo [Playback] ExecuteWaypoint called with: ${xmlLine}
    echo [Playback] xmlLine length: ${xmlLine.Length}

    ; Parse waypoint XML: <Waypoint X="..." Y="..." Z="..." />
    variable string xVal
    variable string yVal
    variable string zVal

    ; Use Token-based extraction with quotes as delimiters
    ; Format: <Waypoint X="VALUE" Y="VALUE" Z="VALUE" />
    ; Token 1 with " is empty, Token 2 is X value, Token 4 is Y value, Token 6 is Z value

    variable int tokenCount = ${xmlLine.Count["\""]}
    echo [Playback] Quote count: ${tokenCount}

    if ${tokenCount} >= 6
    {
        xVal:Set["${xmlLine.Token[2,"\""]}"]
        yVal:Set["${xmlLine.Token[4,"\""]}"]
        zVal:Set["${xmlLine.Token[6,"\""]}"]
    }

    echo [Playback] xVal: ${xVal} (length: ${xVal.Length})
    echo [Playback] yVal: ${yVal} (length: ${yVal.Length})
    echo [Playback] zVal: ${zVal} (length: ${zVal.Length})

    echo [Playback] Checking if all coords exist: x=${xVal.Length}, y=${yVal.Length}, z=${zVal.Length}
    if ${xVal.Length} > 0 && ${yVal.Length} > 0 && ${zVal.Length} > 0
    {
        ; Navigate to waypoint using direct movement
        variable point3f waypointLoc
        waypointLoc.X:Set[${xVal}]
        waypointLoc.Y:Set[${yVal}]
        waypointLoc.Z:Set[${zVal}]

        echo [Playback] Parsed coordinates: X=${xVal}, Y=${yVal}, Z=${zVal}
        echo [Playback] Current location: ${Me.Loc}
        echo [Playback] Target location: ${waypointLoc}
        echo [Playback] Distance: ${Math.Distance[${Me.Loc},${waypointLoc}]}

        UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Moving to ${xVal},${yVal},${zVal}"]
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Waypoint: ${xVal}, ${yVal}, ${zVal}"]

        ; Call the improved movement function
        call JBUI_Playback_MoveToLocation ${xVal} ${yVal} ${zVal}
    }
    else
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Failed to parse waypoint coordinates"]
    }
}

; Check if a command type requires stopping movement
function:bool JBUI_Command_RequiresStop(string cmdType)
{
    ; Interactive commands that need the character to stop
    switch ${cmdType}
    {
        case ClickActor
        case HailActor
        case TargetActor
        case WaitForActor
        case WaitForNPCAlive
        case ApplyVerb
        case InteractActor
        case ConversationBubble
        case ReplyDialog
        case ReplyDialogClose
        case ChoiceWindow
        case GetToZone
        case WaitForZoning
        case WaitForZoned
        case ZoneDoor
        case Door
        case TravelBell
        case TravelDruid
        case TravelSpire
        case HaveQuest
        case CheckQuestStep
        case HaveQuestCompleted
        case OffersQuest
        case GetSpecificQuestFromNPC
        case WaitForQuestOffered
        case CheckChoiceWindow
        case WaitForChatText
        case CampSpot
        case ChangeCampSpot
        case ChangeCampSpotWho
        case CampSpotAutoPosition
        case CampSpotAutoNPC
        case CampSpotJoustOut
        case CampSpotJoustIn
        case ClearCampSpot
        case MoveToPerson
        case MoveToArea
        case Evac
            return TRUE
        default
            return FALSE
    }
}

function JBUI_Playback_ExecuteCommand(string xmlLine)
{
    ; Parse command XML: <Command Type="..." Value="..." /> or <Command Type="..." />
    variable string cmdType
    variable string cmdValue

    ; Extract Type
    variable int typeStart = ${xmlLine.Find["Type=\""]}
    if ${typeStart} > 0
    {
        typeStart:Set[${Math.Calc[${typeStart} + 6]}]
        variable int typeEnd = ${xmlLine.Find[typeStart,"\""]}
        cmdType:Set["${xmlLine.Mid[${typeStart},${Math.Calc[${typeEnd} - ${typeStart}]}]}"]
    }

    ; Extract Value (if exists)
    variable int valStart = ${xmlLine.Find["Value=\""]}
    if ${valStart} > 0
    {
        valStart:Set[${Math.Calc[${valStart} + 7]}]
        variable int valEnd = ${xmlLine.Find[valStart,"\""]}
        cmdValue:Set["${xmlLine.Mid[${valStart},${Math.Calc[${valEnd} - ${valStart}]}]}"]
    }

    if ${cmdType.Length} == 0
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Failed to parse command type"]
        return
    }

    ; Stop movement if this command requires it
    if ${JBUI_Command_RequiresStop["${cmdType}"]}
    {
        echo [Playback] Command "${cmdType}" requires stopping movement
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Stopping for command: ${cmdType}"]

        ; Call navigation library to stop all movement
        if ${Obj_JBUINav(exists)}
        {
            call Obj_JBUINav.StopMovement
        }

        ; Cancel any active movement request
        JBUI_Movement_Active:Set[FALSE]
    }

    UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["${cmdType}"]
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Command: ${cmdType} ${cmdValue}"]

    ; Execute command based on type
    switch ${cmdType}
    {
        case Wait
            variable int waitTime = ${cmdValue}
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Waiting ${waitTime} deciseconds (${Math.Calc[${waitTime} / 10]} seconds)"]
            wait ${waitTime}
            break

        case ChangeCampSpot
            ; Parse X,Y,Z from value
            variable string coords = "${cmdValue}"
            relay all oc !ci -ChangeCampSpot ${coords.Token[1,","]} ${coords.Token[2,","]} ${coords.Token[3,","]} igw:${Me.Name}
            wait 10
            break

        case ChangeCampSpotWho
            ; Parse ForWho,X,Y,Z from value
            variable string forWho = "${cmdValue.Token[1,","]}"
            relay ${forWho} oc !ci -ChangeCampSpot ${cmdValue.Token[2,","]} ${cmdValue.Token[3,","]} ${cmdValue.Token[4,","]} igw:${Me.Name}
            wait 10
            break

        case ConversationBubble
            ; Support multiple dialog options in sequence
            ; Format: "1,2,1,3,4:20" = options 1,2,1,3,4 with 20 deci-seconds between each
            ; Or: "1,2,3" = options with default 20 deci-second wait

            variable int waitBetween = 20  ; Default 2 seconds between options
            variable string optionSequence = "${cmdValue}"

            ; Check if wait time is specified (after colon)
            if ${cmdValue.Find[":"]}
            {
                ; Extract options before colon
                optionSequence:Set["${cmdValue.Token[1,":"]}"]
                ; Extract wait time after colon
                waitBetween:Set[${cmdValue.Token[2,":"]}]
            }

            ; Count how many options (tokens separated by comma)
            variable int optionCount = 1
            variable int tempIdx
            for (tempIdx:Set[0]; ${tempIdx} < ${optionSequence.Length}; tempIdx:Inc)
            {
                if ${optionSequence.Mid[${tempIdx},1].Equal[","]}
                    optionCount:Inc
            }

            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ConversationBubble: ${optionCount} options, ${waitBetween}ds between"]

            ; Execute each option in sequence
            variable int optIdx
            for (optIdx:Set[1]; ${optIdx} <= ${optionCount}; optIdx:Inc)
            {
                if !${JBUI_Playback_IsPlaying} || ${JBUI_Playback_IsPaused}
                    break

                variable int currentOption = ${optionSequence.Token[${optIdx},","]}
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["  Option ${optIdx}/${optionCount}: ${currentOption}"]

                relay all eq2execute ConversationBubble ${currentOption}

                ; Wait between options (but not after the last one)
                if ${optIdx} < ${optionCount}
                    wait ${waitBetween}
            }

            ; Small final wait to let dialog close
            wait 5
            break

        case CampSpotAutoPosition
            ; Auto position with ForWho parameter
            relay ${cmdValue} oc !ci -cs auto igw:${Me.Name}
            wait 10
            break

        case CampSpotAutoNPC
            ; Auto position around NPC (tank in front, others behind)
            relay all oc !ci -cs auto -setcs_positionnpc igw:${Me.Name}
            wait 10
            break

        case CampSpotJoustOut
            ; Joust out from camp spot
            relay all oc !ci -cs-jo igw:${Me.Name}
            wait 10
            break

        case CampSpotJoustIn
            ; Joust back to camp spot
            relay all oc !ci -cs-ji igw:${Me.Name}
            wait 10
            break

        case MoveToPerson
            ; Parse WhoMoves,WhoToMoveTo,Precision
            variable string whoMoves = "${cmdValue.Token[1,","]}"
            variable string moveToWho = "${cmdValue.Token[2,","]}"
            variable float precision = ${cmdValue.Token[3,","]}
            if ${precision} <= 0
                precision:Set[5]
            relay all oc !c -a_OgreBotMoveToPerson ${moveToWho} ${whoMoves} ${precision}
            wait 10
            break

        case MoveToArea
            ; Parse WhoMoves,X,Y,Precision
            variable string whoMoves2 = "${cmdValue.Token[1,","]}"
            variable float xPos = ${cmdValue.Token[2,","]}
            variable float yPos = ${cmdValue.Token[3,","]}
            variable float precision2 = ${cmdValue.Token[4,","]}
            if ${precision2} <= 0
                precision2:Set[5]
            relay all oc !c -a_OgreBotMoveToArea ${xPos} ${yPos} ${whoMoves2} ${precision2}
            wait 10
            break

        case ClickNPC
        case HailNPC
        case DoubleClickNPC
            relay all oc !ci -${cmdType} ${cmdValue} igw:${Me.Name}
            wait 10
            break

        case AutoTargetAddActor
            ; Parse ActorName,HP,CheckCollision,AggroOnGroup
            relay all oc !ci -AutoTargetAddActor ${cmdValue.Token[1,","]} ${cmdValue.Token[2,","]} ${cmdValue.Token[3,","]} ${cmdValue.Token[4,","]} igw:${Me.Name}
            wait 5
            break

        case WaitForQuestOffered
            ; Wait for quest dialog to appear
            variable string questName = "${cmdValue}"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Waiting for quest: ${questName}"]

            ; Wait up to 300 deciseconds (30 seconds)
            variable int waitCount = 0
            while ${waitCount} < 300
            {
                if ${EQ2.QuestInstructions(exists)}
                {
                    ; If specific quest name provided, check it matches
                    if ${questName.Length} > 0
                    {
                        if ${EQ2.QuestInstructions.Find["${questName}"]}
                        {
                            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Quest offered: ${questName}"]
                            break
                        }
                    }
                    else
                    {
                        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Quest offered"]
                        break
                    }
                }

                if !${JBUI_Playback_IsPlaying} || ${JBUI_Playback_IsPaused}
                    break

                wait 5
                waitCount:Inc[5]
            }
            break

        case CheckChoiceWindow
            ; Check if choice window contains specific text
            variable string searchText = "${cmdValue}"

            if ${EQ2.ChoiceWindowText(exists)}
            {
                if ${EQ2.ChoiceWindowText.Find["${searchText}"]}
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Choice window found: ${searchText}"]
                }
                else
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Choice window open but text not found: ${searchText}"]
                }
            }
            else
            {
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["No choice window open"]
            }
            wait 5
            break

        case WaitForChatText
            ; Wait for specific chat message to appear
            variable string chatText = "${cmdValue}"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Waiting for chat: ${chatText}"]

            ; This would need event atom integration
            ; For now, just wait a fixed time as placeholder
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["NOTE: WaitForChatText needs event atom integration"]
            wait 50
            break

        case CheckDetriment
            ; Check if actor has specific detriment
            ; Parse: ActorName,DetrimentID
            variable string actorName = "${cmdValue.Token[1,","]}"
            variable int detrimentID = ${cmdValue.Token[2,","]}

            ; Get actor ID
            variable int actorID = ${Actor[${actorName}].ID}

            if ${actorID} > 0
            {
                ; Check using OgreBotAPI
                variable string detrimentInfo = "${OgreBotAPI.DetrimentalInfo[0,${detrimentID},${actorID},\"CurrentIncrements\"]}"

                if ${detrimentInfo.Length} > 0 && ${detrimentInfo} > 0
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["${actorName} has detriment ${detrimentID}"]
                }
                else
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["${actorName} does NOT have detriment ${detrimentID}"]
                }
            }
            else
            {
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Actor not found: ${actorName}"]
            }
            wait 5
            break

        case CheckDetrimentStacks
            ; Check if detriment stack count is in range
            ; Parse: ActorName,DetrimentID,MinStacks,MaxStacks
            variable string actorName2 = "${cmdValue.Token[1,","]}"
            variable int detrimentID2 = ${cmdValue.Token[2,","]}
            variable int minStacks = ${cmdValue.Token[3,","]}
            variable int maxStacks = ${cmdValue.Token[4,","]}

            ; Get actor ID
            variable int actorID2 = ${Actor[${actorName2}].ID}

            if ${actorID2} > 0
            {
                ; Get current stack count
                variable int stackCount = ${OgreBotAPI.DetrimentalInfo[0,${detrimentID2},${actorID2},\"CurrentIncrements\"]}

                if ${stackCount} >= ${minStacks} && ${stackCount} <= ${maxStacks}
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["${actorName2} detriment ${detrimentID2} stacks: ${stackCount} (in range ${minStacks}-${maxStacks})"]
                }
                else
                {
                    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["${actorName2} detriment ${detrimentID2} stacks: ${stackCount} (OUT of range ${minStacks}-${maxStacks})"]
                }
            }
            else
            {
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Actor not found: ${actorName2}"]
            }
            wait 5
            break

        case AutoTargetClear
        case AutoTargetEnable
        case AutoTargetDisable
        case CS_ClearAll
        case Jump
        case Special
        case ClearAbilityQueue
        case CancelSpellcast
        case HOEnableAll
        case HODisable
        case EnableStuns
        case DisableStuns
        case EnableInterrupts
        case DisableInterrupts
        case EnableCures
        case DisableCures
        case EnableDispells
        case DisableDispells
        case EnableAOEs
        case DisableAOEs
            relay all oc !ci -${cmdType} igw:${Me.Name}
            wait 5
            break

        ; ========== SMART NAVIGATION COMMANDS ==========
        case GoToActor
            ; Navigate to cataloged actor
            ; Parse: ActorName or ActorName,MaxRetries
            variable string actorNameGTA = "${cmdValue.Token[1,","]}"
            variable int maxRetriesGTA = 3
            if ${cmdValue.Find[","]}
                maxRetriesGTA:Set[${cmdValue.Token[2,","]}]

            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["GoToActor: ${actorNameGTA}"]
            call JBUI_Playback_Command_GoToActor "${actorNameGTA}" ${maxRetriesGTA}
            break

        case FindNearest
            ; Find and navigate to nearest actor of type
            ; Parse: ActorType or ActorType,MaxDistance
            variable string actorTypeFN = "${cmdValue.Token[1,","]}"
            variable int maxDistanceFN = 50
            if ${cmdValue.Find[","]}
                maxDistanceFN:Set[${cmdValue.Token[2,","]}]

            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FindNearest: ${actorTypeFN} within ${maxDistanceFN}m"]
            call JBUI_Playback_Command_FindNearest "${actorTypeFN}" ${maxDistanceFN}
            break

        case InteractActor
            ; Navigate to and interact with actor
            ; Parse: ActorName or ActorName,MaxRetries
            variable string actorNameIA = "${cmdValue.Token[1,","]}"
            variable int maxRetriesIA = 3
            if ${cmdValue.Find[","]}
                maxRetriesIA:Set[${cmdValue.Token[2,","]}]

            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["InteractActor: ${actorNameIA}"]
            call JBUI_Playback_Command_InteractActor "${actorNameIA}" ${maxRetriesIA}
            break

        ; ========================================================
        ; PLAYBACK COMMANDS FROM JB_PlaybackCommands.iss
        ; ========================================================

        case Hail
            ; Hail actor with optional conversation/reply selections
            ; Format: "ActorName" or "ActorName,1,2,3" or "ActorName,c1,c2,r1"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Hail: ${cmdValue}"]
            call Cmd_Hail "${cmdValue}"
            break

        case ReplyDialog
            ; Reply dialog with one or more selections
            ; Format: "1" or "1,2,3"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ReplyDialog: ${cmdValue}"]
            call Cmd_ReplyDialog "${cmdValue}"
            break

        case TravelBell
            ; Travel using translocator bells
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["TravelBell: ${cmdValue}"]
            call Cmd_TravelBell "${cmdValue}"
            break

        case TravelSpire
            ; Travel using wizard spires
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["TravelSpire: ${cmdValue}"]
            call Cmd_TravelSpire "${cmdValue}"
            break

        case TravelDruid
            ; Travel using druid rings
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["TravelDruid: ${cmdValue}"]
            call Cmd_TravelDruid "${cmdValue}"
            break

        case ZoneDoor
            ; Use zone door (accepts door name or number)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ZoneDoor: ${cmdValue}"]
            call Cmd_ZoneDoor "${cmdValue}"
            break

        case AcceptQuest
            ; Accept quest
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["AcceptQuest: ${cmdValue}"]
            call Cmd_AcceptQuest "${cmdValue}"
            break

        case RepeatQuestUntilFaction
            ; Repeat quest until faction goal reached
            ; Format: "QuestName,FactionName,TargetValue"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["RepeatQuestUntilFaction: ${cmdValue}"]
            call Cmd_RepeatQuestUntilFaction "${cmdValue}"
            break

        case PortalToGuildHall
            ; Portal to guild hall
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["PortalToGuildHall"]
            call Cmd_PortalToGuildHall
            break

        case WaitForZoned
            ; Wait for zoning to complete
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["WaitForZoned"]
            call Cmd_WaitForZoned
            break

        case WaitWhileCombat
            ; Wait while in combat
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["WaitWhileCombat"]
            call Cmd_WaitWhileCombat
            break

        case DoubleClick
            ; Double click actor
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["DoubleClick: ${cmdValue}"]
            call Cmd_DoubleClick "${cmdValue}"
            break

        case UseItem
            ; Use item from inventory
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["UseItem: ${cmdValue}"]
            call Cmd_UseItem "${cmdValue}"
            break

        case Target
            ; Target actor or clear target
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Target: ${cmdValue}"]
            call Cmd_Target "${cmdValue}"
            break

        case HailAndAcceptQuest
            ; Hail actor and accept quest (simplified command)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["HailAndAcceptQuest: ${cmdValue}"]
            call Cmd_HailAndAcceptQuest "${cmdValue}"
            break

        case CraftItem
            ; Craft an item (simplified crafting)
            ; Format: "RecipeName,quantity" (quantity optional)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["CraftItem: ${cmdValue}"]
            call Cmd_CraftItem "${cmdValue}"
            break

        case ScribeRecipe
            ; Scribe a recipe
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ScribeRecipe: ${cmdValue}"]
            call Cmd_ScribeRecipe "${cmdValue}"
            break

        case ScribeAndCraft
            ; Scribe then craft (for quest recipes)
            ; Format: "RecipeName,quantity" (quantity optional)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ScribeAndCraft: ${cmdValue}"]
            call Cmd_ScribeAndCraft "${cmdValue}"
            break

        case ClickActor
            ; Click an actor (quest items, doors, etc)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ClickActor: ${cmdValue}"]
            call Cmd_ClickActor "${cmdValue}"
            break

        case GatherNode
            ; Gather from a harvest node (single attempt)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["GatherNode: ${cmdValue}"]
            call Cmd_GatherNode "${cmdValue}"
            break

        case GatherNodeUntilUpdate
            ; Gather nodes repeatedly until quest updates
            ; Format: "nodeName,questName,maxAttempts"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["GatherNodeUntilUpdate: ${cmdValue}"]
            call Cmd_GatherNodeUntilUpdate "${cmdValue}"
            break

        case GatherMultipleNodes
            ; Gather from multiple node types until quest updates
            ; Format: "questName,node1;node2;node3,maxAttempts"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["GatherMultipleNodes: ${cmdValue}"]
            call Cmd_GatherMultipleNodes "${cmdValue}"
            break

        case WaitForQuestStep
            ; Wait for quest step to complete
            ; Format: "QuestName,stepText"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["WaitForQuestStep: ${cmdValue}"]
            call Cmd_WaitForQuestStep "${cmdValue}"
            break

        case KillUntilUpdate
            ; Kill NPCs repeatedly until quest updates
            ; Format: "actorName,questName,maxKills"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["KillUntilUpdate: ${cmdValue}"]
            call Cmd_KillUntilUpdate "${cmdValue}"
            break

        case ClickActorUntilUpdate
            ; Click actors repeatedly until quest updates
            ; Format: "actorName,questName,maxClicks"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ClickActorUntilUpdate: ${cmdValue}"]
            call Cmd_ClickActorUntilUpdate "${cmdValue}"
            break

        case CraftUntilUpdate
            ; Craft items repeatedly until quest updates
            ; Format: "recipeName,questName,maxCrafts"
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["CraftUntilUpdate: ${cmdValue}"]
            call Cmd_CraftUntilUpdate "${cmdValue}"
            break

        case FaceActor
            ; Turn character to face an actor
            ; Format: "ActorName" (e.g., "Boss Name")
            ; Uses EQ2 command: /face actorname
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FaceActor: ${cmdValue}"]
            eq2execute /face ${cmdValue}
            wait 5
            break

        case FaceLoc
            ; Turn character to face a location
            ; Format: "X,Y,Z" (e.g., "833.051270,3.236206,-42.215736")
            ; Uses EQ2 command: /face_loc X,Y,Z
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FaceLoc: ${cmdValue}"]
            eq2execute /face_loc ${cmdValue}
            wait 5
            break

        Default
            ; Generic command execution
            if ${cmdValue.Length} > 0
            {
                relay all oc !ci -${cmdType} ${cmdValue} igw:${Me.Name}
            }
            else
            {
                relay all oc !ci -${cmdType} igw:${Me.Name}
            }
            wait 5
            break
    }
}

; ============================================================================
; IMPROVED MOVEMENT FUNCTION
; ============================================================================

function JBUI_Playback_MoveToLocation(float X1, float Y1, float Z1)
{
    ; Sanity check - don't move to 0,0,0
    if ${X1}==0 && ${Y1}==0 && ${Z1}==0
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Invalid waypoint 0,0,0"]
        echo [Playback] ERROR: Invalid waypoint 0,0,0
        return
    }

    ; Check max distance (10km)
    variable point3f targetLoc
    targetLoc.X:Set[${X1}]
    targetLoc.Y:Set[${Y1}]
    targetLoc.Z:Set[${Z1}]

    if ${Math.Distance[${Me.Loc},${targetLoc}]} > 10000
    {
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Waypoint too far (${Math.Distance[${Me.Loc},${targetLoc}]}m)"]
        echo [Playback] ERROR: Waypoint too far (${Math.Distance[${Me.Loc},${targetLoc}]}m)
        return
    }

    echo [Playback] Moving to ${X1}, ${Y1}, ${Z1} (distance: ${Math.Distance[${Me.Loc},${targetLoc}]}m)
    UIElement[${JBUI_CurrentCommand_Inline_Text}]:SetText["Moving to ${X1},${Y1},${Z1}"]

    ; Use separate movement script (can use 'wait' because it's standalone)
    call JBUI_Playback_MoveToPoint ${X1} ${Y1} ${Z1}

    echo [Playback] Arrived at waypoint (final distance: ${Math.Distance[${Me.Loc},${targetLoc}]}m)
}

; Movement using JNavigation object
function JBUI_Playback_MoveToPoint(float X, float Y, float Z)
{
    variable float distance
    variable int waitCounter = 0

    distance:Set[${Math.Distance[${Me.Loc},${X},${Y},${Z}]}]

    ; Check if this waypoint is blacklisted (near a stuck location)
    variable int i
    for (i:Set[0] ; ${i} < ${JBUI_Stuck_Count} ; i:Inc)
    {
        variable float blacklistDist
        blacklistDist:Set[${Math.Distance[${X},${Y},${Z},${JBUI_Stuck_X[${i}]},${JBUI_Stuck_Y[${i}]},${JBUI_Stuck_Z[${i}]}]}]

        if ${blacklistDist} < ${JBUI_Stuck_Blacklist_Radius}
        {
            echo [Playback] SKIPPING waypoint - too close to stuck location #${i} (${blacklistDist.Precision[1]}m away)
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["SKIPPED - near stuck zone"]
            return
        }
    }

    ; Check for collision - warn but still attempt navigation
    if ${distance} > 10 && ${Me.CheckCollision[${X},${Y},${Z}]}
    {
        echo [Playback] WARNING: Collision detected to waypoint (${distance.Precision[1]}m away) - attempting navigation anyway
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["WARNING - collision ahead, attempting anyway"]
        ; Do NOT return - let navigation and stuck detection handle it
    }

    echo [Playback] Moving to waypoint (${X.Precision[1]}, ${Y.Precision[1]}, ${Z.Precision[1]}) - Distance: ${distance.Precision[2]}m
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Moving to: (${X.Precision[1]}, ${Y.Precision[1]}, ${Z.Precision[1]}) - ${distance.Precision[1]}m"]

    ; Check if movement thread is running
    if !${Script[JB_UI_Movement](exists)}
    {
        echo [Playback] ERROR: Movement thread not running
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: Movement thread not running"]
        return
    }

    ; Set waypoint marker
    eq2execute waypoint ${X} ${Y} ${Z}

    ; Send movement request to movement thread
    JBUI_Movement_TargetX:Set[${X}]
    JBUI_Movement_TargetY:Set[${Y}]
    JBUI_Movement_TargetZ:Set[${Z}]
    JBUI_Movement_Arrived:Set[FALSE]
    JBUI_Movement_Active:Set[TRUE]

    ; Wait for movement to complete - waitframe works in functions!
    JBUI_Movement_Stuck:Set[FALSE]
    while ${JBUI_Movement_Active} && ${Script[JB_UI_Movement](exists)}
    {
        ; Check if stuck was detected
        if ${JBUI_Movement_Stuck}
        {
            echo [Playback] Movement got STUCK - blacklisting this waypoint location

            ; Add to blacklist (if not full)
            if ${JBUI_Stuck_Count} < 10
            {
                JBUI_Stuck_X[${JBUI_Stuck_Count}]:Set[${X}]
                JBUI_Stuck_Y[${JBUI_Stuck_Count}]:Set[${Y}]
                JBUI_Stuck_Z[${JBUI_Stuck_Count}]:Set[${Z}]
                JBUI_Stuck_Count:Inc
                echo [Playback] Blacklist updated - ${JBUI_Stuck_Count} stuck locations
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Blacklisted stuck zone #${JBUI_Stuck_Count}"]
            }

            JBUI_Movement_Active:Set[FALSE]
            break
        }

        waitCounter:Inc
        if ${waitCounter} > 3000
        {
            echo [Playback] Movement timeout (30 seconds)
            JBUI_Movement_Active:Set[FALSE]
            break
        }
        waitframe
    }

    distance:Set[${Math.Distance[${Me.Loc},${X},${Y},${Z}]}]
    echo [Playback] Arrived at waypoint (final distance: ${distance.Precision[2]}m)
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Arrived (distance: ${distance.Precision[1]}m)"]
}

; ============================================================================
; FILE BROWSER & CATALOG RADIUS FUNCTIONS
; ============================================================================

; Wrapper atom to call the function (atoms can be called from XML, functions cannot use wait)
atom(script) JBUI_Playback_RefreshFolders()
{
    call JBUI_Playback_RefreshFolders_Impl
}

function JBUI_Playback_RefreshFolders_Impl()
{
    if ${JBUI_DebugMode}
        echo [Playback] Refreshing folders...
    UIElement[${JBUI_Playback_FolderList}]:ClearItems
    UIElement[${JBUI_Playback_FileList}]:ClearItems

    variable string jbPath = "${PATH_JB}"
    variable string zonePath = "${jbPath}/Zone"
    variable string instancesPath = "${jbPath}/instances"
    variable string waypointsPath = "${jbPath}/waypoints"
    variable string questsPath = "${jbPath}/quests"
    variable string tasksPath = "${jbPath}/tasks"
    variable string queuesPath = "${jbPath}/queues"

    variable filelist dirList
    variable int iCounter
    variable string searchPath

    ; If we're at the root level, show only categories
    if ${JBUI_CurrentCategory.Equal[""]}
    {
        if ${JBUI_DebugMode}
            echo [Playback] Showing category folders...
        variable int totalCategories = 0

        ; Check Zone Root
        variable filepath zoneFilePath = "${zonePath}"
        if ${zoneFilePath.FileExists}
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[Zone Root]", "ZoneRoot"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [Zone Root]
            totalCategories:Inc
        }

        ; Check instances category
        searchPath:Set["${instancesPath}/"]
        searchPath:Concat["*"]
        dirList:GetDirectories["${searchPath}"]
        if ${dirList.Files} > 0
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[instances]", "Folder"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [instances] category (${dirList.Files} zones)
            totalCategories:Inc
        }

        ; Check waypoints category
        searchPath:Set["${waypointsPath}/"]
        searchPath:Concat["*"]
        dirList:GetDirectories["${searchPath}"]
        if ${dirList.Files} > 0
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[waypoints]", "Folder"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [waypoints] category (${dirList.Files} zones)
            totalCategories:Inc
        }

        ; Check quests category
        searchPath:Set["${questsPath}/"]
        searchPath:Concat["*"]
        dirList:GetDirectories["${searchPath}"]
        if ${dirList.Files} > 0
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[quests]", "Folder"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [quests] category (${dirList.Files} zones)
            totalCategories:Inc
        }

        ; Check tasks category
        searchPath:Set["${tasksPath}/"]
        searchPath:Concat["*"]
        dirList:GetDirectories["${searchPath}"]
        if ${dirList.Files} > 0
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[tasks]", "Folder"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [tasks] category (${dirList.Files} zones)
            totalCategories:Inc
        }

        ; Check queues category
        searchPath:Set["${queuesPath}/"]
        searchPath:Concat["*"]
        dirList:GetDirectories["${searchPath}"]
        if ${dirList.Files} > 0
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["[queues]", "Folder"]
            if ${JBUI_DebugMode}
                echo [Playback] Added [queues] category (${dirList.Files} zones)
            totalCategories:Inc
        }

        if ${JBUI_DebugMode}
            echo [Playback] Refresh complete - Found ${totalCategories} categories

        if ${totalCategories} == 0
        {
            echo [Playback] WARNING: No zone folders found!
            echo [Playback] Make sure you have saved waypoint/quest/task files in zone folders
            echo [Playback] Example: Eq2JCommon/JB/waypoints/Commonlands/mypath.xml
        }
    }
    else
    {
        ; We're inside a category, show zone folders within it
        if ${JBUI_DebugMode}
            echo [Playback] Showing zones in category: ${JBUI_CurrentCategory}

        ; Add a "Back" item to return to categories
        UIElement[${JBUI_Playback_FolderList}]:AddItem["[.. Back]", "Back"]

        variable int totalFolders = 0
        variable string categoryPath

        ; Determine which category path to scan
        if ${JBUI_CurrentCategory.Equal["instances"]}
        {
            categoryPath:Set["${instancesPath}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["waypoints"]}
        {
            categoryPath:Set["${waypointsPath}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["quests"]}
        {
            categoryPath:Set["${questsPath}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["tasks"]}
        {
            categoryPath:Set["${tasksPath}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["queues"]}
        {
            categoryPath:Set["${queuesPath}"]
        }

        if ${JBUI_DebugMode}
            echo [Playback Debug] Category path: ${categoryPath}

        ; Scan the category for zone folders
        searchPath:Set["${categoryPath}/"]
        searchPath:Concat["*"]
        if ${JBUI_DebugMode}
            echo [Playback Debug] Search pattern: ${searchPath}
        dirList:GetDirectories["${searchPath}"]
        if ${JBUI_DebugMode}
            echo [Playback] Found ${dirList.Files} zone folders in ${JBUI_CurrentCategory}

        for (iCounter:Set[1] ; ${iCounter} <= ${dirList.Files} ; iCounter:Inc)
        {
            UIElement[${JBUI_Playback_FolderList}]:AddItem["${dirList.File[${iCounter}].Filename}", "Zone"]
            totalFolders:Inc
        }

        if ${JBUI_DebugMode}
            echo [Playback] Loaded ${totalFolders} zones from [${JBUI_CurrentCategory}]
    }
}

atom(script) JBUI_Playback_FolderSelected()
{
    if !${UIElement[${JBUI_Playback_FolderList}].SelectedItem(exists)}
        return

    variable string selectedFolder = "${UIElement[${JBUI_Playback_FolderList}].SelectedItem.Text}"
    variable string itemType = "${UIElement[${JBUI_Playback_FolderList}].SelectedItem.Value}"

    if ${JBUI_DebugMode}
        echo [Playback Debug] Selected: ${selectedFolder} (Type: ${itemType})

    ; If it's a category folder or back button, don't load files yet (wait for double-click)
    if ${itemType.Equal["Folder"]} || ${itemType.Equal["Back"]}
    {
        UIElement[${JBUI_Playback_FileList}]:ClearItems
        return
    }

    ; Build the folder path based on item type
    variable string jbPath = "${PATH_JB}"
    variable string folderPath

    if ${itemType.Equal["ZoneRoot"]}
    {
        folderPath:Set["${jbPath}/Zone"]
    }
    elseif ${itemType.Equal["Zone"]}
    {
        ; We're in a category, combine category with zone name
        if ${JBUI_CurrentCategory.Equal["instances"]}
        {
            folderPath:Set["${jbPath}/instances/${selectedFolder}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["waypoints"]}
        {
            folderPath:Set["${jbPath}/waypoints/${selectedFolder}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["quests"]}
        {
            folderPath:Set["${jbPath}/quests/${selectedFolder}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["tasks"]}
        {
            folderPath:Set["${jbPath}/tasks/${selectedFolder}"]
        }
        elseif ${JBUI_CurrentCategory.Equal["queues"]}
        {
            folderPath:Set["${jbPath}/queues/${selectedFolder}"]
        }
        else
        {
            return
        }
    }
    else
    {
        return
    }

    ; Store selected folder path
    JBUI_SelectedFolderPath:Set["${folderPath}"]
    if ${JBUI_DebugMode}
        echo [Playback Debug] Folder path: ${folderPath}

    ; Populate files from selected folder using filelist API
    UIElement[${JBUI_Playback_FileList}]:ClearItems

    variable filelist fileList
    variable int iCounter
    variable int fileCount = 0

    ; Get XML files
    variable string xmlSearch
    xmlSearch:Set["${folderPath}/"]
    xmlSearch:Concat["*.xml"]
    if ${JBUI_DebugMode}
        echo [Playback Debug] XML search: ${xmlSearch}
    fileList:GetFiles["${xmlSearch}"]
    if ${JBUI_DebugMode}
        echo [Playback Debug] Found ${fileList.Files} XML files
    for (iCounter:Set[1] ; ${iCounter} <= ${fileList.Files} ; iCounter:Inc)
    {
        UIElement[${JBUI_Playback_FileList}]:AddItem["${fileList.File[${iCounter}].Filename}"]
        fileCount:Inc
    }

    if ${JBUI_DebugMode}
        echo [Playback] Loaded ${fileCount} XML files from ${selectedFolder}
}

atom(script) JBUI_Playback_FileSelected()
{
    if !${UIElement[${JBUI_Playback_FileList}].SelectedItem(exists)}
        return

    variable string fileName = "${UIElement[${JBUI_Playback_FileList}].SelectedItem.Text}"
    variable string fullPath = "${JBUI_SelectedFolderPath}/${fileName}"

    if ${JBUI_DebugMode}
    {
        echo [Playback Debug] File selected: ${fileName}
        echo [Playback Debug] Full path: ${fullPath}
    }

    UIElement[${JBUI_Playback_PathFile_TextEntry}]:SetText["${fullPath}"]
}

atom(script) JBUI_Playback_FolderDoubleClicked()
{
    if !${UIElement[${JBUI_Playback_FolderList}].SelectedItem(exists)}
        return

    variable string selectedFolder = "${UIElement[${JBUI_Playback_FolderList}].SelectedItem.Text}"
    variable string itemType = "${UIElement[${JBUI_Playback_FolderList}].SelectedItem.Value}"

    if ${JBUI_DebugMode}
        echo [Playback Debug] Double-clicked: ${selectedFolder} (Type: ${itemType})

    ; Handle navigation based on item type
    if ${itemType.Equal["Folder"]}
    {
        ; Navigate into this category folder
        ; Extract category name by removing brackets
        variable string categoryName = "${selectedFolder}"
        ; Remove leading [
        categoryName:Set["${categoryName.Right[-1]}"]
        ; Remove trailing ]
        categoryName:Set["${categoryName.Left[-1]}"]

        JBUI_CurrentCategory:Set["${categoryName}"]
        if ${JBUI_DebugMode}
            echo [Playback] Navigating into category: ${categoryName}

        ; Refresh to show zone folders within this category
        call JBUI_Playback_RefreshFolders_Impl
    }
    elseif ${itemType.Equal["Back"]}
    {
        ; Navigate back to category list
        if ${JBUI_DebugMode}
            echo [Playback] Navigating back to categories
        JBUI_CurrentCategory:Set[""]

        ; Refresh to show categories
        call JBUI_Playback_RefreshFolders_Impl
    }
    elseif ${itemType.Equal["ZoneRoot"]}
    {
        ; Zone Root can be treated as already showing files on single-click
        ; Double-click does nothing special
        if ${JBUI_DebugMode}
            echo [Playback Debug] Zone Root double-clicked (no action)
    }
    elseif ${itemType.Equal["Zone"]}
    {
        ; Zone folder double-clicked - files already shown on single-click
        ; Could add future functionality here (e.g., navigate into subfolders)
        if ${JBUI_DebugMode}
            echo [Playback Debug] Zone folder double-clicked (no action)
    }
}

atom(script) JBUI_Mapper_CatalogRadius()
{
    variable int radius
    radius:Set[${UIElement[${JBUI_Mapper_RadiusEntry}].Text}]

    if ${radius} <= 0
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Invalid radius"]
        return
    }

    ; Use QueryActors for efficient actor scanning (WAY faster than looping)
    variable index:actor Actors
    variable iterator ActorIterator
    variable int catalogCount = 0

    EQ2:QueryActors[Actors, Distance <= ${radius}]
    Actors:GetIterator[ActorIterator]

    if ${ActorIterator:First(exists)}
    {
        do
        {
            ; Skip self
            if ${ActorIterator.Value.ID} == ${Me.ID}
                continue

            ; Build detailed actor entry
            variable string actorEntry
            actorEntry:Set["[${ActorIterator.Value.Type}] ${ActorIterator.Value.Name} (ID:${ActorIterator.Value.ID}) - ${ActorIterator.Value.Distance.Precision[1]}m @ ${ActorIterator.Value.Loc.X.Precision[1]},${ActorIterator.Value.Loc.Y.Precision[1]},${ActorIterator.Value.Loc.Z.Precision[1]}"]

            ; Check if already in UI list (duplicate check by ID)
            variable bool isDuplicate = FALSE
            variable int i
            for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
            {
                if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["ID:${ActorIterator.Value.ID}"]}
                {
                    isDuplicate:Set[TRUE]
                    break
                }
            }

            if !${isDuplicate}
            {
                UIElement[${JBUI_Mapper_ActorCatalog}]:AddItem["${actorEntry}"]
                catalogCount:Inc

                ; Save detailed actor info to catalog database
                call JBUI_Catalog_SaveActor "${ActorIterator.Value.ID}"
            }
        }
        while ${ActorIterator:Next(exists)}
    }

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Cataloged ${catalogCount} actors within ${radius}m"]
    echo [Mapper] Cataloged ${catalogCount} actors within ${radius}m radius

    ; Auto-save catalog to file
    if ${JBUI_Catalog_AutoSave}
        call JBUI_Catalog_SaveToFile
}

; ============================================================================
; ACTOR CATALOG DATABASE - Persistent Storage System
; ============================================================================

function JBUI_Catalog_SaveActor(int actorID)
{
    ; Save detailed actor information to memory (for later file save)
    ; This stores actor data in a format ready for persistent storage

    if !${Actor[${actorID}](exists)}
        return

    ; Create catalog directory structure if it doesn't exist
    variable filepath jbDir = "${PATH_JB}"
    variable string catalogPath = "${PATH_JB}/catalog"
    variable filepath catalogDir = "${catalogPath}"

    if !${catalogDir.FileExists}
    {
        jbDir:MakeSubdirectory["catalog"]
        echo [Catalog] Created catalog directory: ${catalogPath}
    }

    ; Create zone-specific directory
    variable string zoneName = "${Zone.Name}"
    variable string zonePath = "${catalogPath}/${zoneName}"
    variable filepath zoneDir = "${zonePath}"
    if !${zoneDir.FileExists}
    {
        catalogDir:MakeSubdirectory["${zoneName}"]
        echo [Catalog] Created zone catalog: ${zoneName}
    }

    JBUI_Catalog_CurrentZone:Set["${zoneName}"]
    JBUI_Catalog_TotalActors:Inc
}

function JBUI_Catalog_SaveToFile()
{
    ; Save current catalog UI list to persistent XML file
    variable string zoneName = "${Zone.Name}"
    variable string catalogPath = "${PATH_JB}/catalog/${zoneName}"
    variable string catalogFile = "${catalogPath}/actors.xml"

    ; Ensure directory exists
    variable filepath catalogBaseDir = "${PATH_JB}/catalog"
    variable filepath catalogDir = "${catalogPath}"
    if !${catalogDir.FileExists}
    {
        catalogBaseDir:MakeSubdirectory["${zoneName}"]
        echo [Catalog] Created zone directory: ${zoneName}
    }

    ; Build XML from current catalog list
    variable file outputFile
    variable string xmlData
    variable int itemCount = ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}

    if ${itemCount} == 0
    {
        echo [Catalog] No actors to save
        return
    }

    xmlData:Set["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"]
    xmlData:Concat["<ActorCatalog zone=\"${zoneName.Escape}\" saved=\"${Time.Date} ${Time.Time24}\" totalActors=\"${itemCount}\">\n"]

    variable int i
    variable int savedCount = 0
    for (i:Set[1]; ${i} <= ${itemCount}; i:Inc)
    {
        variable string actorText = "${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text}"

        ; Skip empty/null items
        if ${actorText.Length} == 0
        {
            echo [Catalog] Skipping empty item ${i}
            continue
        }

        ; Skip items that don't match expected format (must have "ID:" and "@")
        if !${actorText.Find["ID:"]} || !${actorText.Find["@"]}
        {
            echo [Catalog] Skipping malformed item ${i}: "${actorText}"
            continue
        }

        echo [Catalog] Parsing actor ${i}: "${actorText}"

        ; Parse actor info from UI text format:
        ; [Type] Name (ID:123) - 15.0m @ X,Y,Z

        ; Extract Type (between [ and ])
        variable string actorType = "Unknown"
        variable int typeStart = ${actorText.Find["["]}
        variable int typeEnd = ${actorText.Find["]"]}
        if ${typeStart} >= 0 && ${typeEnd} > ${typeStart}
        {
            variable int typeLen = ${Math.Calc[${typeEnd}-${typeStart}-1]}
            if ${typeLen} > 0
                actorType:Set["${actorText.Mid[${Math.Calc[${typeStart}+1]},${typeLen}]}"]
        }

        ; Extract Name (between "] " and " (ID:")
        variable string actorName = "Unknown"
        variable int nameStart = ${Math.Calc[${typeEnd}+2]}
        variable int nameEnd = ${actorText.Find[" (ID:"]}
        if ${nameEnd} > ${nameStart}
        {
            variable int nameLen = ${Math.Calc[${nameEnd}-${nameStart}]}
            if ${nameLen} > 0
                actorName:Set["${actorText.Mid[${nameStart},${nameLen}]}"]
        }

        ; Extract ID (between "ID:" and ")")
        variable string actorID = "0"
        variable int idStart = ${actorText.Find["ID:"]}
        variable int idEnd = ${actorText.Find[idStart,")"]}
        if ${idStart} >= 0 && ${idEnd} > ${idStart}
        {
            variable int idLen = ${Math.Calc[${idEnd}-${idStart}-3]}
            if ${idLen} > 0
                actorID:Set["${actorText.Mid[${Math.Calc[${idStart}+3]},${idLen}]}"]
        }

        ; Extract Location (everything after " @ ")
        variable string xCoord = "0"
        variable string yCoord = "0"
        variable string zCoord = "0"
        variable int locStart = ${actorText.Find[" @ "]}
        if ${locStart} >= 0
        {
            ; Get substring from locStart+3 to end
            variable int locPos = ${Math.Calc[${locStart}+3]}
            variable int locLen = ${Math.Calc[${actorText.Length}-${locPos}]}
            if ${locLen} > 0
            {
                variable string location = "${actorText.Mid[${locPos},${locLen}]}"
                ; Remove any trailing text after coordinates (like [MULTI-SPAWN])
                variable int spacePos = ${location.Find[" "]}
                if ${spacePos} > 0
                    location:Set["${location.Left[${spacePos}]}"]

                ; Parse X,Y,Z
                variable int comma1 = ${location.Find[","]}
                variable int comma2 = ${location.Find[comma1+1,","]}
                if ${comma1} > 0 && ${comma2} > ${comma1}
                {
                    xCoord:Set["${location.Left[${comma1}]}"]
                    yCoord:Set["${location.Mid[${Math.Calc[${comma1}+1]},${Math.Calc[${comma2}-${comma1}-1]}]}"]
                    zCoord:Set["${location.Mid[${Math.Calc[${comma2}+1]},${Math.Calc[${location.Length}-${comma2}-1]}]}"]
                }
            }
        }

        echo [Catalog]   Type="${actorType}" Name="${actorName}" ID=${actorID} Loc="${xCoord},${yCoord},${zCoord}"

        ; Build XML entry - escape XML special characters
        xmlData:Concat["    <Actor name=\"${actorName.Escape}\" type=\"${actorType.Escape}\" id=\"${actorID}\" x=\"${xCoord}\" y=\"${yCoord}\" z=\"${zCoord}\" />\n"]
        savedCount:Inc
    }

    xmlData:Concat["</ActorCatalog>\n"]

    ; Write to file
    outputFile:SetFilename["${catalogFile}"]
    outputFile:Open[write]
    outputFile:Write["${xmlData}"]
    outputFile:Close

    echo [Catalog] Saved ${savedCount} actors to ${catalogFile}
}

function JBUI_Catalog_LoadFromFile()
{
    ; Load catalog from XML file for current zone
    variable string zoneName = "${Zone.Name}"
    variable string catalogFile = "${PATH_JB}/catalog/${zoneName}/actors.xml"

    variable filepath checkFile = "${catalogFile}"
    if !${checkFile.FileExists}
    {
        echo [Catalog] No saved catalog found for zone: ${zoneName}
        return
    }

    ; Clear current catalog
    UIElement[${JBUI_Mapper_ActorCatalog}]:ClearItems

    ; Read and parse XML file
    variable file inputFile
    variable string line
    variable int loadedCount = 0

    inputFile:SetFilename["${catalogFile}"]
    inputFile:Open[readonly]

    echo [Catalog] Loading catalog from ${catalogFile}

    while ${inputFile:Read[line]}
    {
        ; Look for <Actor> lines
        if ${line.Find["<Actor "]} > 0
        {
            ; Parse XML attributes: name="..." type="..." id="..." x="..." y="..." z="..."
            variable string actorName = "Unknown"
            variable string actorType = "Unknown"
            variable string actorID = "0"
            variable string xCoord = "0"
            variable string yCoord = "0"
            variable string zCoord = "0"

            ; Extract name
            variable int namePos = ${line.Find["name=\""]}
            if ${namePos} > 0
            {
                variable int nameStart = ${Math.Calc[${namePos}+6]}
                variable int nameEnd = ${line.Find[nameStart,"\""]}
                if ${nameEnd} > ${nameStart}
                {
                    actorName:Set["${line.Mid[${nameStart},${Math.Calc[${nameEnd}-${nameStart}]}]}"]
                }
            }

            ; Extract type
            variable int typePos = ${line.Find["type=\""]}
            if ${typePos} > 0
            {
                variable int typeStart = ${Math.Calc[${typePos}+6]}
                variable int typeEnd = ${line.Find[typeStart,"\""]}
                if ${typeEnd} > ${typeStart}
                {
                    actorType:Set["${line.Mid[${typeStart},${Math.Calc[${typeEnd}-${typeStart}]}]}"]
                }
            }

            ; Extract id
            variable int idPos = ${line.Find["id=\""]}
            if ${idPos} > 0
            {
                variable int idStart = ${Math.Calc[${idPos}+4]}
                variable int idEnd = ${line.Find[idStart,"\""]}
                if ${idEnd} > ${idStart}
                {
                    actorID:Set["${line.Mid[${idStart},${Math.Calc[${idEnd}-${idStart}]}]}"]
                }
            }

            ; Extract x
            variable int xPos = ${line.Find["x=\""]}
            if ${xPos} > 0
            {
                variable int xStart = ${Math.Calc[${xPos}+3]}
                variable int xEnd = ${line.Find[xStart,"\""]}
                if ${xEnd} > ${xStart}
                {
                    xCoord:Set["${line.Mid[${xStart},${Math.Calc[${xEnd}-${xStart}]}]}"]
                }
            }

            ; Extract y
            variable int yPos = ${line.Find["y=\""]}
            if ${yPos} > 0
            {
                variable int yStart = ${Math.Calc[${yPos}+3]}
                variable int yEnd = ${line.Find[yStart,"\""]}
                if ${yEnd} > ${yStart}
                {
                    yCoord:Set["${line.Mid[${yStart},${Math.Calc[${yEnd}-${yStart}]}]}"]
                }
            }

            ; Extract z
            variable int zPos = ${line.Find["z=\""]}
            if ${zPos} > 0
            {
                variable int zStart = ${Math.Calc[${zPos}+3]}
                variable int zEnd = ${line.Find[zStart,"\""]}
                if ${zEnd} > ${zStart}
                {
                    zCoord:Set["${line.Mid[${zStart},${Math.Calc[${zEnd}-${zStart}]}]}"]
                }
            }

            ; Build UI list entry in same format as cataloging: [Type] Name (ID:123) - 0.0m @ X,Y,Z
            variable string actorEntry
            actorEntry:Set["[${actorType}] ${actorName} (ID:${actorID}) - 0.0m @ ${xCoord},${yCoord},${zCoord}"]

            UIElement[${JBUI_Mapper_ActorCatalog}]:AddItem["${actorEntry}"]
            loadedCount:Inc
        }
    }

    inputFile:Close

    echo [Catalog] Loaded ${loadedCount} actors from ${catalogFile}
    UIElement[${JBUI_Mapper_StatusText}]:SetText["Loaded ${loadedCount} actors for ${zoneName}"]
}

function JBUI_Catalog_SearchByName(string searchName)
{
    ; Search catalog for actors matching name (partial match)
    ; Returns count of matches found

    variable int matchCount = 0
    variable int i

    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["${searchName}"]}
        {
            matchCount:Inc
            echo [Catalog] Found: ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text}
        }
    }

    return ${matchCount}
}

atom(script) JBUI_Catalog_SaveCatalog()
{
    ; Button handler to manually save catalog
    call JBUI_Catalog_SaveToFile
    UIElement[${JBUI_Mapper_StatusText}]:SetText["Catalog saved to file"]
}

atom(script) JBUI_Catalog_LoadCatalog()
{
    ; Button handler to manually load catalog
    call JBUI_Catalog_LoadFromFile
}

; ============================================================================
; STAGE 2: SEARCH & NAVIGATION
; ============================================================================

atom(script) JBUI_Catalog_SearchActors()
{
    ; Search catalog for actors by name (partial match)
    variable string searchTerm = "${UIElement[${JBUI_Mapper_SearchEntry}].Text}"

    if ${searchTerm.Length} == 0
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Enter search term"]
        return
    }

    variable int matchCount = 0
    variable int i

    ; Convert search term to lowercase for case-insensitive search
    variable string searchLower = "${searchTerm.Lower}"

    ; Search through catalog list (case-insensitive)
    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        variable string itemText = "${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Lower}"
        if ${itemText.Find["${searchLower}"]}
        {
            matchCount:Inc
            echo [Catalog] Match ${matchCount}: ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text}
        }
    }

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Found ${matchCount} matching actors"]
    echo [Catalog] Search "${searchTerm}" found ${matchCount} matches
}

atom(script) JBUI_Catalog_FilterByType()
{
    ; Filter catalog by actor type
    variable string filterType = "${UIElement[${JBUI_Mapper_TypeFilterCombo}].SelectedItem.Text}"

    if ${filterType.Equal["All Types"]}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Showing all actor types"]
        return
    }

    ; Count matching types
    variable int matchCount = 0
    variable int i

    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["[${filterType}]"]}
        {
            matchCount:Inc
        }
    }

    UIElement[${JBUI_Mapper_StatusText}]:SetText["Found ${matchCount} ${filterType} actors"]
}

atom(script) JBUI_Catalog_NavigateToActor()
{
    ; Navigate to selected actor's location
    if !${UIElement[${JBUI_Mapper_ActorCatalog}].SelectedItem(exists)}
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Select an actor first"]
        return
    }

    variable string actorText = "${UIElement[${JBUI_Mapper_ActorCatalog}].SelectedItem.Text}"

    ; Extract location from format: [Type] Name (ID:123) - 15.0m @ X,Y,Z
    variable int locStart = ${actorText.Find[" @ "]}
    if ${locStart} <= 0
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: No location data for actor"]
        return
    }

    variable string location = "${actorText.Right[${Math.Calc[${locStart}+3]}]}"

    ; Parse X,Y,Z
    variable string xVal
    variable string yVal
    variable string zVal
    variable int comma1 = ${location.Find[","]}
    variable int comma2

    if ${comma1} > 0
    {
        xVal:Set["${location.Left[${comma1}]}"]
        location:Set["${location.Right[${Math.Calc[${comma1}+1]}]}"]
        comma2:Set[${location.Find[","]}]

        if ${comma2} > 0
        {
            yVal:Set["${location.Left[${comma2}]}"]
            zVal:Set["${location.Right[${Math.Calc[${comma2}+1]}]}"]
        }
    }

    if ${xVal.Length} > 0 && ${yVal.Length} > 0 && ${zVal.Length} > 0
    {
        ; Navigate using OgreBot ChangeCampSpot
        relay all oc !ci -ChangeCampSpot ${xVal} ${yVal} ${zVal} igw:${Me.Name}
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Navigating to: ${xVal},${yVal},${zVal}"]
        echo [Catalog] Navigating to actor at ${xVal},${yVal},${zVal}

        ; Set waypoint
        eq2execute /waypoint ${xVal} ${yVal} ${zVal}
    }
    else
    {
        UIElement[${JBUI_Mapper_StatusText}]:SetText["ERROR: Could not parse location"]
    }
}

function JBUI_Catalog_VerifyActorAtLocation(string actorName, float x, float y, float z, float tolerance)
{
    ; Check if actor is near the expected location
    ; Returns TRUE if found, FALSE if not

    variable index:actor Actors
    variable iterator ActorIterator

    ; Query actors near the location
    EQ2:QueryActors[Actors, Name =- "${actorName}"]
    Actors:GetIterator[ActorIterator]

    if ${ActorIterator:First(exists)}
    {
        do
        {
            ; Check distance from expected location
            variable float distX = ${Math.Calc[${ActorIterator.Value.X} - ${x}]}
            variable float distY = ${Math.Calc[${ActorIterator.Value.Y} - ${y}]}
            variable float distZ = ${Math.Calc[${ActorIterator.Value.Z} - ${z}]}

            ; Simple distance check
            if ${Math.Calc[${distX}*${distX} + ${distY}*${distY} + ${distZ}*${distZ}]} < ${Math.Calc[${tolerance}*${tolerance}]}
            {
                echo [Catalog] Verified actor "${actorName}" at location
                return TRUE
            }
        }
        while ${ActorIterator:Next(exists)}
    }

    echo [Catalog] Actor "${actorName}" NOT found at expected location
    return FALSE
}

; ============================================================================
; STAGE 3: AUTOMATION COMMANDS (GoToActor, FindNearest, InteractActor)
; ============================================================================

; Blacklist tracking for failed locations
variable(global) string JBUI_Blacklist_Actors[100]
variable(global) int JBUI_Blacklist_Count = 0

function JBUI_Catalog_IsBlacklisted(string actorName)
{
    ; Check if actor is blacklisted
    variable int i
    for (i:Set[1]; ${i} <= ${JBUI_Blacklist_Count}; i:Inc)
    {
        if ${JBUI_Blacklist_Actors[${i}].Equal["${actorName}"]}
            return TRUE
    }
    return FALSE
}

function JBUI_Catalog_AddToBlacklist(string actorName)
{
    ; Add actor to blacklist
    if ${JBUI_Blacklist_Count} < 100
    {
        JBUI_Blacklist_Count:Inc
        JBUI_Blacklist_Actors[${JBUI_Blacklist_Count}]:Set["${actorName}"]
        echo [Catalog] Blacklisted: ${actorName}
    }
}

function JBUI_Catalog_ClearBlacklist()
{
    ; Clear all blacklisted actors
    JBUI_Blacklist_Count:Set[0]
    echo [Catalog] Blacklist cleared
}

function JBUI_Playback_Command_GoToActor(string actorName, int maxRetries)
{
    ; Navigate to a cataloged actor by name
    ; Retries alternate spawn points if actor not found
    ; Blacklists after max failures

    if ${maxRetries} <= 0
        maxRetries:Set[3]

    ; Check if blacklisted
    if ${JBUI_Catalog_IsBlacklisted["${actorName}"]}
    {
        echo [GoToActor] Actor "${actorName}" is blacklisted, skipping
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["SKIP: ${actorName} blacklisted"]
        return FALSE
    }

    ; Search catalog for actor
    variable int actorIndex = -1
    variable int i

    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["${actorName}"]}
        {
            actorIndex:Set[${i}]
            break
        }
    }

    if ${actorIndex} <= 0
    {
        echo [GoToActor] Actor "${actorName}" not found in catalog
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["ERROR: ${actorName} not cataloged"]
        return FALSE
    }

    ; Extract location from cataloged actor
    variable string actorText = "${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${actorIndex}].Text}"
    variable int locStart = ${actorText.Find[" @ "]}

    if ${locStart} <= 0
    {
        echo [GoToActor] No location data for "${actorName}"
        return FALSE
    }

    variable string location = "${actorText.Right[${Math.Calc[${locStart}+3]}]}"

    ; Parse X,Y,Z
    variable string xVal
    variable string yVal
    variable string zVal
    variable int comma1 = ${location.Find[","]}
    variable int comma2

    if ${comma1} > 0
    {
        xVal:Set["${location.Left[${comma1}]}"]
        location:Set["${location.Right[${Math.Calc[${comma1}+1]}]}"]
        comma2:Set[${location.Find[","]}]

        if ${comma2} > 0
        {
            yVal:Set["${location.Left[${comma2}]}"]
            zVal:Set["${location.Right[${Math.Calc[${comma2}+1]}]}"]
        }
    }

    ; Navigate to location
    echo [GoToActor] Navigating to "${actorName}" at ${xVal},${yVal},${zVal}
    UIElement[${JBUI_PlaybackStatus_Console}]:Echo["GoToActor: ${actorName}"]

    relay all oc !ci -ChangeCampSpot ${xVal} ${yVal} ${zVal} igw:${Me.Name}
    wait 50  ; Wait for initial movement

    ; Wait for arrival (check distance to destination)
    variable int waitCount = 0
    variable float distance

    while ${waitCount} < 200
    {
        distance:Set[${Math.Distance[${Me.X},${Me.Y},${Me.Z},${xVal},${yVal},${zVal}]}]

        if ${distance} < 5
        {
            echo [GoToActor] Arrived at ${actorName} location

            ; Verify actor is actually there
            if ${JBUI_Catalog_VerifyActorAtLocation["${actorName}",${xVal},${yVal},${zVal},10]}
            {
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["SUCCESS: Found ${actorName}"]
                return TRUE
            }
            else
            {
                echo [GoToActor] Actor not found at location, blacklisting
                call JBUI_Catalog_AddToBlacklist "${actorName}"
                UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FAILED: ${actorName} not at location"]
                return FALSE
            }
        }

        wait 10
        waitCount:Inc
    }

    echo [GoToActor] Timeout navigating to ${actorName}
    return FALSE
}

function JBUI_Playback_Command_FindNearest(string actorType, int maxDistance)
{
    ; Find and navigate to nearest actor of specified type

    if ${maxDistance} <= 0
        maxDistance:Set[50]

    variable index:actor Actors
    variable iterator ActorIterator
    variable float nearestDist = 999999
    variable int nearestID = 0

    ; Query actors by type within distance
    EQ2:QueryActors[Actors, Type = "${actorType}" && Distance <= ${maxDistance}]
    Actors:GetIterator[ActorIterator]

    if ${ActorIterator:First(exists)}
    {
        do
        {
            if ${ActorIterator.Value.Distance} < ${nearestDist}
            {
                nearestDist:Set[${ActorIterator.Value.Distance}]
                nearestID:Set[${ActorIterator.Value.ID}]
            }
        }
        while ${ActorIterator:Next(exists)}
    }

    if ${nearestID} > 0
    {
        echo [FindNearest] Found ${actorType} at ${nearestDist.Precision[1]}m (ID:${nearestID})
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FindNearest: ${Actor[${nearestID}].Name}"]

        ; Navigate to it
        relay all oc !ci -ChangeCampSpot ${Actor[${nearestID}].X} ${Actor[${nearestID}].Y} ${Actor[${nearestID}].Z} igw:${Me.Name}
        return TRUE
    }
    else
    {
        echo [FindNearest] No ${actorType} found within ${maxDistance}m
        UIElement[${JBUI_PlaybackStatus_Console}]:Echo["FindNearest: None found"]
        return FALSE
    }
}

function JBUI_Playback_Command_InteractActor(string actorName, int maxRetries)
{
    ; Navigate to actor and interact with them

    if ${maxRetries} <= 0
        maxRetries:Set[3]

    ; First, navigate to actor
    if !${JBUI_Playback_Command_GoToActor["${actorName}",${maxRetries}]}
    {
        echo [InteractActor] Failed to navigate to ${actorName}
        return FALSE
    }

    ; Now try to interact
    variable int tryCount = 0
    variable index:actor Actors
    variable iterator ActorIterator

    while ${tryCount} < ${maxRetries}
    {
        ; Find actor by name
        EQ2:QueryActors[Actors, Name =- "${actorName}" && Distance <= 10]
        Actors:GetIterator[ActorIterator]

        if ${ActorIterator:First(exists)}
        {
            echo [InteractActor] Interacting with ${actorName}
            UIElement[${JBUI_PlaybackStatus_Console}]:Echo["Interact: ${actorName}"]

            ; Double-click actor to interact
            Actor[${ActorIterator.Value.ID}]:DoubleClick
            wait 20
            return TRUE
        }

        tryCount:Inc
        wait 10
    }

    echo [InteractActor] Failed to interact with ${actorName}
    call JBUI_Catalog_AddToBlacklist "${actorName}"
    return FALSE
}

; ============================================================================
; STAGE 4: EVENT-BASED AUTO-CATALOGING & MULTI-SPAWN TRACKING
; ============================================================================

variable(global) bool JBUI_Catalog_LearnMode = FALSE
variable(global) int JBUI_Catalog_LearnRadius = 50

atom(script) JBUI_Catalog_ToggleLearnMode()
{
    ; Toggle learning mode on/off
    JBUI_Catalog_LearnMode:Set[${Math.Not[${JBUI_Catalog_LearnMode}]}]

    if ${JBUI_Catalog_LearnMode}
    {
        ; Enable learning mode - attach event
        Event[EQ2_ActorSpawned]:AttachAtom[JBUI_Catalog_OnActorSpawned]
        UIElement[${JBUI_Mapper_LearnModeButton}].Font:SetColor[FF00FF00]
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Learning Mode: ON (radius ${JBUI_Catalog_LearnRadius}m)"]
        echo [Catalog] Learning Mode ENABLED - will auto-catalog actors within ${JBUI_Catalog_LearnRadius}m
    }
    else
    {
        ; Disable learning mode - detach event
        Event[EQ2_ActorSpawned]:DetachAtom[JBUI_Catalog_OnActorSpawned]
        UIElement[${JBUI_Mapper_LearnModeButton}].Font:SetColor[FFFF0000]
        UIElement[${JBUI_Mapper_StatusText}]:SetText["Learning Mode: OFF"]
        echo [Catalog] Learning Mode DISABLED
    }
}

atom(script) JBUI_Catalog_OnActorSpawned(string ID, string Name, string Level, string ActorType)
{
    ; Auto-catalog actor when it spawns (if within learn radius)

    if !${Actor[${ID}](exists)}
        return

    if ${Actor[${ID}].Distance} > ${JBUI_Catalog_LearnRadius}
        return

    ; Skip self
    if ${Actor[${ID}].ID} == ${Me.ID}
        return

    ; Check if already cataloged (avoid duplicates)
    variable int i
    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["${Name}"]} && ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["ID:${ID}"]}
        {
            ; Already have this exact actor
            return
        }
    }

    ; Check for multi-spawn (same name, different ID/location)
    variable bool isMultiSpawn = FALSE
    for (i:Set[1]; ${i} <= ${UIElement[${JBUI_Mapper_ActorCatalog}].Items}; i:Inc)
    {
        if ${UIElement[${JBUI_Mapper_ActorCatalog}].Item[${i}].Text.Find["] ${Name} ("]}
        {
            ; Found same actor name with different ID - this is a multi-spawn
            isMultiSpawn:Set[TRUE]
            echo [Catalog] Multi-spawn detected: ${Name} at new location
            break
        }
    }

    ; Add to catalog
    variable string actorEntry
    actorEntry:Set["[${ActorType}] ${Name} (ID:${ID}) - ${Actor[${ID}].Distance.Precision[1]}m @ ${Actor[${ID}].X.Precision[1]},${Actor[${ID}].Y.Precision[1]},${Actor[${ID}].Z.Precision[1]}"]

    if ${isMultiSpawn}
        actorEntry:Concat[" [MULTI-SPAWN]"]

    UIElement[${JBUI_Mapper_ActorCatalog}]:AddItem["${actorEntry}"]
    call JBUI_Catalog_SaveActor "${ID}"

    echo [Catalog] Auto-cataloged: ${Name} (${ActorType}) at ${Actor[${ID}].Distance.Precision[1]}m

    ; Auto-save if enabled
    if ${JBUI_Catalog_AutoSave}
        call JBUI_Catalog_SaveToFile
}

; ============================================================================
; ZONE TRAVEL HELPER FUNCTIONS
; ============================================================================

function wait_for_zone(string ZoneName)
{
    while !${Zone.Name.Find["${ZoneName}"]} || ${EQ2.Zoning}
        wait 50
}

; NOTE: move_to_actor is now defined in JB_PlaybackCommands.iss
; This file includes JB_PlaybackCommands.iss, so the function is available

function use_everporter(string ZoneName)
{
    variable string GHActor = "Coldborne EverPorter"
    if ${Actor[Query, Name == "${GHActor}"](exists)}
    {
        echo "In GH, EverPorter"
        wait 10
        call move_to_actor ${Actor[Query, Name == "${GHActor}"].ID}
        oc !ci -Actor_Click igw:${Me.Name} ${Actor[Query, Name == "${GHActor}"].ID} TRUE
        wait 20
        oc !ci -ZoneDoorForWho igw:${Me.Name} "${ZoneName}"
    }
    else
    {
        echo "Cannot find EverPorter! Are you in GH?"
    }
}

; ============================================================================
; ZONE TRAVEL HANDLERS
; ============================================================================

function JBUI_ZoneTravel_UseBell()
{
    ; Check if an item is selected in the listbox
    if !${UIElement[${JBUI_ZoneTravel_BellList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Please select a destination from the list"]
        echo [ZoneTravel] No bell destination selected
        return
    }

    variable string destination
    destination:Set["${UIElement[${JBUI_ZoneTravel_BellList}].SelectedItem.Text}"]

    if ${destination.Length} == 0 || ${destination.Equal["NULL"]}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Invalid destination selected"]
        echo [ZoneTravel] Invalid bell destination: ${destination}
        return
    }

    echo [ZoneTravel] Traveling to ${destination} via bell
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Traveling to ${destination} via bell..."]

    ; Use playback command library
    call Cmd_TravelBell "${destination}"

    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Arrived at ${destination}"]
    echo [ZoneTravel] Successfully traveled to ${destination}
}

function JBUI_ZoneTravel_UseSpire()
{
    ; Check if an item is selected in the listbox
    if !${UIElement[${JBUI_ZoneTravel_SpireList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Please select a destination from the list"]
        echo [ZoneTravel] No spire destination selected
        return
    }

    variable string destination
    destination:Set["${UIElement[${JBUI_ZoneTravel_SpireList}].SelectedItem.Text}"]

    if ${destination.Length} == 0 || ${destination.Equal["NULL"]}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Invalid destination selected"]
        echo [ZoneTravel] Invalid spire destination: ${destination}
        return
    }

    echo [ZoneTravel] Traveling to ${destination} via spire
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Traveling to ${destination} via spire..."]

    ; Use playback command library
    call Cmd_TravelSpire "${destination}"

    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Arrived at ${destination}"]
    echo [ZoneTravel] Successfully traveled to ${destination}
}

function JBUI_ZoneTravel_UseDruid()
{
    ; Check if an item is selected in the listbox
    if !${UIElement[${JBUI_ZoneTravel_DruidList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Please select a destination from the list"]
        echo [ZoneTravel] No druid ring destination selected
        return
    }

    variable string destination
    destination:Set["${UIElement[${JBUI_ZoneTravel_DruidList}].SelectedItem.Text}"]

    if ${destination.Length} == 0 || ${destination.Equal["NULL"]}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Invalid destination selected"]
        echo [ZoneTravel] Invalid druid ring destination: ${destination}
        return
    }

    echo [ZoneTravel] Traveling to ${destination} via druid ring
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Traveling to ${destination} via druid ring..."]

    ; Use playback command library
    call Cmd_TravelDruid "${destination}"

    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Arrived at ${destination}"]
    echo [ZoneTravel] Successfully traveled to ${destination}
}

function JBUI_ZoneTravel_UseEverPorter()
{
    ; Check if an item is selected in the listbox
    if !${UIElement[${JBUI_ZoneTravel_EverPorterList}].SelectedItem(exists)}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Please select a destination from the list"]
        echo [ZoneTravel] No EverPorter destination selected
        return
    }

    variable string destination
    destination:Set["${UIElement[${JBUI_ZoneTravel_EverPorterList}].SelectedItem.Text}"]

    ; Validate destination is not NULL or empty
    if ${destination.Length} == 0 || ${destination.Equal["NULL"]}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Invalid destination selected"]
        echo [ZoneTravel] Invalid EverPorter destination: ${destination}
        return
    }

    echo [ZoneTravel] Traveling to ${destination} via EverPorter

    ; Find the Coldborne EverPorter in Guild Hall
    variable string GHActor = "Coldborne EverPorter"
    if !${Actor[Query, Name == "${GHActor}"](exists)}
    {
        UIElement[${JBUI_ZoneTravel_Status}]:SetText["Error: Cannot find EverPorter! Are you in your Guild Hall?"]
        echo [ZoneTravel] Cannot find ${GHActor} - not in Guild Hall?
        return
    }

    ; Move to the EverPorter
    variable int everporterID
    everporterID:Set[${Actor[Query, Name == "${GHActor}"].ID}]
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Moving to EverPorter..."]
    echo [ZoneTravel] Found EverPorter at ${Actor[${everporterID}].Distance.Precision[1]}m, moving to it
    call move_to_actor ${everporterID}

    ; Click the EverPorter to open dialog
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Opening EverPorter dialog..."]
    oc !ci -Actor_Click igw:${Me.Name} ${everporterID} TRUE
    wait 20

    ; Use the zone door option to travel to destination
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Selecting destination: ${destination}"]
    echo [ZoneTravel] Requesting zone door to ${destination}
    oc !ci -ZoneDoorForWho igw:${Me.Name} "${destination}"
    wait 20

    ; Wait for zoning to complete
    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Traveling to ${destination}..."]
    echo [ZoneTravel] Waiting for zone to ${destination}
    call wait_for_zone "${destination}"

    UIElement[${JBUI_ZoneTravel_Status}]:SetText["Arrived at ${destination}"]
    echo [ZoneTravel] Successfully traveled to ${destination} via EverPorter
}

; ============================================================================
; TSO INSTANCE ROUTING FUNCTIONS (Loping Plains)
; ============================================================================

function tso_routes_get_to_loping()
{
    ; Use zone travel to get to Loping Plains via druid ring
    variable string destination = "Loping Plains"

    ; Find nearby Druid Ring automatically
    variable int druidID
    if ${Actor[Query, Type="Transport" && Name="Druid Ring"](exists)}
    {
        druidID:Set[${Actor[Query, Type="Transport" && Name="Druid Ring"].ID}]
        echo [TSO Routes] Found druid ring at ${Actor[${druidID}].Distance.Precision[1]}m, moving to it
        call move_to_actor ${druidID}

        ; Click the druid ring to open radial menu
        oc !ci -Actor_Click igw:${Me.Name} ${druidID} TRUE
        wait 10
    }
    elseif ${Me.Target(exists)}
    {
        echo [TSO Routes] Using current target for druid ring travel
    }
    else
    {
        echo [TSO Routes] ERROR: No Druid Ring found nearby or targeted
        return
    }

    ; Use radial menu to select Loping Plains
    EQ2:DoRadialMenu[${destination}]
    wait 20

    ; Wait for zoning to complete
    echo [TSO Routes] Waiting for zone to ${destination}
    call wait_for_zone "${destination}"
    echo [TSO Routes] Arrived at ${destination}
}

function tso_routes_to_loping(string ZoneName)
{
    ; Get to Loping Plains first
    echo [TSO Routes] Traveling to Loping Plains
    call tso_routes_get_to_loping

    ; Navigate to the portal chamber
    echo [TSO Routes] Navigating to portal chamber
    call tso_play_waypoint_file "Loping Plains/to_portal_chamber.xml"

    ; Now navigate to the specific instance based on ZoneName
    switch ${ZoneName}
    {
        case Evernight Abbey
            echo [TSO Routes] Entering Evernight Abbey
            call tso_play_waypoint_file "Loping Plains/to_evernight_abbey.xml"
            break
        case Mistmyr Manor
            echo [TSO Routes] Entering Mistmyr Manor
            call tso_play_waypoint_file "Loping Plains/to_mistmyr_manor.xml"
            break
        case Ravenscale Repository
            echo [TSO Routes] Entering Ravenscale Repository
            call tso_play_waypoint_file "Loping Plains/to_ravenscale_repository.xml"
            break
        default
            echo [TSO Routes] ERROR: Unknown zone ${ZoneName}
            return
    }

    ; Wait for zoning into instance
    echo [TSO Routes] Waiting for zone to ${ZoneName}
    call wait_for_zone "${ZoneName}"
    echo [TSO Routes] Arrived at ${ZoneName}
}

function tso_play_waypoint_file(string RelativePath)
{
    ; Build full path to waypoint file
    variable string waypointPath = "${PATH_JB}/waypoints/${RelativePath}"

    echo [TSO Routes] Loading waypoint file: ${waypointPath}

    ; Set the path and load it
    UIElement[${JBUI_Playback_PathFile_TextEntry}]:SetText["${waypointPath}"]
    JBUI_Playback_PathFile:Set["${waypointPath}"]
    call JBUI_Playback_ReadAndCountFile

    JBUI_Playback_TotalItems:Set[${Math.Calc[${JBUI_Playback_WaypointCount} + ${JBUI_Playback_CommandCount}]}]
    JBUI_Playback_CurrentIndex:Set[0]
    JBUI_Playback_Loaded:Set[TRUE]

    echo [TSO Routes] Loaded ${JBUI_Playback_WaypointCount} waypoints and ${JBUI_Playback_CommandCount} commands

    ; Start playback
    JBUI_Playback_IsPlaying:Set[TRUE]
    JBUI_Playback_IsPaused:Set[FALSE]
    JBUI_Stuck_Count:Set[0]

    echo [TSO Routes] Starting playback...

    ; Wait for playback to complete
    while ${JBUI_Playback_IsPlaying}
    {
        wait 10
    }

    echo [TSO Routes] Playback complete
}