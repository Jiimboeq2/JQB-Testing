/*
 * JB - Main Launcher for J Common System
 * Path: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JB.iss
 * 
 * Usage:
 *   run JB run "Instance Name"         - Run an instance
 *   run JB task "Task Name"            - Run a quest/task
 *   run JB queue "Queue Name"          - Run a task queue
 *   run JB map                         - Start waypoint mapper
 *   run JB list                        - List available instances
 *   run JB list tasks                  - List available tasks
 *   run JB help                        - Show help
 *   run JB init                        - Initialize/setup JB system
 *   run JB test                        - Test all systems
 */

variable(global) string JB_Version = "2.0.0"
variable(global) string JB_ReleaseDate = "2025-10-19"
variable(global) string JB_BaseDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/"

function main(string command, string parameter="", string parameter2="")
{
    call ShowHeader
    
    ; Check if command provided
    if !${command.Length}
    {
        call ShowHelp
        return
    }
    
    ; Route to appropriate handler
    switch ${command.Lower}
    {
        case run
        case instance
            call RunInstance "${parameter}"
            break
            
        case task
        case quest
            call RunTask "${parameter}"
            break
            
        case queue
            call RunQueue "${parameter}"
            break
            
        case map
        case mapper
        case record
        case waypoints
            call StartMapper
            break
            
        case list
        case ls
            call ListItems "${parameter}"
            break
            
        case help
        case h
        case ?
            call ShowHelp
            break
            
        case init
        case initialize
        case setup
            call Initialize
            break
            
        case test
        case validate
        case check
            call TestSystems
            break
            
        case version
        case ver
        case v
            call ShowVersion
            break
            
        case status
        case info
            call ShowStatus
            break
            
        default
            echo ${Time}: Unknown command: ${command}
            echo
            call ShowHelp
            break
    }
}

function ShowHeader()
{
    echo ================================================
    echo JB - JSON-Based Bot System
    echo Version ${JB_Version} (${JB_ReleaseDate})
    echo ================================================
}

function ShowHelp()
{
    echo Commands:
    echo
    echo   INSTANCE MANAGEMENT:
    echo   -------------------
    echo   run JB run "Instance Name"
    echo     Run a JSON instance file
    echo     Example: run JB run "Kralet Penumbra"
    echo
    echo   run JB list
    echo     List all available instances
    echo
    echo   TASK MANAGEMENT:
    echo   ----------------
    echo   run JB task "Task Name"
    echo     Run a single task file
    echo     Example: run JB task "Daily Writs Carpenter"
    echo
    echo   run JB queue "Queue Name"
    echo     Run a task queue (multiple tasks in sequence)
    echo     Example: run JB queue "All Daily Writs"
    echo
    echo   run JB list tasks
    echo     List all available tasks
    echo
    echo   run JB list queues
    echo     List all available task queues
    echo
    echo   WAYPOINT RECORDING:
    echo   -------------------
    echo   run JB map
    echo     Start the waypoint mapper/recorder
    echo
    echo   SYSTEM:
    echo   -------
    echo   run JB init
    echo     Initialize JB system (first-time setup)
    echo
    echo   run JB test
    echo     Test all JB systems and dependencies
    echo
    echo   run JB status
    echo     Show system status and configuration
    echo
    echo   run JB version
    echo     Show version information
    echo
    echo   run JB help
    echo     Show this help
    echo
    echo ================================================
    echo Quick Start Examples:
    echo ================================================
    echo
    echo 1. Record waypoints for a path:
    echo    run JB map
    echo
    echo 2. Run a heroic instance:
    echo    run JB run "Kralet Penumbra Epic"
    echo
    echo 3. Run all daily writs:
    echo    run JB queue "Daily Writs"
    echo
    echo ================================================
    echo File Locations:
    echo ================================================
    echo Instances: ${JB_BaseDir}instances/
    echo Tasks: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/
    echo Queues: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/
    echo Waypoints: ${JB_BaseDir}waypoints/
    echo ================================================
}

