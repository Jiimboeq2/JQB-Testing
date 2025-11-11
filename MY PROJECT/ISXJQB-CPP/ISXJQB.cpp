#include "ISXJQB.h"
#include <stdio.h>

// Global interface and service handles
ISInterface *pISInterface = nullptr;
HISXSERVICE hPulseService = 0;
HISXSERVICE hMemoryService = 0;
HISXSERVICE hHTTPService = 0;
HISXSERVICE hTriggerService = 0;
HISXSERVICE hSystemService = 0;

ISXJQB *pExtension = nullptr;

// LavishScript type pointers
LSType *pStringType = nullptr;
LSType *pIntType = nullptr;
LSType *pUintType = nullptr;
LSType *pBoolType = nullptr;
LSType *pFloatType = nullptr;
LSType *pTimeType = nullptr;
LSType *pByteType = nullptr;
LSType *pIntPtrType = nullptr;
LSType *pBoolPtrType = nullptr;
LSType *pFloatPtrType = nullptr;
LSType *pBytePtrType = nullptr;

char JQB_Version[] = "1.0.0";

// ==================== Static Member Definitions ====================
// These must be defined in exactly ONE .cpp file to avoid linker errors

// JQBAuth static members
std::string JQBAuth::PayPalEmail = "";
std::string JQBAuth::LicenseKey = "";
bool JQBAuth::IsAuthenticated = false;
std::string JQBAuth::AuthFilePath = "";

// KeyDerivation static members
const unsigned char KeyDerivation::KEY_PART1[] = {
    0x4A, 0x51, 0x42, 0x2D, 0x53, 0x65, 0x63, 0x72,  // "JQB-Secr"
    0x65, 0x74, 0x2D, 0x50, 0x61, 0x72, 0x74, 0x31   // "et-Part1"
};

const unsigned char KeyDerivation::KEY_PART2[] = {
    0x58, 0x4F, 0x52, 0x2D, 0x4B, 0x65, 0x79, 0x2D,  // "XOR-Key-"
    0x50, 0x61, 0x72, 0x74, 0x2D, 0x54, 0x77, 0x6F   // "Part-Two"
};

const unsigned char KeyDerivation::XOR_SALT[] = {
    0x3C, 0x1E, 0x30, 0x02, 0x37, 0x00, 0x57, 0x5D,
    0x05, 0x15, 0x1D, 0x24, 0x4C, 0x26, 0x53, 0x4E
};

unsigned char KeyDerivation::SessionSalt[16] = {0};
bool KeyDerivation::SaltInitialized = false;

// PatchManager static members
std::vector<Patch> PatchManager::Patches;
std::vector<Hook> PatchManager::Hooks;

ISXJQB::ISXJQB(void)
{
    pExtension = this;
}

ISXJQB::~ISXJQB(void)
{
}

bool ISXJQB::Initialize(ISInterface *p_ISInterface)
{
    pISInterface = p_ISInterface;

    // Initialize derivative key system
    KeyDerivation::InitializeSessionSalt();

    printf("\arISXJQB v%s Loading...", JQB_Version);

    // Get LavishScript type pointers
    pStringType = pISInterface->FindLSType("string");
    pIntType = pISInterface->FindLSType("int");
    pUintType = pISInterface->FindLSType("uint");
    pBoolType = pISInterface->FindLSType("bool");
    pFloatType = pISInterface->FindLSType("float");
    pTimeType = pISInterface->FindLSType("time");
    pByteType = pISInterface->FindLSType("byte");
    pIntPtrType = pISInterface->FindLSType("intptr");
    pBoolPtrType = pISInterface->FindLSType("boolptr");
    pFloatPtrType = pISInterface->FindLSType("floatptr");
    pBytePtrType = pISInterface->FindLSType("byteptr");

    RegisterExtension();

    printf("\agISXJQB v%s Loaded Successfully!", JQB_Version);

    return true;
}

void ISXJQB::Shutdown()
{
    printf("\arISXJQB v%s Shutting down...", JQB_Version);

    // Remove all patches and hooks before shutting down
    PatchManager::RemoveAllPatches();
    PatchManager::RemoveAllHooks();

    DisconnectServices();
    UnRegisterCommands();
    UnRegisterAliases();
    UnRegisterDataTypes();
    UnRegisterTopLevelObjects();
    UnRegisterServices();

    printf("\agISXJQB v%s Shutdown complete.", JQB_Version);
}

