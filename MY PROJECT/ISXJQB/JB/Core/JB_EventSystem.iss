/*
 * JB_EventSystem.iss
 *
 * Event-driven automation system for XML waypoint playback
 * Bridges the gap between simple linear playback and complex instance scripts
 *
 * Features:
 * - Event triggers (chat text, actor spawns, detrimental stacks)
 * - Action blocks (reusable command sequences)
 * - State variables (track phases, counters, etc.)
 * - Conditional execution (if/while/waituntil)
 *
 * Usage:
 *   #include "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JB_EventSystem.iss"
 *
 * XML Format:
 *   <EventTrigger Type="ChatText" Match="plants her feet" Action="JoustOut" />
 *   <EventTrigger Type="ActorSpawn" Match="Boss Name" Action="StartFight" />
 *   <EventTrigger Type="DetrimentalStacks" Actor="Boss" MainID="273" BackdropID="33085" HighStacks="8" Action="MoveToLand" />
 *
 *   <Action Name="JoustOut">
 *       <Waypoint X="50" Y="20" Z="-100" />
 *       <Command Type="Wait" Value="30" />
 *   </Action>
 */

variable(global) string JB_EventSystem_Version = "1.0.0"

/*
 * =====================================================
 * EVENT TRIGGER STORAGE
 * =====================================================
 * Store up to 50 event triggers
 */
; ChatText, ActorSpawn, ActorDeath, DetrimentalStacks, etc.
variable(global) int JB_Event_Count = 0
variable(global) string JB_Event_Type[50]
variable(global) string JB_Event_Match[50]
variable(global) string JB_Event_Action[50]
variable(global) bool JB_Event_Enabled[50]
variable(global) bool JB_Event_OneShot[50]

; Additional parameters for specific event types
variable(global) string JB_Event_Actor[50]
variable(global) int JB_Event_MainID[50]
variable(global) int JB_Event_BackdropID[50]
variable(global) int JB_Event_HighStacks[50]
variable(global) int JB_Event_LowStacks[50]

/*
 * =====================================================
 * ACTION BLOCK STORAGE
 * =====================================================
 * Store up to 50 action blocks, each with up to 100 commands
 */
variable(global) int JB_Action_Count = 0
variable(global) string JB_Action_Name[50]
variable(global) int JB_Action_CmdCount[50]
variable(global) string JB_Action_Commands[50,100]

/*
 * =====================================================
 * STATE VARIABLES
 * =====================================================
 * Track state during playback (up to 50 variables)
 */
variable(global) int JB_StateVar_Count = 0
variable(global) string JB_StateVar_Name[50]
variable(global) string JB_StateVar_Value[50]

/*
 * =====================================================
 * EVENT REGISTRATION
 * =====================================================
 */

function JB_Event_Register(string eventType, string matchText, string actionName, bool oneShot=FALSE)
{
    if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
        echo [Debug:Events] Registering event - Type:${eventType}, Match:"${matchText}", Action:${actionName}, OneShot:${oneShot}

    if ${JB_Event_Count} >= 50
    {
        echo ${Time}: [EventSystem] ERROR: Maximum 50 event triggers reached
        if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
            echo [Debug:Events] Registration FAILED - Event limit (50) reached
        return
    }

    variable int idx = ${JB_Event_Count}
    JB_Event_Type[${idx}]:Set["${eventType}"]
    JB_Event_Match[${idx}]:Set["${matchText}"]
    JB_Event_Action[${idx}]:Set["${actionName}"]
    JB_Event_Enabled[${idx}]:Set[TRUE]
    JB_Event_OneShot[${idx}]:Set[${oneShot}]

    JB_Event_Count:Inc
    echo ${Time}: [EventSystem] Registered ${eventType} trigger: "${matchText}" -> Action: ${actionName}
    if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
        echo [Debug:Events] Registration SUCCESS - Event index:${idx}, Total events:${JB_Event_Count}
}