function ShowVersion()
{
    echo ================================================
    echo JB System Information
    echo ================================================
    echo Version: ${JB_Version}
    echo Release Date: ${JB_ReleaseDate}
    echo Base Directory: ${JB_BaseDir}
    echo
    echo Components:
    echo - JInstanceRunner: Instance automation
    echo - JQuestBot: Task/quest automation
    echo - JMapper: Waypoint recorder
    echo - JNavigation: Path navigation
    echo - JCommandExecutor: Command processor
    echo - JCommon: Shared utilities
    echo ================================================
}

function ShowStatus()
{
    echo ================================================
    echo JB System Status
    echo ================================================
    
    ; Check directories
    echo Checking directories...
    call CheckDirectory "${JB_BaseDir}"
    call CheckDirectory "${JB_BaseDir}instances/"
    call CheckDirectory "${JB_BaseDir}waypoints/"
    call CheckDirectory "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/"
    call CheckDirectory "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/"
    
    echo
    echo Checking core files...
    call CheckFile "${JB_BaseDir}JInstanceRunner.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/JQuestBot.iss"
    call CheckFile "${JB_BaseDir}JMapper.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JNavigation.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JCommandExecutor.iss"
    
    echo
    echo Checking OgreBot...
    if ${OgreBotAPI.IsReady}
    {
        echo OgreBot: Ready
    }
    else
    {
        echo OgreBot: Not ready or not running
    }
    
    echo ================================================
}

function CheckDirectory(string path)
{
    if ${System.FileExists["${path}"]}
    {
        echo ${path}
    }
    else
    {
        echo ${path} (MISSING)
    }
}

function CheckFile(string path)
{
    if ${System.FileExists["${path}"]}
    {
        echo ${path}
    }
    else
    {
        echo ${path} (MISSING)
    }
}

function RunInstance(string instanceName)
{
    if !${instanceName.Length}
    {
        echo ERROR: No instance name specified
        echo Usage: run JB run "Instance Name"
        echo
        call ListInstances
        return
    }
    
    variable string instancePath = "${JB_BaseDir}instances/${instanceName}.json"
    
    if !${System.FileExists["${instancePath}"]}
    {
        echo ERROR: Instance not found: ${instanceName}
        echo
        echo Looking for: ${instancePath}
        echo
        call ListInstances
        return
    }
    
    echo ================================================
    echo Launching Instance: ${instanceName}
    echo ================================================
    echo
    
    ; Launch JInstanceRunner
    runscript "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JInstanceRunner.iss" "${instanceName}"
}

function ListInstances()
{
    variable string searchPath = "${JB_BaseDir}instances/"
    variable string searchPattern = "*.json"
    variable filelist instanceFiles
    variable iterator fileIter
    variable int counter = 0
    
    echo ================================================
    echo Available Instances
    echo ================================================

    instanceFiles:GetFiles["${searchPath}${searchPattern}"]
    instanceFiles:GetIterator[fileIter]
    
    if ${fileIter:First(exists)}
    {
        do
        {
            counter:Inc
            variable string fileName = "${fileIter.Value.Filename}"
            fileName:Set["${fileName.Left[${Math.Calc[${fileName.Length}-5]}]}"]
            
            ; Try to read metadata
            variable jsonvalue metadata
            variable string fullPath = "${JB_BaseDir}instances/${fileIter.Value.Filename}"
            variable jsonvalue instanceData
            instanceData:SetValue["${File.Read["${fullPath}"]}"]
            
            if ${instanceData.Has[metadata]}
            {
                echo ${counter}. ${fileName}
                if ${instanceData.Get[metadata].Has[zone]}
                    echo    Zone: ${instanceData.Get[metadata].Get[zone]}
                if ${instanceData.Get[metadata].Has[difficulty]}
                    echo    Difficulty: ${instanceData.Get[metadata].Get[difficulty]}
            }
            else
            {
                echo ${counter}. ${fileName}
            }
            echo
        }
        while ${fileIter:Next(exists)}
    }
    else
    {
        echo (No instances found)
        echo
        echo Create instance files in:
        echo ${JB_BaseDir}instances/
        echo
        echo Use: run JB init
        echo To create example files
    }
    
    echo ================================================
}

