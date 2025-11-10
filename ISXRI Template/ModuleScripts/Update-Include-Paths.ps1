<#
.SYNOPSIS
Calculates the relative path from one path to another.

.DESCRIPTION
Get-RelativePath takes two paths as input and computes the relative path from the first path to the second. It is useful for converting absolute paths to relative paths within a specified context.

.PARAMETER from
The base path from which to calculate the relative path.

.PARAMETER to
The target path to which the relative path is calculated.

.EXAMPLE
$relativePath = Get-RelativePath -from "C:\BaseFolder" -to "C:\BaseFolder\SubFolder\File.txt"

Returns the relative path '.\SubFolder\File.txt'.

.OUTPUTS
String
The relative path from the 'from' path to the 'to' path.

#>
function Get-RelativePath {
    param (
        [string]$from,
        [string]$to
    )
    $fromUri = New-Object System.Uri($from)
    $toUri = New-Object System.Uri($to)
    return  ".\$($fromUri.MakeRelativeUri($toUri).ToString().Replace('/', '\'))"
}

<#
.SYNOPSIS
Retrieves all subdirectories from a given path.

.DESCRIPTION
Get-Subdirectories recursively retrieves all subdirectories in the specified path. It returns the full paths of all subdirectories found.

.PARAMETER path
The path from which to retrieve subdirectories.

.EXAMPLE
$subdirectories = Get-Subdirectories -path "C:\ModuleDirectory"

Retrieves all subdirectories within 'C:\ModuleDirectory'.

.OUTPUTS
System.Array
An array of strings, each representing the full path of a subdirectory.

#>

function Get-Subdirectories {
    param ([string]$path)
    Get-ChildItem -Path $path -Directory -Recurse | ForEach-Object { $_.FullName }
}

<#
.SYNOPSIS
Updates a file with relative include paths.

.DESCRIPTION
Update-Include-Paths generates a list of relative paths for all subdirectories within a specified root path and writes this list to a specified output file in a format suitable for inclusion in project files.

.PARAMETER rootPath
The root path from which to start generating relative include paths.

.PARAMETER outputFile
The output file where the generated relative include paths will be written.

.EXAMPLE
Update-Include-Paths -rootPath "C:\ModuleDirectory" -outputFile "C:\Project\IncludePaths.props"

Writes relative include paths from 'C:\ModuleDirectory' to 'C:\Project\IncludePaths.props'.

.OUTPUTS
None. This function writes to a file and does not return any output.

.NOTES
This function is useful in build systems and environments where relative paths are required in project configuration files.

#>

function Update-Include-Paths {
    param (
        [string]$rootPath = "$PSScriptRoot\..\include",
        [string]$outputFile = "$PSScriptRoot\..\GeneratedIncludePaths.props"
    )

    Write-Host "Writing updated include paths to file $outputFile" -ForegroundColor Magenta

    $includePaths = Get-Subdirectories -path $rootPath
    $relativePaths = $includePaths | ForEach-Object { Get-RelativePath -from $rootPath -to $_ }
    $propsContent = "<Project>`n  <PropertyGroup>`n    <IncludePath>"
    $propsContent += ($relativePaths -join ';') + '</IncludePath>`n  </PropertyGroup>`n</Project>'

    $propsContent -replace '`n', "`r`n" | Out-File -FilePath $outputFile -Encoding UTF8

}