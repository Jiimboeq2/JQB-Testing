<#
.SYNOPSIS
Updates module include files

.DESCRIPTION
Processes module data and updates include headers for module integration
#>

. "$PSScriptRoot/Get-Relative-FilePath"

function Update-Module-Includes {
    param (
        [PSCustomObject]$moduleData
    )

    if ($null -eq $moduleData) {
        return
    }

    Write-Host "Updating module includes for: $($moduleData.Name)" -ForegroundColor Cyan

    # Process subfolders recursively
    foreach ($subFolder in $moduleData.SubFolders) {
        Update-Module-Includes -moduleData $subFolder
    }
}
