<#
.SYNOPSIS
Main module processing script for ISXJQB

.DESCRIPTION
Processes module directories and generates necessary headers and project files.
Adapted from ISXRI's Update-Modules.ps1 for ISXJQB.

.PARAMETER baseModuleDirectory
The base directory containing modules. Defaults to ../include

.PARAMETER moduleName
Optional specific module to process. If not specified, all modules are processed.

.EXAMPLE
.\Update-Modules.ps1
# Processes all modules in the include directory

.EXAMPLE
.\Update-Modules.ps1 -moduleName "MyModule"
# Processes only the MyModule directory
#>

param (
    [string]$baseModuleDirectory = "$PSScriptRoot\..\include",
    [string]$moduleName = $null
)

# Import helper scripts
. "$PSScriptRoot/Process-Module-Directory.ps1"
. "$PSScriptRoot/Write-Module-Header.ps1"
. "$PSScriptRoot/Update-Include-Paths.ps1"
. "$PSScriptRoot/Update-Module-Includes.ps1"
. "$PSScriptRoot/Update-Project-Includes.ps1"
. "$PSScriptRoot/Update-JQB-Header-File.ps1"

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "ISXJQB Module Update System" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

$moduleDirectoryName = $baseModuleDirectory
if ($moduleName -ne $null -and $moduleName.Trim() -ne "") {
    $moduleDirectoryName = "$baseModuleDirectory\$moduleName"
}

if (!(Test-Path $moduleDirectoryName)) {
    Write-Host "Module directory not found: $moduleDirectoryName" -ForegroundColor Yellow
    Write-Host "Creating include directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $baseModuleDirectory -Force | Out-Null

    Write-Host "No modules to process yet. Add modules with _metadata.json files." -ForegroundColor Cyan
} else {
    Write-Host "Processing modules in: $moduleDirectoryName" -ForegroundColor Cyan

    $moduleList = ProcessModuleDirectory -path $moduleDirectoryName

    if ($moduleList.Count -eq 0) {
        Write-Host "No modules found with _metadata.json files" -ForegroundColor Yellow
    } else {
        $moduleList | ForEach-Object {
            Write-Host "Processing module: $($_.Name)" -ForegroundColor Green

            Write-Module-Header -modulePath $moduleDirectoryName -moduleData $_
            Update-Project-Includes -moduleData $_ -includeFiles $_.IncludeFiles -projectFilePath "$PSScriptRoot\..\ISXJQB.vcxproj"
            Update-JQB-Header-File -moduleData $_ -headerFilePath "$PSScriptRoot\..\include\JQB.iss"
            Update-Module-Includes -moduleData $_
        }
    }
}

Write-Host "Updating include paths..." -ForegroundColor Cyan
& "$PSScriptRoot/Update-Include-Paths.ps1"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Module update complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
