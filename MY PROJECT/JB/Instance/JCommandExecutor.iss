

objectdef JCommandExecutor
{
    variable int CommandsExecuted = 0
    variable int CommandsFailed = 0
    variable string LastError = ""
    variable bool Initialized = FALSE

    method Initialize()
    {
        
        echo ${Time}: [CommandExecutor] Initializing...

        echo ${Time}: [CommandExecutor] JCommandExecutor loaded
        This.CommandsExecuted:Set[0]
        This.CommandsFailed:Set[0]
        This.LastError:Set[""]
        This.Initialized:Set[TRUE]

        echo ${Time}: [CommandExecutor] Ready
    }

    method ExecuteCommand(string commandDataString)
    {
        if !${This.Initialized}
        {
            echo ${Time}: [CommandExecutor] ERROR: Not initialized
            return
        }

        variable jsonvalue commandData
        commandData:SetValue["${commandDataString}"]

        variable string command = "${commandData.Get["command"]}"
        variable jsonvalue parameters

        if ${commandData.Has["parameters"]}
        {
            parameters:SetReference["commandData.Get[\"parameters\"]"]
        }

        This.CommandsExecuted:Inc

        ; Route to appropriate handler based on command prefix
        if ${command.Find["OgreBot:"]}
        {
            call This.HandleOgreBotCommand "${command}" "${parameters}"
        }
        elseif ${command.Find["QuestBot:"]}
        {
            call This.HandleQuestBotCommand "${command}" "${parameters}"
        }
        ; ... rest of your handlers
        else
        {
            echo ${Time}: [CommandExecutor] Unknown command type: ${command}
            This.CommandsFailed:Inc
            This.LastError:Set["Unknown command: ${command}"]
        }
    }

    method HandleOgreBotCommand(string command, jsonvalue params)
    {
        variable string cmdType = "${command.Right[${Math.Calc[${command.Length}-9]}]}"

        echo ${Time}: [Ogre] ${cmdType}

        switch ${cmdType}
        {
            case CampSpot
                call This.OB_CampSpot "${params}"
                break
            case ChangeCampSpot
                call This.OB_ChangeCampSpot "${params}"
                break
            case AddAutoTargetByName
                call This.OB_AddAutoTarget "${params}"
                break
            case ClearAutoTarget
                call This.OB_ClearAutoTarget "${params}"
                break
            case SetAutoTargetRadius
                call This.OB_SetAutoTargetRadius "${params}"
                break
            case Attack
                call This.OB_Attack "${params}"
                break
            case EnableMoveBehind
                call This.OB_EnableMoveBehind "${params}"
                break
            case DisableMoveBehind
                call This.OB_DisableMoveBehind "${params}"
                break
            case JoustOut
                call This.OB_JoustOut "${params}"
                break
            case JoustIn
                call This.OB_JoustIn "${params}"
                break
            default
            echo ${Time}: [Ogre] Unknown OgreBot command: ${cmdType}
            This.CommandsFailed:Inc
            break
        }
    }

    method OB_CampSpot(jsonvalue params)
    {
        variable string who = "all"
        variable int mode = 2
        variable int range = 500

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        mode:Set[${params.Get[1]}]
        if ${params.Size} >= 3
        range:Set[${params.Get[2]}]

        relay "${who}" "oc !c -CampSpot ${mode} ${range}"
        wait 5
    }

    method OB_ChangeCampSpot(jsonvalue params)
    {
        variable string who = "all"
        variable string location = ""

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        location:Set["${params.Get[1]}"]

        relay "${who}" "oc !c -ChangeCampSpot ${who} ${location}"
        wait 5
    }

    method OB_AddAutoTarget(jsonvalue params)
    {
        variable string who = "all"
        variable string targetName = ""
        variable int priority = 0

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        targetName:Set["${params.Get[1]}"]
        if ${params.Size} >= 3
        priority:Set[${params.Get[2]}]

        relay "${who}" "Ob_AutoTarget:AddActor[\"${targetName}\",${priority}]"
        wait 5
    }

    method OB_ClearAutoTarget(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "Ob_AutoTarget:Clear"
        wait 5
    }

    method OB_SetAutoTargetRadius(jsonvalue params)
    {
        variable string who = "all"
        variable int radius = 40

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        radius:Set[${params.Get[1]}]

        relay "${who}" "UIElement[${OBUI_slider_autotarget_scanradius}]:SetValue[${radius}]"
        wait 5
    }

    method OB_Attack(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "press AUTOATTACK"
        wait 5
    }

    method OB_EnableMoveBehind(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "if !$\{UIElement[${OBUI_checkbox_settings_movebehind}].Checked} UIElement[${OBUI_checkbox_settings_movebehind}]:LeftClick"
        wait 5
    }

    method OB_DisableMoveBehind(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "if $\{UIElement[${OBUI_checkbox_settings_movebehind}].Checked} UIElement[${OBUI_checkbox_settings_movebehind}]:LeftClick"
        wait 5
    }

    method OB_JoustOut(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustOut]"
        wait 5
    }

    method OB_JoustIn(jsonvalue params)
    {
        variable string who = "all"

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]

        relay "${who}" "Script[\${OgreBotScriptName}]:ExecuteAtom[aJoustIn]"
        wait 5
    }

    ; =====================================================
    ; QUESTBOT COMMANDS
    ; =====================================================

    method HandleQuestBotCommand(string command, jsonvalue params)
    {
        variable string cmdType = "${command.Right[${Math.Calc[${command.Length}-10]}]}"

        echo ${Time}: [QuestBot] ${cmdType}

        switch ${cmdType}
        {
            case Wait
                call This.QB_Wait "${params}"
                break
            case Author_Message
                call This.QB_AuthorMessage "${params}"
                break
            case Hail
                call This.QB_Hail "${params}"
                break
            case Actor_DoubleClick
                call This.QB_ActorDoubleClick "${params}"
                break
            case Apply_Verb
                call This.QB_ApplyVerb "${params}"
                break
            case Use_Item
                call This.QB_UseItem "${params}"
                break
            case Confirm_ZoneName
                call This.QB_ConfirmZoneName "${params}"
                break
            case Movement_SetUpFor
                call This.QB_MovementSetupFor "${params}"
                break
            case Wait_For_Combat
                call This.QB_WaitForCombat "${params}"
                break
            case Wait_While_Combat
                call This.QB_WaitWhileCombat "${params}"
                break
            case QuestJournal
                call This.QB_QuestJournalInfo "${params}"
                break
            case WaitForZone
                call This.QB_WaitForZone "${params}"
                break
            default
            echo ${Time}: [QuestBot] Unknown command: ${cmdType}
            This.CommandsFailed:Inc
            break
        }
    }

    method QB_Wait(jsonvalue params)
    {
        variable int waitTime = 10

        if ${params.Size} >= 1
        waitTime:Set[${params.Get[0]}]

        echo ${Time}: [Wait] ${waitTime} deciseconds
        wait ${waitTime}
    }

    method QB_AuthorMessage(jsonvalue params)
    {
        variable string message = ""

        if ${params.Size} >= 1
        message:Set["${params.Get[0]}"]

        echo ${Time}: [Message] ${message}
        relay all "oc ${message}"
    }

    method QB_Hail(jsonvalue params)
    {
        variable string actorName = ""

        if ${params.Size} >= 1
        actorName:Set["${params.Get[0]}"]

        variable int actorID = ${Actor["${actorName}"].ID}

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
            echo ${Time}: [Hail] Actor not found: ${actorName}
            This.CommandsFailed:Inc
            This.LastError:Set["Actor not found: ${actorName}"]
        }
    }

    method QB_ActorDoubleClick(jsonvalue params)
    {
        variable string actorName = ""

        if ${params.Size} >= 1
        actorName:Set["${params.Get[0]}"]

        variable int actorID = ${Actor["${actorName}"].ID}

        if ${actorID}
        {
            echo ${Time}: [DoubleClick] ${actorName}
            Actor[${actorID}]:DoubleClick
            wait 10
        }
        else
        {
            echo ${Time}: [DoubleClick] Actor not found: ${actorName}
            This.CommandsFailed:Inc
            This.LastError:Set["Actor not found: ${actorName}"]
        }
    }

    method QB_ApplyVerb(jsonvalue params)
    {
        variable string actorName = ""
        variable string verbName = ""

        if ${params.Size} >= 1
        actorName:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        verbName:Set["${params.Get[1]}"]

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
            echo ${Time}: [ApplyVerb] Actor not found: ${actorName}
            This.CommandsFailed:Inc
            This.LastError:Set["Actor not found: ${actorName}"]
        }
    }

    method QB_UseItem(jsonvalue params)
    {
        variable string itemName = ""

        if ${params.Size} >= 1
        itemName:Set["${params.Get[0]}"]

        echo ${Time}: [UseItem] ${itemName}

        ; Try to use item from inventory
        if ${Me.Inventory["${itemName}"](exists)}
        {
            Me.Inventory["${itemName}"]:Use
            wait 10
        }
        else
        {
            echo ${Time}: [UseItem] Item not found: ${itemName}
            This.CommandsFailed:Inc
            This.LastError:Set["Item not found: ${itemName}"]
        }
    }

    method QB_ConfirmZoneName(jsonvalue params)
    {
        variable string who = "all"
        variable string zoneName = ""

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        zoneName:Set["${params.Get[1]}"]

        echo ${Time}: [ConfirmZone] Verifying zone: ${zoneName}

        if !${Zone.Name.Equal["${zoneName}"]}
        {
            echo ${Time}: [ConfirmZone] Wrong zone! Expected: ${zoneName}, Got: ${Zone.Name}
            This.CommandsFailed:Inc
            This.LastError:Set["Wrong zone"]
        }
        else
        {
            echo ${Time}: [ConfirmZone] Correct zone
        }
    }

    method QB_MovementSetupFor(jsonvalue params)
    {
        variable string who = "all"
        variable string encounter = ""

        if ${params.Size} >= 1
        who:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        encounter:Set["${params.Get[1]}"]

        echo ${Time}: [MovementSetup] ${encounter}
        relay "${who}" "/say ${encounter}"
        wait 10
    }

    method QB_WaitForCombat(jsonvalue params)
    {
        variable int timeout = 300

        if ${params.Size} >= 1
        timeout:Set[${params.Get[0]}]

        echo ${Time}: [WaitForCombat] Waiting up to ${Math.Calc[${timeout}/10]} seconds...

        variable int counter = 0
        while !${Me.InCombat} && ${counter} < ${timeout}
        {
            wait 10
            counter:Inc
        }

        if ${Me.InCombat}
        {
            echo ${Time}: [WaitForCombat] Combat started
        }
        else
        {
            echo ${Time}: [WaitForCombat] Timeout
            This.CommandsFailed:Inc
            This.LastError:Set["Combat timeout"]
        }
    }

    method QB_WaitWhileCombat(jsonvalue params)
    {
        echo ${Time}: [WaitWhileCombat] Waiting for combat to end...

        while ${Me.InCombat}
        {
            wait 10
        }

        echo ${Time}: [WaitWhileCombat] Combat ended
        wait 20
    }

    method QB_QuestJournalInfo(jsonvalue params)
    {
        ; Quest journal checking - implemented in separate include file
        echo ${Time}: [QuestJournal] Checking quest status...
    }

    method QB_WaitForZone(jsonvalue params)
    {
        variable string zoneName = ""
        variable int timeout = 60

        if ${params.Size} >= 1
        zoneName:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        timeout:Set[${params.Get[1]}]

        echo ${Time}: [WaitForZone] Waiting for: ${zoneName}

        variable int counter = 0
        while !${Zone.Name.Equal["${zoneName}"]} && ${counter} < ${timeout}
        {
            wait 10
            counter:Inc
        }

        if ${Zone.Name.Equal["${zoneName}"]}
        {
            echo ${Time}: [WaitForZone] Zone loaded
        }
        else
        {
            echo ${Time}: [WaitForZone] Timeout
            This.CommandsFailed:Inc
        }
    }

    ; =====================================================
    ; NAVIGATION COMMANDS
    ; =====================================================

    method HandleNavigationCommand(string command, jsonvalue params)
    {
        echo ${Time}: [Navigate] Processing navigation command

        variable string pathName = ""
        variable bool reverse = FALSE
        variable bool preBuff = FALSE
        variable bool ignoreAggro = FALSE

        if ${params.Size} >= 1
        pathName:Set["${params.Get[0]}"]
        if ${params.Size} >= 2
        reverse:Set[${params.Get[1]}]
        if ${params.Size} >= 3
        preBuff:Set[${params.Get[2]}]
        if ${params.Size} >= 4
        ignoreAggro:Set[${params.Get[3]}]

        ; Call navigation system
        if ${Obj_JNav(exists)}
        {
            echo ${Time}: [Navigate] Path: ${pathName}, Reverse: ${reverse}
            call JCmd_Navigate "${pathName}" "${reverse}" "${preBuff}" "${ignoreAggro}"
        }
        else
        {
            echo ${Time}: [Navigate] Navigation system not loaded
            This.CommandsFailed:Inc
            This.LastError:Set["Navigation system not available"]
        }
    }

    ; =====================================================
    ; SIMPLE COMMANDS
    ; =====================================================

    method HandleWaitCommand(string command, jsonvalue params)
    {
        variable int waitTime = 10

        if ${params.Size} >= 1
        waitTime:Set[${params.Get[0]}]

        echo ${Time}: [Wait] ${waitTime} deciseconds
        wait ${waitTime}
    }

    method HandleChatCommand(string command, jsonvalue params)
    {
        variable string message = ""

        if ${params.Size} >= 1
        message:Set["${params.Get[0]}"]

        echo ${Time}: [Chat] ${message}
        eq2execute ${message}
        wait 5
    }

    method HandleOgreCraftCommand(string command, jsonvalue params)
    {
        echo ${Time}: [OgreCraft] Command: ${command}
        echo ${Time}: [OgreCraft] Not yet implemented
        This.CommandsFailed:Inc
    }

    ; =====================================================
    ; STATUS & STATS
    ; =====================================================


    method ResetStats()
    {
        This.CommandsExecuted:Set[0]
        This.CommandsFailed:Set[0]
        This.LastError:Set[""]
    }
}
