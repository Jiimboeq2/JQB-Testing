<#
.SYNOPSIS
Complete ISXJQB Build - One Script Does Everything

.DESCRIPTION
This is the ONLY script you need to run.
- Generates encryption keys if needed
- Updates modules
- Builds the project
- Shows you what to do next

.PARAMETER SkipKeyGeneration
Skip encryption key generation (use existing keys)

.PARAMETER Configuration
Build configuration: Release or Debug (default: Release)

.EXAMPLE
.\BuildAll.ps1
# Does everything - generates keys, builds project

.EXAMPLE
.\BuildAll.ps1 -SkipKeyGeneration
# Builds using existing keys
#>

param(
    [switch]$SkipKeyGeneration,
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$Platform = "x64"  # Always x64

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ISXJQB Complete Build System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Check/Generate Encryption Keys
# ============================================

if (!$SkipKeyGeneration) {
    Write-Host "[1/4] Checking encryption keys..." -ForegroundColor Yellow

    $keyDerivFile = "$PSScriptRoot\KeyDerivation.h"
    $needsNewKeys = $false

    if (Test-Path $keyDerivFile) {
        # Check if keys are still default values
        $content = Get-Content $keyDerivFile -Raw
        if ($content -match "JQB-Secr" -or $content -match "XOR-Key-") {
            Write-Host "  Default keys detected - generating new keys..." -ForegroundColor Yellow
            $needsNewKeys = $true
        } else {
            Write-Host "  Custom keys already present - skipping generation" -ForegroundColor Green
        }
    } else {
        Write-Host "  KeyDerivation.h not found!" -ForegroundColor Red
        exit 1
    }

    if ($needsNewKeys) {
        Write-Host ""
        Write-Host "  Generating secure encryption keys..." -ForegroundColor Yellow

        # Generate random keys inline (no separate script needed)
        function Generate-RandomBytes {
            param([int]$count)
            $bytes = New-Object byte[] $count
            $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
            $rng.GetBytes($bytes)
            $rng.Dispose()
            return $bytes
        }

        function Format-ByteArray {
            param([byte[]]$bytes)
            $output = ""
            for ($i = 0; $i -lt $bytes.Length; $i++) {
                $output += "0x{0:X2}" -f $bytes[$i]
                if ($i -lt $bytes.Length - 1) { $output += ", " }
                if (($i + 1) % 8 -eq 0 -and $i -lt $bytes.Length - 1) { $output += "`n    " }
            }
            return $output
        }

        $keyPart1 = Generate-RandomBytes -count 16
        $keyPart2 = Generate-RandomBytes -count 16
        $xorSalt = Generate-RandomBytes -count 16

        # Read current file
        $lines = Get-Content $keyDerivFile
        $newLines = @()
        $skipUntil = $null

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Replace KEY_PART1
            if ($line -match "const unsigned char KeyDerivation::KEY_PART1") {
                $newLines += "const unsigned char KeyDerivation::KEY_PART1[] = {"
                $newLines += "    " + (Format-ByteArray -bytes $keyPart1)
                $newLines += "};"
                # Skip old definition
                while ($i -lt $lines.Count -and $lines[$i] -notmatch "^\};") { $i++ }
                continue
            }

            # Replace KEY_PART2
            if ($line -match "const unsigned char KeyDerivation::KEY_PART2") {
                $newLines += "const unsigned char KeyDerivation::KEY_PART2[] = {"
                $newLines += "    " + (Format-ByteArray -bytes $keyPart2)
                $newLines += "};"
                while ($i -lt $lines.Count -and $lines[$i] -notmatch "^\};") { $i++ }
                continue
            }

            # Replace XOR_SALT
            if ($line -match "const unsigned char KeyDerivation::XOR_SALT") {
                $newLines += "const unsigned char KeyDerivation::XOR_SALT[] = {"
                $newLines += "    " + (Format-ByteArray -bytes $xorSalt)
                $newLines += "};"
                while ($i -lt $lines.Count -and $lines[$i] -notmatch "^\};") { $i++ }
                continue
            }

            $newLines += $line
        }

        # Write updated file
        $newLines | Out-File -FilePath $keyDerivFile -Encoding UTF8

        Write-Host "  Keys generated and updated in KeyDerivation.h" -ForegroundColor Green
    }

    Write-Host ""
} else {
    Write-Host "[1/4] Skipping key generation (using existing keys)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# STEP 2: Update Modules
# ============================================

Write-Host "[2/4] Updating modules..." -ForegroundColor Yellow

$updateScript = "$PSScriptRoot\ModuleScripts\Update-Modules.ps1"
if (Test-Path $updateScript) {
    & $updateScript
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Host "  Module update failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  Update-Modules.ps1 not found - skipping" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# STEP 3: Find MSBuild
# ============================================

Write-Host "[3/4] Locating MSBuild..." -ForegroundColor Yellow

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
    # Try vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
        if ($vsPath) {
            $msbuild = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        }
    }
}

if (!$msbuild -or !(Test-Path $msbuild)) {
    Write-Host ""
    Write-Host "ERROR: MSBuild not found!" -ForegroundColor Red
    Write-Host "Install Visual Studio 2022 Community (free) from:" -ForegroundColor Red
    Write-Host "https://visualstudio.microsoft.com/downloads/" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "  Found: $msbuild" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 4: Build Project
# ============================================

Write-Host "[4/4] Building ISXJQB (x64 $Configuration)..." -ForegroundColor Yellow
Write-Host ""

$solutionFile = "$PSScriptRoot\ISXJQB.sln"

if (!(Test-Path $solutionFile)) {
    Write-Host "ERROR: ISXJQB.sln not found!" -ForegroundColor Red
    exit 1
}

$buildArgs = @(
    $solutionFile,
    "/p:Configuration=$Configuration",
    "/p:Platform=x64",
    "/m",
    "/v:minimal",
    "/nologo"
)

& $msbuild $buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "     BUILD FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the error messages above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ============================================
# SUCCESS!
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "     BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Show output info
$outputDll = "$PSScriptRoot\bin\x64\ISXJQB.dll"
if (Test-Path $outputDll) {
    $fileInfo = Get-Item $outputDll
    Write-Host "Output DLL:" -ForegroundColor Cyan
    Write-Host "  Location: $outputDll" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor White
    Write-Host "  Modified: $($fileInfo.LastWriteTime)" -ForegroundColor White
} else {
    Write-Host "WARNING: ISXJQB.dll not found at expected location" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Copy DLL to InnerSpace:" -ForegroundColor Yellow
Write-Host "   $outputDll" -ForegroundColor White
Write-Host "   TO: C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll" -ForegroundColor White
Write-Host ""
Write-Host "2. Create auth file:" -ForegroundColor Yellow
Write-Host "   C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml" -ForegroundColor White
Write-Host ""
Write-Host "3. Load in EverQuest II (via InnerSpace):" -ForegroundColor Yellow
Write-Host "   ext isxjqb" -ForegroundColor White
Write-Host ""
Write-Host "4. Test with:" -ForegroundColor Yellow
Write-Host "   jqb ?" -ForegroundColor White
Write-Host ""

exit 0
