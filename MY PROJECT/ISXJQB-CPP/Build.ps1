<#
.SYNOPSIS
ISXJQB Build Script

.DESCRIPTION
Automated build script for ISXJQB extension.
Updates modules, generates include paths, and optionally builds the project.

.PARAMETER UpdateModulesOnly
Only update modules without building

.PARAMETER Configuration
Build configuration: Release or Debug (default: Release)

.PARAMETER Platform
Build platform: Win32 or x64 (default: x64)

.PARAMETER SkipModuleUpdate
Skip module update and just build

.EXAMPLE
.\Build.ps1
# Updates modules and builds x64 Release

.EXAMPLE
.\Build.ps1 -UpdateModulesOnly
# Only updates modules without building

.EXAMPLE
.\Build.ps1 -Platform Win32
# Builds Win32 Release version
#>

param(
    [switch]$UpdateModulesOnly,
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [ValidateSet("Win32", "x64")]
    [string]$Platform = "x64",
    [switch]$SkipModuleUpdate
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     ISXJQB Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Update modules
if (!$SkipModuleUpdate) {
    Write-Host "[1/3] Updating modules..." -ForegroundColor Yellow
    & "$PSScriptRoot\ModuleScripts\Update-Modules.ps1"

    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Host "Module update failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

if ($UpdateModulesOnly) {
    Write-Host "Module update complete. Skipping build." -ForegroundColor Green
    exit 0
}

# Check for Visual Studio
Write-Host "[2/3] Checking for MSBuild..." -ForegroundColor Yellow

$msbuildPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
)

$msbuild = $null
foreach ($path in $msbuildPaths) {
    if (Test-Path $path) {
        $msbuild = $path
        break
    }
}

if (!$msbuild) {
    # Try to find via vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
        if ($vsPath) {
            $msbuild = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        }
    }
}

if (!$msbuild -or !(Test-Path $msbuild)) {
    Write-Host "ERROR: MSBuild not found!" -ForegroundColor Red
    Write-Host "Please install Visual Studio 2022 or Build Tools for Visual Studio 2022" -ForegroundColor Red
    exit 1
}

Write-Host "Found MSBuild: $msbuild" -ForegroundColor Green
Write-Host ""

# Build project
Write-Host "[3/3] Building ISXJQB ($Platform $Configuration)..." -ForegroundColor Yellow

$solutionFile = "$PSScriptRoot\ISXJQB.sln"
$buildArgs = @(
    $solutionFile,
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform",
    "/m",
    "/v:minimal",
    "/nologo"
)

Write-Host "Running: MSBuild $buildArgs" -ForegroundColor DarkGray
& $msbuild $buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build FAILED!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "     Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$outputDll = "$PSScriptRoot\bin\$Platform\ISXJQB.dll"
if (Test-Path $outputDll) {
    $fileInfo = Get-Item $outputDll
    Write-Host "Output DLL: $outputDll" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host "Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Cyan
} else {
    Write-Host "WARNING: Output DLL not found at expected location" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Copy ISXJQB.dll to your InnerSpace Extensions folder" -ForegroundColor White
Write-Host "  2. Start InnerSpace and load the extension" -ForegroundColor White
Write-Host ""
