<#
.SYNOPSIS
Updates include paths for the ISXJQB project

.DESCRIPTION
Generates a Visual Studio property sheet with all include directory paths
from the include folder for easy compilation.

.PARAMETER rootPath
The root path to scan for include directories. Defaults to the include folder.

.PARAMETER outputFile
The output property sheet file. Defaults to GeneratedIncludePaths.props
#>

param (
    [string]$rootPath = "$PSScriptRoot\..\include",
    [string]$outputFile = "$PSScriptRoot\..\GeneratedIncludePaths.props"
)

function Get-RelativePath {
    param (
        [string]$from,
        [string]$to
    )
    $fromUri = New-Object System.Uri($from)
    $toUri = New-Object System.Uri($to)
    return ".\$($fromUri.MakeRelativeUri($toUri).ToString().Replace('/', '\'))"
}

function Get-Subdirectories {
    param ([string]$path)

    if (!(Test-Path $path)) {
        Write-Warning "Path does not exist: $path"
        return @()
    }

    Get-ChildItem -Path $path -Directory -Recurse | ForEach-Object { $_.FullName }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$includePaths = Get-Subdirectories -path $rootPath

if ($includePaths.Count -eq 0) {
    Write-Host "No include directories found, creating minimal props file" -ForegroundColor Yellow
    $propsContent = @"
<Project>
  <PropertyGroup>
    <IncludePath>.\include</IncludePath>
  </PropertyGroup>
</Project>
"@
} else {
    $relativePaths = $includePaths | ForEach-Object { Get-RelativePath -from $projectRoot -to $_ }
    $propsContent = "<Project>`n  <PropertyGroup>`n    <IncludePath>"
    $propsContent += ($relativePaths -join ';') + '</IncludePath>`n  </PropertyGroup>`n</Project>'
}

$propsContent -replace '`n', "`r`n" | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Generated include paths at: $outputFile" -ForegroundColor Green