function RunTask(string taskName)
{
    if !${taskName.Length}
    {
        echo ERROR: No task name specified
        echo Usage: run JB task "Task Name"
        echo
        call ListTasks
        return
    }
    
    variable string taskPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/${taskName}.json"
    
    if !${System.FileExists["${taskPath}"]}
    {
        echo ERROR: Task not found: ${taskName}
        echo
        call ListTasks
        return
    }
    
    echo ================================================
    echo Launching Task: ${taskName}
    echo ================================================
    echo
    
    ; Launch JQuestBot
    runscript "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/JQuestBot.iss" "${taskName}"
}

function RunQueue(string queueName)
{
    if !${queueName.Length}
    {
        echo ERROR: No queue name specified
        echo Usage: run JB queue "Queue Name"
        echo
        call ListQueues
        return
    }
    
    variable string queuePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/${queueName}.json"
    
    if !${System.FileExists["${queuePath}"]}
    {
        echo ERROR: Queue not found: ${queueName}
        echo
        call ListQueues
        return
    }
    
    echo ================================================
    echo Launching Queue: ${queueName}
    echo ================================================
    echo
    
    ; Launch JQuestBot with queue
    runscript "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/JQuestBot.iss" "" "${queueName}"
}

function ListTasks()
{
    variable string searchPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/"
    variable string searchPattern = "*.json"
    variable filelist taskFiles
    variable iterator fileIter
    variable int counter = 0
    
    echo ================================================
    echo Available Tasks
    echo ================================================

    taskFiles:GetFiles["${searchPath}${searchPattern}"]
    taskFiles:GetIterator[fileIter]
    
    if ${fileIter:First(exists)}
    {
        do
        {
            counter:Inc
            variable string fileName = "${fileIter.Value.Filename}"
            fileName:Set["${fileName.Left[${Math.Calc[${fileName.Length}-5]}]}"]
            echo ${counter}. ${fileName}
        }
        while ${fileIter:Next(exists)}
    }
    else
    {
        echo (No tasks found)
        echo
        echo Create task files in:
        echo ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/
    }
    
    echo ================================================
}

function ListQueues()
{
    variable string searchPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/"
    variable string searchPattern = "*.json"
    variable filelist queueFiles
    variable iterator fileIter
    variable int counter = 0
    
    echo ================================================
    echo Available Task Queues
    echo ================================================

    queueFiles:GetFiles["${searchPath}${searchPattern}"]
    queueFiles:GetIterator[fileIter]
    
    if ${fileIter:First(exists)}
    {
        do
        {
            counter:Inc
            variable string fileName = "${fileIter.Value.Filename}"
            fileName:Set["${fileName.Left[${Math.Calc[${fileName.Length}-5]}]}"]
            echo ${counter}. ${fileName}
        }
        while ${fileIter:Next(exists)}
    }
    else
    {
        echo (No queues found)
        echo
        echo Create queue files in:
        echo ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/
    }
    
    echo ================================================
}

function ListItems(string itemType)
{
    switch ${itemType.Lower}
    {
        case tasks
        case task
            call ListTasks
            break
            
        case queues
        case queue
            call ListQueues
            break
            
        case instances
        case instance
        case ""
            call ListInstances
            break
            
        default
            echo Unknown list type: ${itemType}
            echo Valid options: instances, tasks, queues
            break
    }
}

function StartMapper()
{
    echo ================================================
    echo Launching Waypoint Mapper
    echo ================================================
    echo
    echo Controls:
    echo   F2  - Start/Stop Recording
    echo   F3  - Manually add waypoint
    echo   F5  - Change record distance
    echo   F11 - Change path name
    echo   F12 - Save and exit
    echo
    echo Waypoints save to:
    echo ${JB_BaseDir}waypoints/
    echo ================================================
    echo
    
    wait 20
    
    runscript "${JB_BaseDir}JMapper.iss"
}

