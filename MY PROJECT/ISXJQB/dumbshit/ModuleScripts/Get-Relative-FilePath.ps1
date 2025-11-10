<#
.SYNOPSIS
Determine the relative file path based on a given base path.

.DESCRIPTION
This function computes the relative path from a specified base path to a target file path. It normalizes both paths and then determines if the file path starts with the base path. If so, it trims the base path from the file path and returns the relative path. If the paths do not share a common base, the full file path is returned.

.PARAMETER filePath
The full path to the file for which the relative path is to be calculated.

.PARAMETER basePath
The base path from which the relative path to the file will be calculated.

.OUTPUTS
System.String
Returns a string representing the relative path from the base path to the file path. If the paths do not share a common base, returns the full file path. If the file path is the same as the base path, returns '.\' indicating the current directory.

.NOTES
Function performs a case-insensitive comparison of the paths and normalizes them by removing trailing backslashes for accurate comparison.
#>

function Get-Relative-FilePath {
    param (
        [string]$filePath,
        [string]$basePath = (Split-Path -Path $PSScriptRoot -Parent)
    )

    $normalizedFilePath = [IO.Path]::GetFullPath($filePath).TrimEnd("\")
    $normalizedBasePath = [IO.Path]::GetFullPath($basePath).TrimEnd("\")

    if ($normalizedFilePath.ToLower().StartsWith($normalizedBasePath.ToLower())) {
        $relativePath = $normalizedFilePath.Substring($normalizedBasePath.Length).TrimStart("\")
        if ($relativePath -eq "") {
            return ".\"
        }
        else {
            return $relativePath
        }
    }
    else {
        return $normalizedFilePath
    }
}