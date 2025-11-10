; JB - Main Launcher
; Path: ${LavishScript.HomeDirectory}\Scripts\JB\JB.iss

function main(string command, string parameter)
{
    echo ===================================
    echo JB - JSON-Based Bot System
    echo ===================================
    echo.
    
    if !${command.Length}
    {
        call ShowHelp
        return
    }
    
    switch ${command}
    {
        case run
        case instance
            if !${parameter.Length}
            {
                echo ERROR: No instance file specified
                echo Usage: run JB run "Instance Name"
                return
            }
            echo Starting instance: ${parameter}
            runscript "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JInstanceRunner.iss" "${parameter}"
            break
            
        case map
        case mapper
        case record
            echo Starting waypoint mapper...
            runscript "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMapper.iss"
            break
            
        case list
            call ListInstances
            break
            
        case help
            call ShowHelp
            break
            
        default
            echo Unknown command: ${command}
            call ShowHelp
            break
    }
}

function ShowHelp()
{
    echo Commands:

    echo   run JB run "Instance Name"
    echo     - Run an instance file

    echo   run JB map
    echo     - Start waypoint mapper (record paths)

    echo   run JB list
    echo     - List available instances

    echo   run JB help
    echo     - Show this help

    echo ===================================
    echo Quick Examples:

    echo   Record waypoints:
    echo     run JB map

    echo   Run an instance:
    echo     run JB run "Kralet Penumbra"

    echo ===================================
}

function ListInstances()
{
    variable string searchPath
    variable filelist instanceFiles
    variable int i = 1
    
    searchPath:Set["${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/Instances/*.json"]
    
    echo Available instances:
    echo.
    
    instanceFiles:GetFiles["${searchPath}"]
    
    if ${instanceFiles.Files}
    {
        while ${i} <= ${instanceFiles.Files}
        {
            variable string fileName
            fileName:Set["${instanceFiles.File[${i}]}"]
            ; Remove .json extension
            fileName:Set["${fileName.Left[${Math.Calc[${fileName.Length}-5]}]}"]
            echo   ${i}. ${fileName}
            i:Inc
        }
    }
    else
    {
        echo   (No instances found)
   
        echo   Create instances in:
        echo   ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/Instances/
    }
    

    echo To run an instance:
    echo   run JB run "Instance Name"
}