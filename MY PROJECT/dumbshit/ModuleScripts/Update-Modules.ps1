<#
.SYNOPSIS
Processes a specified module directory and outputs its structure and contents in JSON format.

.DESCRIPTION
This script sets the base directory for module processing and an optional module name. 
It then processes the directory using the ProcessModuleDirectory function, 
which should be defined in the "Process-Module-Directory" script, 
and outputs the structured information about the directory in JSON format.

.PARAMETER baseModuleDirectory
The base directory from which the module processing starts. 
Defaults to the "include" directory relative to the script's location.

.PARAMETER moduleName
An optional parameter specifying the name of the module to process. 
If not provided, all modules within the base directory are processed.

.EXAMPLE
.\Update-Modules.ps1
# Processes the default module directory and outputs information in JSON format.

.EXAMPLE
.\Update-Modules.ps1 -baseModuleDirectory "C:\Modules" -moduleName "MyModule"
# Processes the "MyModule" within "C:\Modules" and outputs information in JSON format.

.OUTPUTS
JSON
Outputs a JSON representation of the processed module directory.

.NOTES
This script requires the "Process-Module-Directory" script to be present in the same directory.
This dependent script defines the ProcessModuleDirectory function used for processing.
#>

param (
    [string]$baseModuleDirectory = "$PSScriptRoot\..\include",
    [string]$moduleName = $null
)

. "$PSScriptRoot/Process-Module-Directory"
. "$PSScriptRoot/Write-Module-Header"
. "$PSScriptRoot/Update-Include-Paths"
. "$PSScriptRoot/Update-Module-Includes"
. "$PSScriptRoot/Update-Project-Includes"
. "$PSScriptRoot/Update-RI-Header-File"


$moduleDirectoryName = $baseModuleDirectory
if ($moduleName -ne $null) {
    $moduleDirectoryName = "$baseModuleDirectory\$moduleName"
}

$moduleList = ProcessModuleDirectory -path $moduleDirectoryName

$moduleList | ForEach-Object {
    Write-Module-Header -modulePath $moduleDirectoryName -moduleData $_
    Update-Project-Includes -moduleData $_ $_.IncludeFiles -projectFilePath "$PSScriptRoot\..\ISXRI.vcxproj"
    Update-RI-Header-File -moduleData $_ -headerFilePath "$PSScriptRoot\..\include\RI.iss" -fileKey "3rtZdjv7"
    Update-Module-Includes -moduleData $_
}

Update-Include-Paths
