<#
.SYNOPSIS
Updates a module include file with new include lines.

.DESCRIPTION
The Update-Module-Includes function updates a specific module include file by adding new include lines for each module file that is not already included. It ensures that all necessary module files are referenced in the module include file.

.PARAMETER moduleMap
A hashtable containing the module file information to be added to the include file.

.EXAMPLE
Update-Module-Includes -moduleMap $myModuleMap

Updates the module include file with new include lines based on the provided module map information.

.OUTPUTS
None. This function updates a file and does not produce a PowerShell output.

#>

function Update-Module-Includes {
    param(
        [PSCustomObject]$moduleData
    )

    $moduleIncludeFilePath = "..\include\ModuleIncludes.h"

    $fileContents = Get-Content -Path $moduleIncludeFilePath

    $includeLine = "#include ""$($moduleData.ModuleFile)"""
    if ($fileContents -notcontains $includeLine) {
        $fileContents += "$includeLine"
    }

    $fileContents -replace "`r`n", "`n" -replace "`n", "`r`n" | Set-Content -Path $moduleIncludeFilePath    
}