function JB_Event_Register_DetrimentalStacks(string actorName, int mainID, int backdropID, int highStacks, int lowStacks, string actionName)
{
    if ${JB_Event_Count} >= 50
    {
        echo ${Time}: [EventSystem] ERROR: Maximum 50 event triggers reached
        return
    }

    variable int idx = ${JB_Event_Count}
    JB_Event_Type[${idx}]:Set["DetrimentalStacks"]
    JB_Event_Actor[${idx}]:Set["${actorName}"]
    JB_Event_MainID[${idx}]:Set[${mainID}]
    JB_Event_BackdropID[${idx}]:Set[${backdropID}]
    JB_Event_HighStacks[${idx}]:Set[${highStacks}]
    JB_Event_LowStacks[${idx}]:Set[${lowStacks}]
    JB_Event_Action[${idx}]:Set["${actionName}"]
    JB_Event_Enabled[${idx}]:Set[TRUE]
    JB_Event_OneShot[${idx}]:Set[FALSE]

    JB_Event_Count:Inc
    echo ${Time}: [EventSystem] Registered DetrimentalStacks trigger for ${actorName} -> Action: ${actionName}
}

function JB_Event_Clear()
{
    variable int i
    JB_Event_Count:Set[0]
    for (i:Set[0]; ${i} < 50; i:Inc)
    {
        JB_Event_Type[${i}]:Set[""]
        JB_Event_Match[${i}]:Set[""]
        JB_Event_Action[${i}]:Set[""]
        JB_Event_Enabled[${i}]:Set[FALSE]
        JB_Event_OneShot[${i}]:Set[FALSE]
    }
    echo ${Time}: [EventSystem] Cleared all event triggers
}

/*
 * =====================================================
 * ACTION BLOCK MANAGEMENT
 * =====================================================
 */

function JB_Action_Start(string actionName)
{
    if ${JB_Action_Count} >= 50
    {
        echo ${Time}: [EventSystem] ERROR: Maximum 50 action blocks reached
        return
    }

    variable int idx = ${JB_Action_Count}
    JB_Action_Name[${idx}]:Set["${actionName}"]
    JB_Action_CmdCount[${idx}]:Set[0]

    JB_Action_Count:Inc
    echo ${Time}: [EventSystem] Started action block: ${actionName}
}

function JB_Action_AddCommand(string actionName, string xmlCommand)
{
    ; Find the action block
    variable int i
    variable int actionIdx = -1

    for (i:Set[0]; ${i} < ${JB_Action_Count}; i:Inc)
    {
        if ${JB_Action_Name[${i}].Equal["${actionName}"]}
        {
            actionIdx:Set[${i}]
            break
        }
    }

    if ${actionIdx} < 0
    {
        echo ${Time}: [EventSystem] ERROR: Action block not found: ${actionName}
        return
    }

    variable int cmdIdx = ${JB_Action_CmdCount[${actionIdx}]}
    if ${cmdIdx} >= 100
    {
        echo ${Time}: [EventSystem] ERROR: Action ${actionName} has reached max 100 commands
        return
    }

    JB_Action_Commands[${actionIdx},${cmdIdx}]:Set["${xmlCommand}"]
    JB_Action_CmdCount[${actionIdx}]:Inc
}

function JB_Action_Execute(string actionName)
{
    if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
        echo [Debug:Events] Executing action - Name:${actionName}, Searching ${JB_Action_Count} action blocks

    ; Find the action block
    variable int i
    variable int actionIdx = -1

    for (i:Set[0]; ${i} < ${JB_Action_Count}; i:Inc)
    {
        if ${JB_Action_Name[${i}].Equal["${actionName}"]}
        {
            actionIdx:Set[${i}]
            break
        }
    }

    if ${actionIdx} < 0
    {
        echo ${Time}: [EventSystem] ERROR: Action block not found: ${actionName}
        if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
            echo [Debug:Events] Action FAILED - ${actionName} not found in registered actions
        return
    }

    echo ${Time}: [EventSystem] Executing action: ${actionName} (${JB_Action_CmdCount[${actionIdx}]} commands)
    if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
        echo [Debug:Events] Action found - Index:${actionIdx}, Commands:${JB_Action_CmdCount[${actionIdx}]}

    ; Execute each command in the action
    variable int cmdIdx
    for (cmdIdx:Set[0]; ${cmdIdx} < ${JB_Action_CmdCount[${actionIdx}]}; cmdIdx:Inc)
    {
        variable string xmlLine = "${JB_Action_Commands[${actionIdx},${cmdIdx}]}"

        if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
            echo [Debug:Events] Executing command ${Math.Calc[${cmdIdx}+1]}/${JB_Action_CmdCount[${actionIdx}]} - XML:${xmlLine.Left[50]}...

        ; Determine if it's a waypoint or command
        if ${xmlLine.Find["<Waypoint"]}
        {
            call JBUI_Playback_ExecuteWaypoint "${xmlLine}"
        }
        elseif ${xmlLine.Find["<Command"]}
        {
            call JBUI_Playback_ExecuteCommand "${xmlLine}"
        }
    }

    echo ${Time}: [EventSystem] Completed action: ${actionName}
    if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
        echo [Debug:Events] Action completed successfully - Name:${actionName}, Commands executed:${JB_Action_CmdCount[${actionIdx}]}
}