function Initialize()
{
    echo ================================================
    echo JB System Initialization
    echo ================================================
    echo
    echo This will create the directory structure and
    echo example files for the JB system.
    echo
    echo Creating directories...
    
    ; Create main directories
    if !${System.FileExists["${JB_BaseDir}"]}
    {
        System:CreateDirectory["${JB_BaseDir}"]
        echo Created: ${JB_BaseDir}
    }
    else
    {
        echo Exists: ${JB_BaseDir}
    }
    
    if !${System.FileExists["${JB_BaseDir}instances/"]}
    {
        System:CreateDirectory["${JB_BaseDir}instances/"]
        echo Created: ${JB_BaseDir}instances/
    }
    else
    {
        echo Exists: ${JB_BaseDir}instances/
    }
    
    if !${System.FileExists["${JB_BaseDir}waypoints/"]}
    {
        System:CreateDirectory["${JB_BaseDir}waypoints/"]
        echo Created: ${JB_BaseDir}waypoints/
    }
    else
    {
        echo Exists: ${JB_BaseDir}waypoints/
    }
    
    ; Create JQuestBot directories
    variable string qbBase = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/"
    
    if !${System.FileExists["${qbBase}"]}
    {
        System:CreateDirectory["${qbBase}"]
        echo Created: ${qbBase}
    }
    
    if !${System.FileExists["${qbBase}tasks/"]}
    {
        System:CreateDirectory["${qbBase}tasks/"]
        echo Created: ${qbBase}tasks/
    }
    
    if !${System.FileExists["${qbBase}queues/"]}
    {
        System:CreateDirectory["${qbBase}queues/"]
        echo Created: ${qbBase}queues/
    }
    
    if !${System.FileExists["${qbBase}config/"]}
    {
        System:CreateDirectory["${qbBase}config/"]
        echo Created: ${qbBase}config/
    }
    
    echo
    echo Creating example files...
    
    call CreateExampleInstance
    call CreateExampleTask
    call CreateExampleQueue
    
    echo
    echo ================================================
    echo Initialization Complete!
    echo ================================================
    echo
    echo Next steps:
    echo 1. Review example files in instances/ and tasks/
    echo 2. Run: run JB test
    echo 3. Try: run JB run "Example Instance"
    echo ================================================
}

function CreateExampleInstance()
{
    variable filepath examplePath = "${JB_BaseDir}instances/example_instance.json"
    
    if ${System.FileExists["${examplePath}"]}
    {
        echo Example instance already exists, skipping
        return
    }
    
    variable jsonvalue example
    example:SetValue["$$>
{
  \"metadata\": {
    \"name\": \"Example Instance\",
    \"zone\": \"Example Zone [Heroic]\",
    \"author\": \"JB System\",
    \"version\": \"1.0.0\",
    \"difficulty\": \"heroic\",
    \"estimated_time\": \"15 minutes\"
  },
  \"steps\": [
    {
      \"step\": 1,
      \"command\": \"QuestBot: Confirm_ZoneName\",
      \"parameters\": [\"all\", \"Example Zone\"],
      \"description\": \"Verify we're in the correct zone\",
      \"enabled\": true
    },
    {
      \"step\": 2,
      \"command\": \"QuestBot: Checkpoint\",
      \"parameters\": [\"Starting Example Instance\"],
      \"description\": \"Checkpoint marker\",
      \"enabled\": true
    },
    {
      \"step\": 3,
      \"command\": \"QuestBot: Author_Message\",
      \"parameters\": [\"This is an example instance. Edit this file to customize!\"],
      \"description\": \"Display message to user\",
      \"enabled\": true
    },
    {
      \"step\": 4,
      \"command\": \"OgreBot: CampSpot\",
      \"parameters\": [\"all\", \"2\", \"300\"],
      \"description\": \"Set camp spot for all characters\",
      \"enabled\": true
    },
    {
      \"step\": 5,
      \"command\": \"QuestBot: Wait\",
      \"parameters\": [\"5\"],
      \"description\": \"Wait 5 seconds\",
      \"enabled\": true
    }
  ],
  \"navigationPaths\": {
    \"example_path\": [
      {\"x\": 100.0, \"y\": 50.0, \"z\": -200.0},
      {\"x\": 120.0, \"y\": 50.0, \"z\": -180.0}
    ]
  }
}
    <$$"]
    
    examplePath:WriteFile["${example}",multiline]
    echo Created: example_instance.json
}

