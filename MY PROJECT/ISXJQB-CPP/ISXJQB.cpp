#include "ISXJQB.h"
#include <stdio.h>

// Global interface and service handles
ISInterface *pISInterface = nullptr;
HISXSERVICE hPulseService = nullptr;
HISXSERVICE hMemoryService = nullptr;
HISXSERVICE hHTTPService = nullptr;
HISXSERVICE hTriggerService = nullptr;
HISXSERVICE hSystemService = nullptr;

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
    RegisterCommands();
    RegisterAliases();
    RegisterDataTypes();
    RegisterTopLevelObjects();
    RegisterServices();
    RegisterTriggers();
}

void ISXJQB::ConnectServices()
{
    // Connect to InnerSpace services
    hMemoryService = pISInterface->ConnectToService(pExtension, "Memory");
    hPulseService = pISInterface->ConnectToService(pExtension, "Pulse");
    hHTTPService = pISInterface->ConnectToService(pExtension, "HTTP");
    hTriggerService = pISInterface->ConnectToService(pExtension, "Triggers");
    hSystemService = pISInterface->ConnectToService(pExtension, "System");

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
        pISInterface->DisconnectFromService(pExtension, hMemoryService);
        hMemoryService = nullptr;
    }
    if (hPulseService)
    {
        pISInterface->DisconnectFromService(pExtension, hPulseService);
        hPulseService = nullptr;
    }
    if (hHTTPService)
    {
        pISInterface->DisconnectFromService(pExtension, hHTTPService);
        hHTTPService = nullptr;
    }
    if (hTriggerService)
    {
        pISInterface->DisconnectFromService(pExtension, hTriggerService);
        hTriggerService = nullptr;
    }
    if (hSystemService)
    {
        pISInterface->DisconnectFromService(pExtension, hSystemService);
        hSystemService = nullptr;
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
