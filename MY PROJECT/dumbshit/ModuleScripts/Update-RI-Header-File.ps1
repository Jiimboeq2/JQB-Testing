. "$PSScriptRoot/Get-TimelineQuests"

<#
.SYNOPSIS
Finds the last block index in the file where a pattern is matched.

.DESCRIPTION
The FindLastBlockIndex function searches for the last occurrence of a block matching a specified pattern in a file. The pattern is defined to find blocks with "_CatName.Equal[...]" and returns the line number immediately after the closing brace of the last block.

.PARAMETER fileContents
The contents of the file as a string.

.OUTPUTS
Integer. Returns the line number immediately after the closing brace of the last block.

.EXAMPLE
$lastIndex = FindLastBlockIndex -fileContents $fileContents
#>
function FindLastBlockIndex {
    param(
        [string]$fileContents
    )

    $pattern = "\{_CatName\.Equal\[(.+?)\]}\s*\{"
    $patternMatches = Select-String -Pattern $pattern -InputObject $fileContents -AllMatches

    if ($patternMatches.Matches.Count -gt 0) {
        $lastMatch = $patternMatches.Matches[$patternMatches.Matches.Count - 1]
        $lastBlockName = $lastMatch.Groups[1].Value

        # Find the block using the last block name
        $blockInfo = FindBlockByName -blockName $lastBlockName -fileContents $fileContents
        if ($null -ne $blockInfo) {
            # Find the closing brace for the last block
            $closingBracePattern = "\}"
            $fileLines = $fileContents -split "\r?\n"
            for ($i = $blockInfo.StartPosition; $i -lt $fileLines.Length; $i++) {
                if ($fileLines[$i] -match $closingBracePattern) {
                    return $i + 2  # Return the line number immediately after the closing brace
                }
            }
        }
    }

    return $null
}

<#
.SYNOPSIS
Finds a specific block by name within file contents.

.DESCRIPTION
The FindBlockByName function searches for a block within the file contents that matches a specified name. If found, it returns an object containing the block's name, start position, end position, and data.

.PARAMETER blockName
The name of the block to find.

.PARAMETER fileContents
The contents of the file as a string.

.OUTPUTS
PSCustomObject. Returns an object containing block name, start position, end position, and data.

.EXAMPLE
$blockInfo = FindBlockByName -blockName "MyBlock" -fileContents $fileContents
#>
function FindBlockByName {
    param(
        [string]$blockName,
        [string]$fileContents
    )

    # Regex pattern to match the specific block
    $pattern = "\{_CatName\.Equal\[$blockName\]}\s*\{(.+?)\}\s*"

    # Find the match
    $match = [regex]::Match($fileContents, $pattern, 'Singleline')

    if ($match.Success) {
        # Calculate the start position
        $linesBeforeMatch = $fileContents.Substring(0, $match.Index) -split "\r?\n"
        $startPosition = $linesBeforeMatch.Count

        # Extract the block lines
        $blockLines = $match.Groups[1].Value.Trim() -split "\r?\n"
        $blockLines[0] = Format-Element -elementData $blockLines[0]
        $endPosition = $startPosition + $blockLines.Count + 2 

        # Return an object with start position, end position, and data
        return [PSCustomObject]@{
            BlockName     = $blockName
            StartPosition = $startPosition
            EndPosition   = $endPosition
            Data          = $blockLines
        }
    }
    else {
        return $null
    }
}


<#
.SYNOPSIS
Adds a category item to the RQ method block if it doesn't exist.

.DESCRIPTION
The Add-Category-To-RQ-Method-Block function adds a new category item to the RQ method block in the specified file, only if the item does not already exist in the block.

.PARAMETER headerFilePath
The file path of the header file to update.

.PARAMETER itemName
The name of the item to add.

