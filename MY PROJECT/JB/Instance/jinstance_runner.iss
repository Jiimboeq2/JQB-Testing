variable(global) string J_InstanceRunner_Version = "2.0.0"
variable(global) string J_InstanceRunner_ReleaseDate = "2025-10-19"
variable(global) string J_Instance_CurrentFile
variable(global) int J_Instance_CurrentStep = 0
variable(global) int J_Instance_MaxSteps = 0
variable(global) bool J_Instance_Running = FALSE
variable(global) bool J_Instance_Paused = FALSE
variable(global) jsonvalue J_Instance_CurrentTask
variable(global) JCommandExecutor J_CommandExecutor
variable(global) int J_Instance_StepsCompleted = 0
variable(global) int J_Instance_StepsFailed = 0
variable(global) int64 J_Instance_StartTime = 0
variable(global) int64 J_Instance_EndTime = 0
variable(global) bool J_Instance_StopOnError = FALSE
variable(global) bool J_Instance_EnableCheckpoints = TRUE
variable(global) int J_Instance_MaxRetries = 3

#include "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/jcommon_helpers.iss"
#include "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JCommandExecutor.iss"
#include "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/Include/JCommands.iss"

function main(string instanceFileName)
{
    echo ${Time}: JInstanceRunner v${J_InstanceRunner_Version}

    if !${instanceFileName.Length}
    {
        echo ${Time}: ERROR: No instance file specified
        return
    }

    J_CommandExecutor:Initialize
    call LoadInstanceFile "${instanceFileName}"

    if !${J_Instance_CurrentTask.Type.Equal[object]}
    {
        echo ${Time}: ERROR: Failed to load instance file
        return
    }

    call ShowInstanceInfo
    call ValidateInstance

    if !${Return}
    {
        echo ${Time}: ERROR: Instance validation failed
        return
    }

    J_Instance_MaxSteps:Set[${J_Instance_CurrentTask.Get[steps].Size}]
    J_Instance_Running:Set[TRUE]
    J_Instance_CurrentStep:Set[1]
    J_Instance_StepsCompleted:Set[0]
    J_Instance_StepsFailed:Set[0]
    J_Instance_StartTime:Set[${Time.Timestamp}]

    echo ${Time}: Starting execution: ${J_Instance_MaxSteps} steps

    while ${J_Instance_Running} && ${J_Instance_CurrentStep} <= ${J_Instance_MaxSteps}
    {
        if ${J_Instance_Paused}
        {
            wait 10
            continue
        }

        call ExecuteStep ${J_Instance_CurrentStep}

        if ${J_Instance_StopOnError} && ${J_CommandExecutor.CommandsFailed} > 0
        break

        J_Instance_CurrentStep:Inc
        wait 5
    }

    J_Instance_EndTime:Set[${Time.Timestamp}]
    call ShowCompletionSummary
    call Cleanup
}

function LoadInstanceFile(string fileName)
{
    variable string filePath
    variable string jsonString

    filePath:Set["${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/instances/${fileName}.json"]

    J_Instance_CurrentTask:ParseFile["${filePath}"]

    if ${J_Instance_CurrentTask.Type.Equal[null]}
    {
        echo ${Time}: ERROR: Failed to parse: ${filePath}
        return
    }

    ; Convert to string and back to fix array access bug
    jsonString:Set["${J_Instance_CurrentTask}"]
    J_Instance_CurrentTask:SetValue["${jsonString}"]

    J_Instance_CurrentFile:Set["${fileName}"]
    echo ${Time}: Loaded: ${fileName}
}

function:bool ValidateInstance()
{
    if !${J_Instance_CurrentTask.Has[metadata]}
    return FALSE

    if !${J_Instance_CurrentTask.Has[steps]}
    return FALSE

    if ${J_Instance_CurrentTask.Get[steps].Size} == 0
    return FALSE

    return TRUE
}

