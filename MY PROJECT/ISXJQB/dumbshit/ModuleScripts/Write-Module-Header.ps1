. "$PSScriptRoot/Get-Relative-FilePath"

<#
.SYNOPSIS
Generates a C++ header file for module initialization.

.DESCRIPTION
The Write-Module-Header function generates a C++ header file named '_InitializeModule.h' based on the provided module data. It includes module file includes, forward declarations, and functions necessary for Top-Level Object (TLO) handling in a C++ environment. The function constructs the necessary C++ code and writes it to a header file in the specified module path. It also processes subfolders recursively.

.PARAMETER modulePath
The path where the '_InitializeModule.h' file will be created.

.PARAMETER moduleData
A custom object representing the module data, which contains information about files, subfolders, and other module-specific data used to generate the header file.

.EXAMPLE
Write-Module-Header -modulePath "C:\ModulePath" -moduleData $myModuleData

This command generates the '_InitializeModule.h' file in the specified module path using the provided module data.

.OUTPUTS
None. This function does not return any output, but it generates a new C++ header file at the specified location.

.NOTES
This function is specifically designed for C++ module initialization and requires an understanding of the module structure and the necessary declarations for proper integration.

#>

function Write-Module-Header {     
    param (
        [string]$modulePath,
        [PSCustomObject]$moduleData
    )

    if ($null -eq $moduleData) {
        Return
    }

    $initModuleFileName = "_InitializeModule.h"

    Write-Host "Generating $initModuleFileName in $modulePath" -ForegroundColor Magenta

    $moduleFileIncludes = ""
    $forwardDeclarations = ""
    $addTLOStatements = ""
    $removeTLOStatements = ""
    $tloFunctions = ""

    # Process Subfolders first
    foreach ($subFolder in $moduleData.SubFolders) {
        $subFolderPath = Join-Path $modulePath $subFolder.Name
        Write-Module-Header -modulePath $subFolderPath -moduleData $subFolder
        $moduleFileIncludes += "#include ""$($subFolder.Name)\$initModuleFileName""`n"
    }    

    foreach ($moduleFile in $moduleData.Files) {
        if ($null -eq $moduleFile.Name) {
            Continue
        }
        $name = $moduleFile.Name
        $moduleFileIncludes += "#include ""$name.h""`n"
        $forwardDeclarations += "bool TLO_$name(int argc, char* argv[], LSTYPEVAR& dest);`n"
        $addTLOStatements += "pISInterface->AddTopLevelObject(""$($name.ToUpper())"", TLO_$name);`n        "
        $removeTLOStatements += "pISInterface->RemoveTopLevelObject(""$($name.ToUpper())"");`n        "
        $tloFunctionTemplate = @"

bool TLO_$name(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction($name, argc, argv, dest);
}`n`n
"@            
        $tloFunctions += $tloFunctionTemplate
    }


    $moduleTemplate = @"

#include <memory>
#include "CommonDeclarations.h"
#include "LavishScript.h"
    
#pragma region Module file includes
$moduleFileIncludes
#pragma endregion
    
#pragma region Forward Declarations
$forwardDeclarations
#pragma endregion
        
class TLOHandler : public ITLOHandler
{
public:
	static std::shared_ptr<TLOHandler> Create()
	{
		std::shared_ptr<TLOHandler> instance(new TLOHandler(), [](TLOHandler* p)
			{ delete p; });
		TLOHandlerRegistry::RegisterHandler(instance);
		return instance;
	}
     
#pragma region Register TLO Function
    void RegisterTLOs(ISInterface* pISInterface) override
    {
        $addTLOStatements
    }
#pragma endregion
    
#pragma region Deregister TLO Function
    void DeregisterTLOs(ISInterface* pISInterface) override
    {
        $removeTLOStatements
    }
#pragma endregion
    
private:
    TLOHandler() = default;
    ~TLOHandler() override = default;
};
    
// Automatically create a new instance of the module
auto handlerInstance = TLOHandler::Create();
    
#pragma region TLO Functions
$tloFunctions
#pragma endregion    
"@    

    $moduleData.IncludeFiles += Get-Relative-FilePath -filePath "$modulePath/$initModuleFileName" -basePath (Split-Path -Path $PSScriptRoot -Parent)
    $moduleData | Add-Member -MemberType NoteProperty -Name "ModuleFile" -Value (Get-Relative-FilePath -filePath "$($modulePath)\$initModuleFileName" -basePath "$PSScriptRoot\..\include")
    $moduleTemplate -replace "`r`n", "`n" -replace "`n", "`r`n" | Out-File -FilePath "$modulePath/$initModuleFileName" -Encoding UTF8
}