<#
.SYNOPSIS
Extracts parent directory names from a file path.

.DESCRIPTION
The Get-Parent-Paths function takes a file path and extracts the directory names that are in the path after the specified 'include\' directory. This is useful for parsing structured directory paths to get a list of parent directories.

.PARAMETER filePath
The full file path from which to extract parent directories.

.EXAMPLE
$parentDirs = Get-Parent-Paths -filePath "G:\path\to\include\SubFolder\File.dat"
# This will return 'SubFolder' as part of the parent directories array.

.OUTPUTS
System.Array
An array of strings, each representing a parent directory in the path.
#>    
function Get-Parent-Paths {
    param (
        [string]$filePath
    )

    $searchPart = "include\"

    $index = $filePath.IndexOf($searchPart)

    if ($index -ne -1) {
        $subPath = $filePath.Substring($index + $searchPart.Length)
        $pathParts = $subPath -split "\\" 
        $parentDirectories = @($pathParts[0..($pathParts.Length - 2)])

        return $parentDirectories
    }
    else {
        return @()
    }
}