void ISXJQB::RegisterExtension()
{
    ConnectServices();

    // Initialize systems
    JQBAuth::Initialize();
    PatchManager::Initialize();

    // Load and verify authentication
    printf("\\ay[ISXJQB] Loading authentication...");
    if (JQBAuth::LoadAuthFile())
    {
        JQBAuth::VerifyLicense();
    }
    else
    {
        printf("\\ar[ISXJQB] No auth file found - creating sample");
        JQBAuth::CreateSampleAuthFile();
    }

    // TODO: Add your game file hashes here for integrity verification
    // Example:
    // PatchManager::RegisterFileHash("C:\\Games\\EQ2\\eq2.exe", "expected_sha256_hash_here");

    // TODO: Register your patches here
    // Example:
    // unsigned char origBytes[] = { 0x74, 0x05 }; // JZ instruction
    // unsigned char patchBytes[] = { 0x90, 0x90 }; // NOP NOP
    // PatchManager::RegisterPatch("DisableCheck", "Disables safety check",
    //                            0x12345678, origBytes, sizeof(origBytes),
    //                            patchBytes, sizeof(patchBytes), "Safety");

    // TODO: Register your hooks here
    // Example:
    // PatchManager::RegisterHook("HookFunction", "Hooks target function",
    //                           0x87654321, MyDetourFunc, OriginalFunc, "Hooks");

    // Apply patches and install hooks
    // PatchManager::ApplyAllPatches();
    // PatchManager::InstallAllHooks();

    RegisterCommands();
    RegisterAliases();
    RegisterDataTypes();
    RegisterTopLevelObjects();
    RegisterServices();
    RegisterTriggers();

    printf("\\ag[ISXJQB] Loaded: %d patches, %d hooks registered",
           PatchManager::GetPatchCount(), PatchManager::GetHookCount());
}

void ISXJQB::ConnectServices()
{
    // Connect to InnerSpace services
    hMemoryService = pISInterface->ConnectService(pExtension, "Memory", 0);
    hPulseService = pISInterface->ConnectService(pExtension, "Pulse", 0);
    hHTTPService = pISInterface->ConnectService(pExtension, "HTTP", 0);
    hTriggerService = pISInterface->ConnectService(pExtension, "Triggers", 0);
    hSystemService = pISInterface->ConnectService(pExtension, "System", 0);

    if (hMemoryService)
        printf("\ag[ISXJQB] Connected to Memory Service");
    if (hPulseService)
        printf("\ag[ISXJQB] Connected to Pulse Service");
    if (hHTTPService)
        printf("\ag[ISXJQB] Connected to HTTP Service");
    if (hTriggerService)
        printf("\ag[ISXJQB] Connected to Trigger Service");
    if (hSystemService)
        printf("\ag[ISXJQB] Connected to System Service");
}

void ISXJQB::DisconnectServices()
{
    if (hMemoryService)
    {
        pISInterface->DisconnectService(pExtension, hMemoryService);
        hMemoryService = 0;
    }
    if (hPulseService)
    {
        pISInterface->DisconnectService(pExtension, hPulseService);
        hPulseService = 0;
    }
    if (hHTTPService)
    {
        pISInterface->DisconnectService(pExtension, hHTTPService);
        hHTTPService = 0;
    }
    if (hTriggerService)
    {
        pISInterface->DisconnectService(pExtension, hTriggerService);
        hTriggerService = 0;
    }
    if (hSystemService)
    {
        pISInterface->DisconnectService(pExtension, hSystemService);
        hSystemService = 0;
    }
}

void ISXJQB::RegisterCommands()
{
    // Commands will be registered by module system
    // See Commands.h for command definitions
}

void ISXJQB::UnRegisterCommands()
{
    // Commands will be unregistered by module system
}

void ISXJQB::RegisterAliases()
{
    // Register any command aliases here
}

void ISXJQB::UnRegisterAliases()
{
    // Unregister aliases
}

void ISXJQB::RegisterDataTypes()
{
    // DataTypes will be registered by module system
    // See DataTypes.h for datatype definitions
}

void ISXJQB::UnRegisterDataTypes()
{
    // DataTypes will be unregistered by module system
}

void ISXJQB::RegisterTopLevelObjects()
{
    // TLOs will be registered by module system
    // See TopLevelObjects.h for TLO definitions
}

void ISXJQB::UnRegisterTopLevelObjects()
{
    // TLOs will be unregistered by module system
}

void ISXJQB::RegisterServices()
{
    // Custom services will be registered here
    // See Services.h for service definitions
}

void ISXJQB::UnRegisterServices()
{
    // Unregister custom services
}

void ISXJQB::RegisterTriggers()
{
    // Register any triggers here
}

// DLL Entry Point
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        // Initialize
        break;
    case DLL_PROCESS_DETACH:
        // Cleanup
        break;
    }
    return TRUE;
}

// InnerSpace extension export
extern "C" __declspec(dllexport) ISXInterface *GetISXInterface()
{
    return new ISXJQB;
}
