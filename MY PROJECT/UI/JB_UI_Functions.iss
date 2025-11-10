; =====================================================
; JB UI Helper Functions
; Path: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JB_UI_Functions.iss
; =====================================================

; ================================================================================
; MODE SWITCHING
; ================================================================================

function JB_UI_SwitchMode(string mode)
{
    ; Hide all frames
    UIElement[${JBUI_Instances_Frame}]:Hide
    UIElement[${JBUI_Tasks_Frame}]:Hide
    UIElement[${JBUI_Queues_Frame}]:Hide
    UIElement[${JBUI_Progress_Frame}]:Hide
    UIElement[${JBUI_Settings_Frame}]:Hide

    ; Reset all button colors
    UIElement[${JBUI_Mode_Instances_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Tasks_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Queues_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Progress_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Mode_Settings_Button}].Font:SetColor[FFFFFFFF]

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
    }

    _sJB_CurrentMode:Set["${mode}"]
}

; ================================================================================
; FILE REFRESHING
; ================================================================================
; NOTE: Refresh functions using filelist/iterator removed due to LavishScript
; parse errors. Users must manually enter instance/task/queue names.
; Future: Implement alternative file listing method if LavishScript supports it.

function JB_UI_RefreshInstances()
{
    ; Placeholder - filelist/iterator pattern causes parse errors
    echo ${Time}: Manual entry required - check ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/instances/
}

function JB_UI_RefreshTasks()
{
    ; Placeholder - filelist/iterator pattern causes parse errors
    echo ${Time}: Manual entry required - check ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/
}

function JB_UI_RefreshQueues()
{
    ; Placeholder - filelist/iterator pattern causes parse errors
    echo ${Time}: Manual entry required - check ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/
}

; ================================================================================
; PREVIEW LOADING
; ================================================================================