.EXAMPLE
Add-Category-To-RQ-Method-Block -headerFilePath "path\to\header.iss" -itemName "NewCategory"
#>
function Add-Category-To-RQ-Method-Block {
    param(
        [string]$headerFilePath,
        [string]$itemName
    )

    $fileContents = Get-Content -Path $headerFilePath -Raw
    $fileLines = $fileContents -split "\r?\n"

    $addItems = @()
    $itemExists = $false
    $lastAddItemLine = -1

    # Find all instances of UIElement[CategoryComboBox@RI]:AddItem
    for ($i = 0; $i -lt $fileLines.Length; $i++) {
        if ($fileLines[$i] -match "UIElement\[CategoryComboBox@RI\]:AddItem\[(.+)\]") {
            $addItems += @{ Line = $i; Content = $fileLines[$i] }

            # Check if the item already exists
            if ($matches[1] -like "*$itemName*") {
                $itemExists = $true
                break
            }

            $lastAddItemLine = $i
        }
    }

    # If the item is not found, add it
    if (-not $itemExists -and $lastAddItemLine -ne -1) {
        $newLine = Format-Element -elementData "UIElement[CategoryComboBox@RI]:AddItem[`"$itemName`"]" -tabCount 3
        $fileLines = $fileLines[0..$lastAddItemLine] + $newLine + $fileLines[($lastAddItemLine + 1)..($fileLines.Length - 1)]
        $fileContents = $fileLines -join "`r`n"
        
        # Write the updated contents back to the file
        $fileContents | Set-Content -Path $headerFilePath
    }
}

<#
.SYNOPSIS
Updates or appends a block of content in a file.

.DESCRIPTION
The Update-Block-InFile function updates an existing block or appends a new block of content in the specified file. If the block exists, it overwrites it; otherwise, it appends the new block at the specified position.

.PARAMETER blockInfo
The information about the block to be updated or appended.

.PARAMETER headerFilePath
The file path of the header file to update.

.EXAMPLE
Update-Block-InFile -blockInfo $blockInfo -headerFilePath "path\to\header.iss"
#>
function Update-Block-InFile {
    param(
        [PSCustomObject]$blockInfo,
        [string]$headerFilePath
    )

    $fileContents = Get-Content -Path $headerFilePath -Raw
    $fileLines = $fileContents -split "\r?\n"

    $beforeBlock = $fileLines[0..($blockInfo.StartPosition - 2)]
    $tempData = @()
    $tempData += Format-Element -elementData "elseif `${_CatName.Equal[$($blockInfo.BlockName)]}" -tabCount 3
    $tempData += Format-Element -elementData "{" -tabCount 3
    $tempData += $blockInfo.Data
    $tempData += Format-Element -elementData "}" -tabCount 3
    $blockInfo.Data = $tempData

    # If we start and end of the same line, we need some breathing room so as to try and not overwrite
    # data. That being said, someone can probably manually edit the file to really throw a wrench in the parsing. 
    # This file is not meant to be a syntax checker/formatter/uWu file at all, mostly due to the complexity of the ISS file format. 
    if ($blockInfo.EndPosition -eq $blockInfo.StartPosition) {
        $blockInfo.EndPosition -= 1
    }
    $afterBlock = $fileLines[$blockInfo.EndPosition..($fileLines.Count - 2)]

    # Combine before block, new content, and after block
    $updatedFileLines = $beforeBlock + $blockInfo.Data + $afterBlock
    $updatedFileLines -join "`r`n" | Out-File -FilePath $headerFilePath -Encoding UTF8
    Write-Host "Block '$($blockInfo.BlockName)' updated successfully in file '$headerFilePath'." -ForegroundColor Green
}

<#
.SYNOPSIS
Formats an element with a specified number of tabs.

.DESCRIPTION
The Format-Element function formats a string element, prepending it with a specified number of tab characters.

.PARAMETER elementData
The data string to format.

.PARAMETER tabCount
The number of tabs to prepend. Default is 4.

.EXAMPLE
$formattedElement = Format-Element -elementData "MyData" -tabCount 2
#>
function Format-Element {
    param(
        [string]$elementData,
        [int]$tabCount = 4
    )

    return "`t" * $tabCount + $elementData
}

<#
.SYNOPSIS
Extracts text from a block based on a specific pattern.

.DESCRIPTION
The Get-Block-Text function extracts text from a given block based on a regex pattern, specifically designed to extract text between quotes in an AddItem call.

.PARAMETER block
The block of text to extract the data from.

.EXAMPLE
$itemText = Get-Block-Text -block $block
#>
function Get-Block-Text {
    param([string]$block)

    $pattern = 'AddItem\[\s*"?(.*?)(?:"|\s*,|\s*\])'
    $match = [regex]::Match($block, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    else {
        return $null
    }
}
<#
.SYNOPSIS
Adds a UIElement to a category block if it doesn't already exist.

.DESCRIPTION
The Add-UIElement-To-Category function adds a UIElement line to the category block only if the specified UIElement does not already exist in the block data.

.PARAMETER blockInfo
Information about the block to which the UIElement is to be added.

.PARAMETER item
The UIElement line to add to the category block.

.EXAMPLE
Add-UIElement-To-Category -blockInfo $blockInfo -item "UIElement[QuestsListBox@RI]:AddItem[\"NewItem\"]"
#>
function Add-UIElement-To-Category {
    param(
        [PSCustomObject]$blockInfo,
        [string]$item
    )
    $isFound = $false
    $itemText = Get-Block-Text -block $item
    
    foreach ($blockItem in $blockInfo.Data) {
        $blockText = Get-Block-Text -block $blockItem
        if ($blockText -eq $itemText) {
            $isFound = $true
        }
    }
    
    if (-not $isFound) {
        $blockInfo.Data += Format-Element -elementData $item
    }
}


<#
.SYNOPSIS
Updates the RI header file with new block data or appends a new block.

.DESCRIPTION
The Update-RI-Header-File function updates the RI header file by either updating existing block data or appending a new block, based on the module data provided.

.PARAMETER moduleData
The module data to be used for updating or appending in the RI header file.

.PARAMETER headerFilePath
The file path of the RI header file to update.

.EXAMPLE
Update-RI-Header-File -moduleData $moduleData -headerFilePath "path\to\RI.iss"
#>
function Update-RI-Header-File {
    param(
        [PSCustomObject]$moduleData,
        [string]$headerFilePath,
        [string]$fileKey = $null
    )

    Write-Host "Updating and Encrypting $headerFilePath" -ForegroundColor Magenta

    $blockName = $moduleData.Name
    Add-Category-To-RQ-Method-Block -headerFilePath $headerFilePath -itemName $blockName

    $fileContents = Get-Content -Path $headerFilePath -Raw
    $blockInfo = FindBlockByName -blockName $blockName -fileContents $fileContents

    if ($null -eq $blockInfo) {
        $lastIndex = FindLastBlockIndex -fileContents $fileContents
        $blockInfo = [PSCustomObject]@{
            BlockName     = $blockName
            StartPosition = $lastIndex
            EndPosition   = $lastIndex
            Data          = @()
        }
    }
      
    # Let's overwrite every qquest in the blockInfo ofor now so that we update the entire block. 
    $blockInfo.Data = @(Format-Element -elementData "UIElement[QuestsListBox@RI]:ClearItems")

    # Determine which files should not be added to the UIElements list
    $ignoreList = $moduleData.Metadata.Ignore  | Where-Object { $_.UIElement -eq $true } | ForEach-Object { $_.File }

    if ($null -ne $moduleData.Metadata.PreferredOrder) {
        $moduleData.Metadata.PreferredOrder | ForEach-Object {
            $ignoreList += $_
            if ($_.ToLower().EndsWith("timeline")) {
                Add-UIElement-To-Category -blockInfo $blockInfo -item "UIElement[QuestsListBox@RI]:AddItem[""$_"",0,FFE8E200]"
            }
            else {
                Add-UIElement-To-Category -blockInfo $blockInfo -item "UIElement[QuestsListBox@RI]:AddItem[""$_""]"
            }
        }
    }
    $timelineQuests = Get-TimelineQuests -moduleData $moduleData

    $filesToInclude = $moduleData.Files | Where-Object {
        $fileName = [System.IO.Path]::GetFileName($_.FileName)
        $fileName -notin $ignoreList -and $_.Title -notin $timelineQuests
    }

    # Add Timelines
    foreach ($timeline in $moduleData.Timelines) {
        Add-UIElement-To-Category -blockInfo $blockInfo -item "UIElement[QuestsListBox@RI]:AddItem[""$($timeline.Name)"",0,FFE8E200]"
    }       

    $filesToInclude | ForEach-Object { 
        Add-UIElement-To-Category -blockInfo $blockInfo -item "UIElement[QuestsListBox@RI]:AddItem[""$($_.Title)""]"        
    }
    Update-Block-InFile -blockInfo $blockInfo -headerFilePath $headerFilePath

    if ($null -ne $fileKey -and $fileKey.Trim().Length -gt 0) {
        Write-Host "Encrypting file $headerFilePath" -ForegroundColor Magenta
        ./LSCrypt.exe -encrypt $fileKey $headerFilePath tmp.txt
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($headerFilePath)
        ./GenInclude.exe tmp.txt $fileNameWithoutExtension
        Copy-Item -Path "$fileNameWithoutExtension.h" -Destination $([System.IO.Path]::GetDirectoryName($headerFilePath)  )
        Remove-Item "$fileNameWithoutExtension.h"
        Remove-Item tmp.txt
    }

}