function ShowInstanceInfo()
{
    if ${J_Instance_CurrentTask.Get[metadata].Has[name]}
    echo ${Time}: ${J_Instance_CurrentTask.Get[metadata].Get[name]}

    if ${J_Instance_CurrentTask.Get[metadata].Has[zone]}
    echo ${Time}: ${J_Instance_CurrentTask.Get[metadata].Get[zone]}

    echo ${Time}: Steps: ${J_Instance_CurrentTask.Get[steps].Size}
}


function ExecuteStep(int stepNumber)
{
    variable string command
    variable string description
    variable int stepIndex
    variable string stepsArrayString
    variable string singleStepString
    variable jsonvalue step
    variable int startPos = 1
    variable int endPos
    variable int braceCount = 0
    variable int i
    variable int currentStepNum = 0

    stepIndex:Set[${Math.Calc[${stepNumber}-1]}]
    stepsArrayString:Set["${J_Instance_CurrentTask.Get[steps]}"]

    ; Find the correct step by iterating through the array string
    i:Set[1]
    while ${i} < ${stepsArrayString.Length} && ${currentStepNum} <= ${stepIndex}
    {
        if ${stepsArrayString.Mid[${i},1].Equal["{"]}
        {
            if ${braceCount} == 0
            {
                ; This is the start of a new object
                if ${currentStepNum} == ${stepIndex}
                {
                    startPos:Set[${i}]
                    break
                }
            }
            braceCount:Inc
        }
        elseif ${stepsArrayString.Mid[${i},1].Equal["}"]}
        {
            braceCount:Dec
            if ${braceCount} == 0
            {
                ; End of current object
                currentStepNum:Inc
            }
        }
        i:Inc
    }

    ; Now find the end of this object
    i:Set[${startPos}]
    braceCount:Set[0]

    while ${i} <= ${stepsArrayString.Length}
    {
        if ${stepsArrayString.Mid[${i},1].Equal["{"]}
        braceCount:Inc
        elseif ${stepsArrayString.Mid[${i},1].Equal["}"]}
        {
            braceCount:Dec
            if ${braceCount} == 0
            {
                endPos:Set[${i}]
                break
            }
        }
        i:Inc
    }

    singleStepString:Set["${stepsArrayString.Mid[${startPos},${Math.Calc[${endPos}-${startPos}+1]}]}"]

    echo ${Time}: DEBUG: Step string: ${singleStepString}

    step:SetValue["${singleStepString}"]

    if !${step.Type.Equal[object]}
    {
        echo ${Time}: ERROR: Invalid step ${stepNumber}
        J_Instance_StepsFailed:Inc
        return
    }

    command:Set["${step.Get[command]}"]

    if ${step.Has[description]}
    description:Set["${step.Get[description]}"]

    echo ${Time}: [${stepNumber}/${J_Instance_MaxSteps}] ${command}

    variable int preFailCount = ${J_CommandExecutor.CommandsFailed}

    J_CommandExecutor:ExecuteCommand["${singleStepString}"]

    if ${J_CommandExecutor.CommandsFailed} > ${preFailCount}
    {
        echo ${Time}: FAILED
        J_Instance_StepsFailed:Inc
    }
    else
    {
        echo ${Time}: COMPLETE
        J_Instance_StepsCompleted:Inc
    }
}



function ShowCompletionSummary()
{
    variable int duration = ${Math.Calc[${J_Instance_EndTime}-${J_Instance_StartTime}]}
    variable int minutes = ${Math.Calc[${duration}/60]}
    variable int seconds = ${Math.Calc[${duration}%60]}

    echo ${Time}: COMPLETE
    echo ${Time}: ${J_Instance_CurrentFile}
    echo ${Time}: ${J_Instance_StepsCompleted}/${J_Instance_MaxSteps} completed, ${J_Instance_StepsFailed} failed
    echo ${Time}: ${minutes}m ${seconds}s

    if ${J_Instance_StepsFailed} == 0 && ${J_CommandExecutor.CommandsFailed} == 0
    echo ${Time}: PERFECT!
}

function Cleanup()
{
    J_Instance_Running:Set[FALSE]
}

function atexit()
{
    call Cleanup
    echo ${Time}: Shutdown
    echo --
    echo -- 
    echo --
    ;echo run eq2jcommon/jb/jinstance_runner
}