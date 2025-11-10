<#
.SYNOPSIS
Retireve the lists of quests from the timelines for the specified moduleData.

.DESCRIPTION
The function Get-TimelineQuests function walks through the Timelines property of the specified moduleData object and will
recursively pull out the full list of quests. 

.PARAMETER moduleData
The module data contianing the Timeline information.

#>
function Get-TimelineQuests{
    param([PSCustomObject]$moduleData)

    $timelineQuests = @()
    foreach ($timeline in $moduleData.Timelines) {
        $timelineQuests += $timeline.Quests.Name
    }    

    if ($null -ne $moduleData.SubFolders)
    {
        foreach ($subTimeline in $moduleData.SubFolders)
        {
            $timelineQuests += Get-TimelineQuests -moduleData $subTimeline
        }
    }

    return $timelineQuests
}