function CreateExampleTask()
{
    variable filepath examplePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/example_task.json"
    
    if ${System.FileExists["${examplePath}"]}
    {
        echo Example task already exists, skipping
        return
    }
    
    variable jsonvalue example
    example:SetValue["$$>
{
  \"task_name\": \"Example Task\",
  \"description\": \"Example task file showing JSON format\",
  \"author\": \"JB System\",
  \"version\": \"1.0.0\",
  \"steps\": [
    {
      \"step\": 1,
      \"command\": \"QuestBot: Author_Message\",
      \"parameters\": [\"Welcome to JB Quest Bot!\"],
      \"description\": \"Welcome message\",
      \"enabled\": true
    },
    {
      \"step\": 2,
      \"command\": \"QuestBot: Wait\",
      \"parameters\": [\"3\"],
      \"description\": \"Wait 3 seconds\",
      \"enabled\": true
    },
    {
      \"step\": 3,
      \"command\": \"QuestBot: Author_Message\",
      \"parameters\": [\"Edit this file to create your own tasks!\"],
      \"description\": \"Info message\",
      \"enabled\": true
    }
  ]
}
    <$$"]
    
    examplePath:WriteFile["${example}",multiline]
    echo Created: example_task.json
}

function CreateExampleQueue()
{
    variable filepath examplePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/example_queue.json"
    
    if ${System.FileExists["${examplePath}"]}
    {
        echo Example queue already exists, skipping
        return
    }
    
    variable jsonvalue example
    example:SetValue["$$>
{
  \"queue_name\": \"Example Queue\",
  \"description\": \"Example task queue\",
  \"tasks\": [
    \"example_task\"
  ]
}
    <$$"]
    
    examplePath:WriteFile["${example}",multiline]
    echo Created: example_queue.json
}

function TestSystems()
{
    echo ================================================
    echo JB System Tests
    echo ================================================
    echo
    
    echo Testing directory structure...
    call TestDirectories
    
    echo
    echo Testing core files...
    call TestCoreFiles
    
    echo
    echo Testing dependencies...
    call TestDependencies
    
    echo
    echo Testing example files...
    call TestExamples
    
    echo
    echo ================================================
    echo Test Complete
    echo ================================================
}

function TestDirectories()
{
    call CheckDirectory "${JB_BaseDir}"
    call CheckDirectory "${JB_BaseDir}instances/"
    call CheckDirectory "${JB_BaseDir}waypoints/"
    call CheckDirectory "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/"
    call CheckDirectory "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/"
}

function TestCoreFiles()
{
    call CheckFile "${JB_BaseDir}JInstanceRunner.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/JQuestBot.iss"
    call CheckFile "${JB_BaseDir}JMapper.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JNavigation.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JCommandExecutor.iss"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JCommon.iss"
}

function TestDependencies()
{
    ; Test OgreBot
    if ${OgreBotAPI.IsReady}
    {
        echo OgreBot API: Ready
    }
    else
    {
        echo OgreBot API: Not ready (may not be running)
    }
    
    ; Test EQ2
    if ${EQ2(exists)}
    {
        echo EQ2: Available
    }
    else
    {
        echo EQ2: Not available
    }
}

function TestExamples()
{
    call CheckFile "${JB_BaseDir}instances/example_instance.json"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/example_task.json"
    call CheckFile "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/example_queue.json"
}

function atexit()
{
    ; Cleanup if needed
}
