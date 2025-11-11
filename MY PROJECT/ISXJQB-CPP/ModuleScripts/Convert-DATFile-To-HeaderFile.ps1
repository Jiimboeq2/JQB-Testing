<#
.SYNOPSIS
Converts a .dat file to a C++ header file with a string array.

.DESCRIPTION
The Convert-DATFile-ToHeaderFile function reads the contents of a specified .dat file and converts it into a C++ header file. Each line in the .dat file is transformed into an element of a string array in C++ format. The generated C++ header file contains an array declaration with the contents of the .dat file.

.PARAMETER filePath
The path to the .dat file that needs to be converted.

.PARAMETER modulePath
The path to the directory where the resulting C++ header file will be saved.

.EXAMPLE
Convert-DATFile-ToHeaderFile -filePath "path\to\file.dat" -modulePath "path\to\module"

This command converts 'file.dat' into a C++ header file and saves it in the specified module path.

.OUTPUTS
None. This function does not return any output, but it generates a new C++ header file at the specified location.

.NOTES
This function assumes that the content of the .dat file is suitable for direct inclusion in a C++ string array and does not perform complex parsing or validation of the file content.
#>
function Convert-DATFile-ToHeaderFile {

    param ($filePath, $modulePath)

    # Handle both FileInfo objects and string paths
    $filePathString = if ($filePath -is [System.IO.FileInfo]) { $filePath.FullName } else { $filePath }

    if (-not (Test-Path $filePathString)) {
        Write-Warning "File not found: $filePathString"
        return
    }

    $content = Get-Content $filePathString
    if ($content.Trim().Length -gt 0) {
        $arrayName = [System.IO.Path]::GetFileNameWithoutExtension($filePathString).Replace(" ", "")
        $arrayData = "string ${arrayName}[] = {`r`n"

        foreach ($line in $content) {
            $cppLine = $line -replace '"', '\"'
            $arrayData += "`t`"$cppLine`",`r`n"
        }

        Write-Host "Converting DAT file $arrayName.dat to header file" -ForegroundColor Green
        $arrayData.TrimEnd(",`r`n") + "`r`n};" | Out-File -FilePath "$modulePath/$arrayName.h" -Encoding UTF8
    }
}