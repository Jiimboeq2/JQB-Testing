<#
.SYNOPSIS
Merges include file paths from a module data object and its subfolders.

.DESCRIPTION
The Merge-IncludeFiles function recursively merges file paths specified in the 'IncludeFiles' property of a module data object, including paths from its 'SubFolders' property. This function is typically used to consolidate file paths from a hierarchical structure of module data.

.PARAMETER moduleData
The module data object containing 'IncludeFiles' and 'SubFolders' properties.

.EXAMPLE
$moduleData = @{ IncludeFiles = @('path1', 'path2'); SubFolders = @(@{ IncludeFiles = @('path3') }) }
$mergedFiles = Merge-IncludeFiles -moduleData $moduleData
# This will return an array of paths: 'path1', 'path2', and 'path3'.

.OUTPUTS
System.Array
An array of strings, each representing a file path included in the module data and its subfolders.

#>
function Merge-IncludeFiles {

    param(
        [PSCustomObject]$moduleData
    )

    if ($null -ne $moduleData.IncludeFiles) {
        $includeFiles = $moduleData.IncludeFiles
    }

    if ($null -ne $moduleData.SubFolders) {
        foreach ($subFolder in $moduleData.SubFolders) {
            $includeFiles += Merge-IncludeFiles -moduleData $subFolder            
        }           
    }

    return $includeFiles
}

<#
.SYNOPSIS
Updates a Visual Studio project file with include files from module data.

.DESCRIPTION
The Update-Project-Includes function updates a Visual Studio project file (.vcxproj) by adding 'ClInclude' elements for each file path in the provided module data. It checks for existing include files to prevent duplication and adds any missing files to the project. This is useful for dynamically updating project files in automation scripts.

.PARAMETER moduleData
The module data object containing 'IncludeFiles' and possibly 'SubFolders' from which the include files are to be sourced.

.PARAMETER projectFilePath
The file path of the Visual Studio project file (.vcxproj) to be updated.

.EXAMPLE
$moduleData = @{ IncludeFiles = @('include\file1.h', 'include\file2.h') }
Update-Project-Includes -moduleData $moduleData -projectFilePath "C:\Projects\MyApp\MyApp.vcxproj"
# This will add 'ClInclude' elements for 'file1.h' and 'file2.h' to the MyApp.vcxproj file if they are not already present.

.OUTPUTS
None. This function directly modifies the specified project file.

.NOTES
The function handles the creation of new 'ClInclude' elements in the context of the project file's XML structure and ensures that duplicate entries are not created.

#>
function Update-Project-Includes {
    param(
        [PSCustomObject]$moduleData,
        [string]$projectFilePath
    )

    if (-not (Test-Path -Path $projectFilePath -PathType Leaf)) {
        Write-Host "File $projectFilePath was not found" -ForegroundColor Red
        Return
    }

    $includeFiles = Merge-IncludeFiles -moduleData $moduleData

    $vcxproj = [XML](Get-Content $projectFilePath -Raw -Encoding UTF8)
    $namespaceUri = $vcxproj.DocumentElement.NamespaceURI

    $clIncludeItemGroup = $vcxproj.Project.ItemGroup | Where-Object { $_.ClInclude }

    # If there's no such CLInclude ItemGroup, then let's create one
    if (-not $clIncludeItemGroup) {
        $clIncludeItemGroup = $vcxproj.CreateElement("ItemGroup")
        $vcxproj.Project.AppendChild($clIncludeItemGroup) > $null
    }    

    foreach ($file in $includeFiles) {
        $includeFileName = $file.Replace("..\", "").Replace("/", "\")
        # Check if the file is already in the ItemGroup
        $existingInclude = $clIncludeItemGroup.ClInclude | Where-Object { $_.Include -eq $includeFileName }
        
        if (-not $existingInclude) {
            # Use the namespace URI to create the element. This will prevent an empty xmlns from being added to the final output. 
            $newInclude = $vcxproj.CreateElement("ClInclude", $namespaceUri)
            $newInclude.SetAttribute("Include", $includeFileName)
            
            $clIncludeItemGroup.AppendChild($newInclude) > $null
            Write-Host "Added $includeFileName" -ForegroundColor Magenta
        }
    }

    try {
        $vcxproj.Save($projectFilePath)    
    }
    catch {
        Write-Error "Error trying to write to file $($projectFilePath): $_"
    }
}