function JB_Action_Clear()
{
    variable int i
    variable int j
    JB_Action_Count:Set[0]
    for (i:Set[0]; ${i} < 50; i:Inc)
    {
        JB_Action_Name[${i}]:Set[""]
        JB_Action_CmdCount[${i}]:Set[0]
        for (j:Set[0]; ${j} < 100; j:Inc)
        {
            JB_Action_Commands[${i},${j}]:Set[""]
        }
    }
    echo ${Time}: [EventSystem] Cleared all action blocks
}

/*
 * =====================================================
 * STATE VARIABLE MANAGEMENT
 * =====================================================
 */

function JB_StateVar_Set(string varName, string value)
{
    ; Check if variable exists
    variable int i
    variable int varIdx = -1

    for (i:Set[0]; ${i} < ${JB_StateVar_Count}; i:Inc)
    {
        if ${JB_StateVar_Name[${i}].Equal["${varName}"]}
        {
            varIdx:Set[${i}]
            break
        }
    }

    ; If not found, create it
    if ${varIdx} < 0
    {
        if ${JB_StateVar_Count} >= 50
        {
            echo ${Time}: [EventSystem] ERROR: Maximum 50 state variables reached
            return
        }
        varIdx:Set[${JB_StateVar_Count}]
        JB_StateVar_Name[${varIdx}]:Set["${varName}"]
        JB_StateVar_Count:Inc
        if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
            echo [Debug:Events] Created new state variable - Name:${varName}, Index:${varIdx}, Total variables:${JB_StateVar_Count}
    }
    else
    {
        if ${JBUI_Debug_Events(exists)} && ${JBUI_Debug_Events}
            echo [Debug:Events] Updating existing state variable - Name:${varName}, Old value:"${JB_StateVar_Value[${varIdx}]}", New value:"${value}"
    }

    JB_StateVar_Value[${varIdx}]:Set["${value}"]
    echo ${Time}: [EventSystem] Set variable ${varName} = ${value}
}

function:string JB_StateVar_Get(string varName)
{
    variable int i
    for (i:Set[0]; ${i} < ${JB_StateVar_Count}; i:Inc)
    {
        if ${JB_StateVar_Name[${i}].Equal["${varName}"]}
            return "${JB_StateVar_Value[${i}]}"
    }
    return ""
}

function JB_StateVar_Clear()
{
    variable int i
    JB_StateVar_Count:Set[0]
    for (i:Set[0]; ${i} < 50; i:Inc)
    {
        JB_StateVar_Name[${i}]:Set[""]
        JB_StateVar_Value[${i}]:Set[""]
    }
    echo ${Time}: [EventSystem] Cleared all state variables
}

/*
 * =====================================================
 * EVENT MONITORING & CHECKING
 * =====================================================
 */

function JB_Event_CheckAll()
{
    ; Called during playback to check if any events should trigger
    ; This should be called every frame or every few deciseconds

    variable int i
    for (i:Set[0]; ${i} < ${JB_Event_Count}; i:Inc)
    {
        if !${JB_Event_Enabled[${i}]}
            continue

        switch ${JB_Event_Type[${i}]}
        {
            case ActorSpawn
                call JB_Event_Check_ActorSpawn ${i}
                break
            case ActorDeath
                call JB_Event_Check_ActorDeath ${i}
                break
            case DetrimentalStacks
                call JB_Event_Check_DetrimentalStacks ${i}
                break
            ; ChatText is handled by atom below
        }
    }
}

