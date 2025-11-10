<#
.SYNOPSIS
Generate new encryption key components for ISXJQB

.DESCRIPTION
Generates randomized key components for the derivative key system.
This creates KEY_PART1, KEY_PART2, and XOR_SALT that should be
copied into KeyDerivation.h before compiling.

.PARAMETER KeyLength
Length of the encryption key (default: 16 bytes)

.EXAMPLE
.\Generate-New-Key.ps1
# Generates new 16-byte key components
#>

param(
    [int]$KeyLength = 16
)

function Generate-RandomBytes {
    param([int]$count)

    $bytes = New-Object byte[] $count
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $rng.Dispose()

    return $bytes
}

function Format-ByteArray {
    param([byte[]]$bytes, [string]$name)

    $output = "const unsigned char KeyDerivation::${name}[] = {`n    "

    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $output += "0x{0:X2}" -f $bytes[$i]

        if ($i -lt $bytes.Length - 1) {
            $output += ", "
        }

        # Line break every 8 bytes
        if (($i + 1) % 8 -eq 0 -and $i -lt $bytes.Length - 1) {
            $output += "`n    "
        }
    }

    $output += "`n};"
    return $output
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ISXJQB Key Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Generating $KeyLength-byte encryption key components..." -ForegroundColor Yellow
Write-Host ""

# Generate key components
$keyPart1 = Generate-RandomBytes -count $KeyLength
$keyPart2 = Generate-RandomBytes -count $KeyLength
$xorSalt = Generate-RandomBytes -count $KeyLength

# Format output
$output = @"
// ========================================
// Generated Encryption Key Components
// Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// ========================================
// IMPORTANT: Copy these into KeyDerivation.h BEFORE compiling!
// Replace the existing KEY_PART1, KEY_PART2, and XOR_SALT definitions.

$(Format-ByteArray -bytes $keyPart1 -name "KEY_PART1")

$(Format-ByteArray -bytes $keyPart2 -name "KEY_PART2")

$(Format-ByteArray -bytes $xorSalt -name "XOR_SALT")

// ========================================
// How the key derivation works:
// 1. KEY_PART1, KEY_PART2, and XOR_SALT are stored in the binary
// 2. At runtime, a random SessionSalt is generated
// 3. The actual key is: KEY_PART1 XOR KEY_PART2 XOR XOR_SALT XOR SessionSalt
// 4. This avoids storing the plaintext key in memory
// ========================================
"@

# Display output
Write-Host $output -ForegroundColor Green
Write-Host ""

# Save to file
$outputFile = "$PSScriptRoot\NewKeyComponents.txt"
$output | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Key components saved to: $outputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open KeyDerivation.h" -ForegroundColor White
Write-Host "  2. Replace KEY_PART1, KEY_PART2, and XOR_SALT with the generated values" -ForegroundColor White
Write-Host "  3. Delete or secure NewKeyComponents.txt (don't commit it!)" -ForegroundColor White
Write-Host "  4. Rebuild the project" -ForegroundColor White
Write-Host ""
Write-Host "WARNING: Keep these key components SECRET!" -ForegroundColor Red
Write-Host "Anyone with access to these can decrypt your compiled extension." -ForegroundColor Red
Write-Host ""