function JB_UI_LoadInstancePreview()
{
    variable string filePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/instances/${_sJB_SelectedInstance}.json"
    variable jsonvalue instanceData

    UIElement[${JBUI_InstancePreview_Console}]:Clear

    if !${System.FileExists["${filePath}"]}
    {
        UIElement[${JBUI_InstancePreview_Console}]:Echo["File not found"]
        return
    }

    instanceData:SetValue["${File.Read["${filePath}"]}"]

    if ${instanceData.Has[metadata]}
    {
        UIElement[${JBUI_InstancePreview_Console}]:Echo["================================================"]
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Instance Information"]
        UIElement[${JBUI_InstancePreview_Console}]:Echo["================================================"]

        if ${instanceData.Get[metadata].Has[name]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Name: ${instanceData.Get[metadata].Get[name]}"]

        if ${instanceData.Get[metadata].Has[zone]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Zone: ${instanceData.Get[metadata].Get[zone]}"]

        if ${instanceData.Get[metadata].Has[difficulty]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Difficulty: ${instanceData.Get[metadata].Get[difficulty]}"]

        if ${instanceData.Get[metadata].Has[author]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Author: ${instanceData.Get[metadata].Get[author]}"]

        if ${instanceData.Get[metadata].Has[version]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Version: ${instanceData.Get[metadata].Get[version]}"]

        if ${instanceData.Has[steps]}
        UIElement[${JBUI_InstancePreview_Console}]:Echo["Total Steps: ${instanceData.Get[steps].Size}"]

        UIElement[${JBUI_InstancePreview_Console}]:Echo[""]
        UIElement[${JBUI_InstancePreview_Console}]:Echo["First 10 Steps:"]
        UIElement[${JBUI_InstancePreview_Console}]:Echo["================================================"]

        variable int i = 0
        while ${i} < ${instanceData.Get[steps].Size} && ${i} < 10
        {
            variable jsonvalue step
            step:SetReference["instanceData.Get[steps].Get[${i}]"]

            variable string stepLine
            stepLine:Set["${Math.Calc[${i}+1]}. ${step.Get[command]}"]

            if ${step.Has[description]}
            stepLine:Concat[" - ${step.Get[description]}"]

            UIElement[${JBUI_InstancePreview_Console}]:Echo["${stepLine}"]
            i:Inc
        }

        if ${instanceData.Get[steps].Size} > 10
        {
            UIElement[${JBUI_InstancePreview_Console}]:Echo["... (${Math.Calc[${instanceData.Get[steps].Size}-10]} more steps)"]
        }
    }
}

function JB_UI_LoadTaskPreview()
{
    variable string filePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/tasks/${_sJB_SelectedTask}.json"
    variable jsonvalue taskData

    UIElement[${JBUI_TaskPreview_Console}]:Clear

    if !${System.FileExists["${filePath}"]}
    {
        UIElement[${JBUI_TaskPreview_Console}]:Echo["File not found"]
        return
    }

    taskData:SetValue["${File.Read["${filePath}"]}"]

    UIElement[${JBUI_TaskPreview_Console}]:Echo["================================================"]
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Task Information"]
    UIElement[${JBUI_TaskPreview_Console}]:Echo["================================================"]

    if ${taskData.Has[task_name]}
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Name: ${taskData.Get[task_name]}"]

    if ${taskData.Has[description]}
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Description: ${taskData.Get[description]}"]

    if ${taskData.Has[author]}
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Author: ${taskData.Get[author]}"]

    if ${taskData.Has[steps]}
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Total Steps: ${taskData.Get[steps].Size}"]

    UIElement[${JBUI_TaskPreview_Console}]:Echo[""]
    UIElement[${JBUI_TaskPreview_Console}]:Echo["Steps:"]
    UIElement[${JBUI_TaskPreview_Console}]:Echo["================================================"]

    if ${taskData.Has[steps]}
    {
        variable int i = 0
        while ${i} < ${taskData.Get[steps].Size}
        {
            variable jsonvalue step
            step:SetReference["taskData.Get[steps].Get[${i}]"]

            variable string stepLine
            stepLine:Set["${Math.Calc[${i}+1]}. ${step.Get[command]}"]

            if ${step.Has[description]}
            stepLine:Concat[" - ${step.Get[description]}"]

            UIElement[${JBUI_TaskPreview_Console}]:Echo["${stepLine}"]
            i:Inc
        }
    }
}

function JB_UI_LoadQueuePreview()
{
    variable string filePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JQuestBot/queues/${_sJB_SelectedQueue}.json"
    variable jsonvalue queueData

    UIElement[${JBUI_QueueContents_Listbox}]:ClearItems

    if !${System.FileExists["${filePath}"]}
    {
        return
    }

    queueData:SetValue["${File.Read["${filePath}"]}"]

    if ${queueData.Has[tasks]}
    {
        variable int i = 0
        while ${i} < ${queueData.Get[tasks].Size}
        {
            UIElement[${JBUI_QueueContents_Listbox}]:AddItem["${Math.Calc[${i}+1]}. ${queueData.Get[tasks].Get[${i}]}"]
            i:Inc
        }
    }
}

; ================================================================================
; SETTINGS MANAGEMENT
; ================================================================================

function JB_UI_SaveSettings()
{
    variable filepath settingsPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/config/ui_settings.xml"

    ; Save to LavishSettings
    LavishSettings[JB_UI]:Clear
    LavishSettings:AddSet[JB_UI]

    LavishSettings[JB_UI].FindSet[General]:Set[AutoLoadLastInstance,"${UIElement[${JBUI_AutoLoadLastInstance_Checkbox}].Checked}"]
    LavishSettings[JB_UI].FindSet[General]:Set[MinimizeOnStart,"${UIElement[${JBUI_MinimizeOnStart_Checkbox}].Checked}"]
    LavishSettings[JB_UI].FindSet[General]:Set[DefaultRetries,"${UIElement[${JBUI_DefaultRetries_TextEntry}].Text}"]

    LavishSettings[JB_UI]:Export["${settingsPath}"]

    echo ${Time}: UI Settings saved to: ${settingsPath}
}

function JB_UI_LoadSettings()
{
    variable filepath settingsPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/config/ui_settings.xml"

    if !${System.FileExists["${settingsPath}"]}
    {
        echo ${Time}: No saved settings found
        return
    }

    LavishSettings:Clear
    LavishSettings[JB_UI]:Import["${settingsPath}"]

    ; Load settings into UI
    if ${LavishSettings[JB_UI].FindSetting[General,AutoLoadLastInstance](exists)}
    {
        if ${LavishSettings[JB_UI].FindSetting[General,AutoLoadLastInstance]}
        UIElement[${JBUI_AutoLoadLastInstance_Checkbox}]:SetChecked
    }

    echo ${Time}: UI Settings loaded
}

; ================================================================================
; PROGRESS UPDATE (called from scripts)
; ================================================================================

atom(global) JB_UI_UpdateProgress(int currentStep, int maxSteps, string command, string description)
{
    UIElement[${JBUI_CurrentStep_Number}]:SetText["Step: ${currentStep} / ${maxSteps}"]
    UIElement[${JBUI_CurrentStep_Command}]:SetText["Command: ${command}"]
    UIElement[${JBUI_CurrentStep_Description}]:SetText["Description: ${description}"]
}

atom(global) JB_UI_UpdateStats(int completed, int failed, int duration)
{
    variable int minutes = ${Math.Calc[${duration}/60]}
    variable int seconds = ${Math.Calc[${duration}%60]}

    UIElement[${JBUI_Stats_Display}]:SetText["Completed: ${completed} | Failed: ${failed} | Duration: ${minutes}m ${seconds}s"]
}

atom(global) JB_UI_LogMessage(string message)
{
    UIElement[${JBUI_ExecutionLog_Console}]:Echo["${message}"]
}
