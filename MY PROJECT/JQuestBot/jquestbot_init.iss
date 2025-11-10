; =====================================================
; J Quest Bot Initialization
; =====================================================

variable string JQB_BaseDir="${LavishScript.HomeDirectory}/jcommon/JQuestBot/"

function main()
{
    echo ================================================
    echo J Quest Bot System - Initialization
    echo ================================================
    
    call CreateDirectories
    call CreateDefaultConfig
    call CreateExampleTask
    call DisplayInfo
    
    echo ================================================
    echo J Quest Bot initialization complete!
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
    
    echo Directories created
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
        \"version\": \"4.0.0\",
        \"ogre_relay_group\": \"all\",
        \"recovery_mode\": {
            \"enabled\": true,
            \"max_attempts\": 3
        },
        \"navigation\": {
            \"precision\": 3,
            \"wait_for_movement\": true
        },
        \"debug\": {
            \"log_commands\": true,
            \"verbose_output\": false
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
        \"task_name\": \"Example Task\",
        \"author\": \"Your Name\",
        \"version\": \"1.0.0\",
        \"description\": \"Example task file showing JSON format\",
        \"zone_name\": \"Any Zone\",
        \"group_size\": 1,
        \"steps\": [
            {
                \"step\": 1,
                \"command\": \"QuestBot: Author_Message\",
                \"parameters\": [
                    \"Welcome to J Quest Bot!\"
                ],
                \"description\": \"Welcome message\",
                \"enabled\": true
            },
            {
                \"step\": 2,
                \"command\": \"QuestBot: Wait\",
                \"parameters\": [
                    \"5\"
                ],
                \"description\": \"Wait 5 seconds\",
                \"enabled\": true
            },
            {
                \"step\": 3,
                \"command\": \"QuestBot: Author_Message\",
                \"parameters\": [
                    \"This is an example task file in JSON format\"
                ],
                \"description\": \"Info message\",
                \"enabled\": true
            },
            {
                \"step\": 4,
                \"command\": \"OgreBot: CampSpot\",
                \"parameters\": [
                    \"all\",
                    \"2\",
                    \"500\"
                ],
                \"description\": \"Set camp spot\",
                \"enabled\": true
            },
            {
                \"step\": 5,
                \"command\": \"QuestBot: Author_Message\",
                \"parameters\": [
                    \"Example task complete! Check the task file to see the JSON structure.\"
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
    echo ================================================
    echo
    echo TASK FILE FORMAT (JSON):
    echo   See example_task.json for structure
    echo   Place .json files in tasks/ directory
    echo
    echo COMMAND TYPES:
    echo   - OgreBot: commands
    echo   - OgreBot Custom: commands
    echo   - OgreCraft: commands
    echo   - QuestBot: commands
    echo
    echo ================================================
}

function atexit()
{
    echo J Quest Bot initialization complete
}