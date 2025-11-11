. "$PSScriptRoot/Get-Parent-Paths.ps1"
. "$PSScriptRoot/Convert-DATFile-To-HeaderFile.ps1"
. "$PSScriptRoot/Get-Relative-FilePath.ps1"
. "$PSScriptRoot/Get-TimelineQuests.ps1"

<#
.SYNOPSIS
Processes a directory to gather module information.

.DESCRIPTION
The ProcessModuleDirectory function recursively processes a directory, looking for .dat files and metadata, and gathers information about these files and subdirectories. The function is designed to process directories that follow a specific structure with _metadata.json files.

.PARAMETER path
The path of the directory to process.

.PARAMETER parentDirName
The name of the parent directory. This parameter is used when processing subdirectories.

.EXAMPLE
$moduleList = ProcessModuleDirectory -path "C:\ModuleDirectory"

Processes the specified directory and returns information about the .dat files and subdirectories.

.OUTPUTS
System.Array
An array of custom objects, each representing a directory with its metadata and file information.

#>
function ProcessModuleDirectory {
    param(
        [string]$path,
        [string]$parentDirName = ""
    )

    Write-Host "Processing Directory $path" -ForegroundColor Magenta
    # Check for _metadata.json in the current directory
    $metadataFileName = "$path\_metadata.json"
    if (Test-Path -Path $metadataFileName -PathType Leaf) {
        # Process this directory if _metadata.json exists and return as an array
        return @(ProcessCurrentDirectory -path $path -parentDirName $parentDirName -metadataFileName $metadataFileName)
    }
    
    # If no _metadata.json, process subdirectories
    $results = @()
    foreach ($dir in Get-ChildItem -Path $path -Directory) {
        $subResults = ProcessModuleDirectory -path $dir.FullName -parentDirName $dir.Name
        $results += $subResults
    }

    return $results
}

<#
.SYNOPSIS
Processes the current directory to extract module information.

.DESCRIPTION
ProcessCurrentDirectory processes a specific directory, extracting information from _metadata.json, if present, and details about .dat files within the directory. It also processes subdirectories recursively.

.PARAMETER path
The path of the current directory to process.

.PARAMETER parentDirName
The name of the parent directory of the current directory.

.PARAMETER metadataFileName
The file name of the metadata file, typically _metadata.json.

.EXAMPLE
$currentDirInfo = ProcessCurrentDirectory -path "C:\ModuleDirectory\SubFolder" -parentDirName "SubFolder" -metadataFileName "_metadata.json"

Processes the specified directory and returns detailed information about its contents.

.OUTPUTS
PSCustomObject
A custom object containing detailed information about the current directory, including metadata, files, and subdirectories.

#>
function ProcessCurrentDirectory {
    param(
        [string]$path,
        [string]$parentDirName,
        [string]$metadataFileName
    )

    # Initialize an object for this directory
    $dirResult = [PSCustomObject]@{
        Name         = $parentDirName
        Metadata     = Get-Content -Raw -Path $metadataFileName | ConvertFrom-Json
        Timelines    = @()
        IncludeFiles = @()
        Paths        = Get-Parent-Paths -filePath $metadataFileName
        Files        = @()
        SubFolders   = @()        
    }

    if ($null -eq $parentDirName -or $parentDirName.Trim().Length -eq 0) {
        $dirResult.Name = $dirResult.Metadata.Category
    }

    foreach ($file in Get-ChildItem -Path $path) {
        if ($file.PSIsContainer) {
            # Recursive call for subdirectories
            $subDirResult = ProcessModuleDirectory -path $file.FullName -parentDirName $file.Name
            $dirResult.SubFolders += $subDirResult
        }
        elseif ($file.Extension.ToLower() -eq '.dat' -and $file.Length -gt 0) {
            # Process .dat files
            ProcessDatFile -file $file -dirResult $dirResult -path $path
        }
    }

    return $dirResult
}

<#
.SYNOPSIS
    Reads a timeline file and extracts quest names, providing both original and sanitized versions.

.DESCRIPTION
    The Read-TimelineFile function reads a specified timeline file line by line and extracts names of quests from lines that start with 'Quest'. It returns an array of objects, each containing the original quest name and a sanitized version with non-alphanumeric characters removed.

.PARAMETER timelineFileName
    The path of the timeline file to be read. This parameter expects a string representing the file path.

.OUTPUTS
    An array of quests (Name and HeaderName) found in the Timeline file. 
#>

function Read-TimelineFile {
    param([string]$timelineFileName)

    $quests = @()

    Get-Content $timelineFileName | ForEach-Object {
        if ($_ -match '^Quest "(.*)"') {
            $quests += [PSCustomObject]@{
                Name       = $matches[1]
                HeaderName = $matches[1] -replace '[^\w\d]', ''
            }
        }
    }

    return $quests
}

<#
.SYNOPSIS
Processes a .dat file in a module directory.

.DESCRIPTION
ProcessDatFile handles the processing of a .dat file, converting it to a header file format and adding it to the directory result object. It checks for specific conditions such as empty files and timeline files.

.PARAMETER file
The FileInfo object representing the .dat file to process.

.PARAMETER dirResult
The directory result object to which the file information will be added.

.PARAMETER path
The path of the directory containing the .dat file.

.EXAMPLE
ProcessDatFile -file $fileInfo -dirResult $dirResult -path "C:\ModuleDirectory\SubFolder"

Processes a given .dat file and updates the directory result object with its information.

.OUTPUTS
None. The function updates the dirResult object but does not return a value.

#>
function ProcessDatFile {
    param(
        [System.IO.FileInfo]$file,
        [PSCustomObject]$dirResult,
        [string]$path
    )    

    Convert-DATFile-ToHeaderFile -filePath $file -modulePath $path
    $includeFile = (Get-Relative-FilePath -filePath $file -basePath "$PSScriptRoot\..").Replace(".dat", ".h")
    $dirResult.IncludeFiles += $includeFile

    $firstLine = Get-Content $file.FullName -TotalCount 1
    if ($firstLine.Trim() -eq "") {
        Write-Warning "Skipping DAT file $($file.Name) because the first line is empty."
        return
    }

    if ($file.BaseName.ToLower().EndsWith("timeline")) {
        $dirResult.Timelines += [PSCustomObject]@{
            Name     = $firstLine
            FileName = $file.BaseName
            Quests   = Read-TimelineFile $file
        }        
    }

    $fileInfo = [PSCustomObject]@{
        Name     = $file.BaseName
        Title    = $firstLine
        FileName = $file.FullName
    }

    $dirResult.Files += $fileInfo
}
