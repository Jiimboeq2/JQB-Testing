; =====================================================
; J Quest Bot Initialization - FIXED PATHS
; =====================================================

variable(global) string J_QuestBot_Path = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/"

function main()
{
    echo ================================================
    echo J Quest Bot System - Initialization
    echo ================================================

    call CreateDirectories
    call CreateDefaultConfig
    call CreateExampleTask
    call CreateExampleQueue
    call DisplayInfo

    echo ================================================
    echo J Quest Bot initialization complete!
    echo ================================================
    echo
    echo Next steps:
    echo 1. Run: run Eq2JCommon/JQuestBot/JQuestBot task_name
    echo 2. Or use: run J_System_Bootstrap all
    echo 3. Check: ${JQB_BaseDir}
    echo ================================================
}

function CreateDirectories()
{
    echo Creating directory structure...

    if !${System.FileExists["${JQB_BaseDir}"]}
    System:CreateDirectory["${JQB_BaseDir}"]

    if !${System.FileExists["${JQB_BaseDir}tasks/"]}
    System:CreateDirectory["${JQB_BaseDir}tasks/"]

    if !${System.FileExists["${JQB_BaseDir}config/"]}
    System:CreateDirectory["${JQB_BaseDir}config/"]

    if !${System.FileExists["${JQB_BaseDir}queues/"]}
    System:CreateDirectory["${JQB_BaseDir}queues/"]

    if !${System.FileExists["${JQB_BaseDir}logs/"]}
    System:CreateDirectory["${JQB_BaseDir}logs/"]

    echo Directory structure created
}

function CreateDefaultConfig()
{
    variable filepath ConfigFile="${JQB_BaseDir}config/questbot_config.json"

    if ${System.FileExists["${ConfigFile}"]}
    {
        echo Config already exists, skipping
        return
    }

    echo Creating default configuration...

    variable jsonvalue config
    config:SetValue["$$>
    {
        \"version\": \"2.0.0\",
        \"release_date\": \"2025.10.19\",
        \"ogre_relay_group\": \"all\",
        \"recovery_mode\": {
            \"enabled\": true,
            \"max_attempts\": 3
        },
        \"navigation\": {
            \"precision\": 3,
            \"wait_for_movement\": true,
            \"stuck_detection\": true
        },
        \"quest_tracking\": {
            \"verify_steps\": true,
            \"auto_accept_rewards\": false
        },
        \"debug\": {
            \"log_commands\": true,
            \"verbose_output\": false,
            \"save_logs\": false
        }
    }
    <$$"]

    ConfigFile:WriteFile["${config}",multiline]
    echo Configuration created
}

function CreateExampleTask()
{
    variable filepath TaskFile="${JQB_BaseDir}tasks/example_task.json"

    if ${System.FileExists["${TaskFile}"]}
    {
        echo Example task already exists, skipping
        return
    }

    echo Creating example task...

    variable jsonvalue task
    task:SetValue["$$>
    {
        \"task_name\": \"Example Quest Task\",
        \"author\": \"J System\",
        \"version\": \"1.0.0\",
        \"description\": \"Example task file showing JSON format\",
        \"zone_name\": \"Any Zone\",
        \"group_size\": 1,
        \"steps\": [
        {
            \"step\": 1,
            \"command\": \"QuestBot: Author_Message\",
            \"parameters\": [
            \"Welcome to J Quest Bot! This is an example task.\"
            ],
            \"description\": \"Welcome message\",
            \"enabled\": true
        },
        {
            \"step\": 2,
            \"command\": \"QuestBot: Wait\",
            \"parameters\": [5],
            \"description\": \"Wait 5 seconds\",
            \"enabled\": true
        },
        {
            \"step\": 3,
            \"command\": \"QuestBot: Hail\",
            \"parameters\": [\"NPC Name\"],
            \"description\": \"Hail an NPC\",
            \"enabled\": false,
            \"note\": \"Disabled - enable and set NPC name to use\"
        },
        {
            \"step\": 4,
            \"command\": \"OgreBot: CampSpot\",
            \"parameters\": [\"all\", 2, 500],
            \"description\": \"Set camp spot\",
            \"enabled\": true
        },
        {
            \"step\": 5,
            \"command\": \"QuestBot: Author_Message\",
            \"parameters\": [
            \"Example task complete! Edit tasks/example_task.json to customize.\"
            ],
            \"description\": \"Completion message\",
            \"enabled\": true
        }
        ]
    }
    <$$"]

    TaskFile:WriteFile["${task}",multiline]
    echo Example task created
}

function CreateExampleQueue()
{
    variable filepath QueueFile="${JQB_BaseDir}queues/example_queue.json"

    if ${System.FileExists["${QueueFile}"]}
    {
        echo Example queue already exists, skipping
        return
    }

    echo Creating example queue...

    variable jsonvalue queue
    queue:SetValue["$$>
    {
        \"queue_name\": \"Example Task Queue\",
        \"description\": \"Runs multiple tasks in sequence\",
        \"author\": \"J System\",
        \"version\": \"1.0.0\",
        \"tasks\": [
        \"example_task\",
        \"another_task\"
        ]
    }
    <$$"]

    QueueFile:WriteFile["${queue}",multiline]
    echo Example queue created
}

function DisplayInfo()
{
    echo
    echo ================================================
    echo J Quest Bot System Information
    echo ================================================
    echo Base Directory: ${JQB_BaseDir}
    echo Tasks Directory: ${JQB_BaseDir}tasks/
    echo Queues Directory: ${JQB_BaseDir}queues/
    echo Config Directory: ${JQB_BaseDir}config/
    echo Logs Directory: ${JQB_BaseDir}logs/
    echo ================================================
    echo
    echo TASK FILE FORMAT (JSON):
    echo   See example_task.json for structure
    echo   Place .json files in tasks/ directory
    echo
    echo COMMAND TYPES:
    echo   - OgreBot: commands
    echo   - QuestBot: commands
    echo   - OgreCraft: commands
    echo   - navigate (uses JNavigation)
    echo   - wait
    echo   - chat
    echo
    echo RUNNING TASKS:
    echo   run
}