function JB_Event_Check_ActorSpawn(int idx)
{
    variable string actorName = "${JB_Event_Match[${idx}]}"

    if ${Actor["${actorName}"](exists)}
    {
        echo ${Time}: [EventSystem] Actor spawned trigger: ${actorName}
        call JB_Action_Execute "${JB_Event_Action[${idx}]}"

        if ${JB_Event_OneShot[${idx}]}
            JB_Event_Enabled[${idx}]:Set[FALSE]
    }
}

function JB_Event_Check_ActorDeath(int idx)
{
    variable string actorName = "${JB_Event_Match[${idx}]}"

    if ${Actor["${actorName}"](exists)} && ${Actor["${actorName}"].IsDead}
    {
        echo ${Time}: [EventSystem] Actor death trigger: ${actorName}
        call JB_Action_Execute "${JB_Event_Action[${idx}]}"

        if ${JB_Event_OneShot[${idx}]}
            JB_Event_Enabled[${idx}]:Set[FALSE]
    }
}

function JB_Event_Check_DetrimentalStacks(int idx)
{
    variable string actorName = "${JB_Event_Actor[${idx}]}"

    if !${Actor["${actorName}"](exists)}
        return

    variable int64 actorID = ${Actor["${actorName}"].ID}
    variable int currentStacks = ${OgreBotAPI.DetrimentalInfo[${JB_Event_MainID[${idx}]},${JB_Event_BackdropID[${idx}]},${actorID},"CurrentIncrements"]}

    variable bool shouldTrigger = FALSE

    ; Check if stacks >= HighStacks or <= LowStacks
    if ${JB_Event_HighStacks[${idx}]} > 0 && ${currentStacks} >= ${JB_Event_HighStacks[${idx}]}
        shouldTrigger:Set[TRUE]

    if ${JB_Event_LowStacks[${idx}]} > 0 && ${currentStacks} <= ${JB_Event_LowStacks[${idx}]}
        shouldTrigger:Set[TRUE]

    if ${shouldTrigger}
    {
        echo ${Time}: [EventSystem] Detrimental stacks trigger: ${actorName} has ${currentStacks} stacks
        call JB_Action_Execute "${JB_Event_Action[${idx}]}"

        if ${JB_Event_OneShot[${idx}]}
            JB_Event_Enabled[${idx}]:Set[FALSE]
    }
}

/*
 * =====================================================
 * CHAT TEXT EVENT MONITORING
 * =====================================================
 * This atom is attached to EQ2_onIncomingText
 */

atom(global) JB_Event_ChatText_Atom(string Message)
{
    variable int i
    for (i:Set[0]; ${i} < ${JB_Event_Count}; i:Inc)
    {
        if !${JB_Event_Enabled[${i}]}
            continue

        if !${JB_Event_Type[${i}].Equal["ChatText"]}
            continue

        if ${Message.Find["${JB_Event_Match[${i}]}"]}
        {
            echo ${Time}: [EventSystem] Chat text trigger: "${JB_Event_Match[${i}]}"
            call JB_Action_Execute "${JB_Event_Action[${i}]}"

            if ${JB_Event_OneShot[${i}]}
                JB_Event_Enabled[${i}]:Set[FALSE]
        }
    }
}

/*
 * =====================================================
 * EVENT SYSTEM INITIALIZATION & CLEANUP
 * =====================================================
 */

function JB_EventSystem_Start()
{
    echo ${Time}: [EventSystem] Starting event system
    Event[EQ2_onIncomingText]:AttachAtom[JB_Event_ChatText_Atom]
}

function JB_EventSystem_Stop()
{
    echo ${Time}: [EventSystem] Stopping event system
    Event[EQ2_onIncomingText]:DetachAtom[JB_Event_ChatText_Atom]
    call JB_Event_Clear
    call JB_Action_Clear
    call JB_StateVar_Clear
}
