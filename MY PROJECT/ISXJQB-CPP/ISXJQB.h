#pragma once
#include <windows.h>
#include <ISXDK.h>
#include "KeyDerivation.h"

class ISXJQB : public ISXInterface
{
public:
    ISXJQB(void);
    ~ISXJQB(void);

    virtual bool Initialize(ISInterface *p_ISInterface);
    virtual void Shutdown();

    void RegisterExtension();

    void ConnectServices();
    void RegisterCommands();
    void RegisterAliases();
    void RegisterDataTypes();
    void RegisterTopLevelObjects();
    void RegisterServices();
    void RegisterTriggers();

    void DisconnectServices();
    void UnRegisterCommands();
    void UnRegisterAliases();
    void UnRegisterDataTypes();
    void UnRegisterTopLevelObjects();
    void UnRegisterServices();
};

// Global interface pointers
extern ISInterface *pISInterface;
extern HISXSERVICE hPulseService;
extern HISXSERVICE hMemoryService;
extern HISXSERVICE hHTTPService;
extern HISXSERVICE hTriggerService;
extern HISXSERVICE hSystemService;

extern ISXJQB *pExtension;
#define printf pISInterface->Printf

// Memory Patching Macros - Easy detour/hook functions
#define EzDetour(Address, Detour, Trampoline) \
    IS_Detour(pExtension, pISInterface, hMemoryService, (UINT_PTR)Address, (UINT_PTR)Detour, (UINT_PTR)Trampoline, -1)

#define EzUnDetour(Address) \
    IS_UnDetour(pExtension, pISInterface, hMemoryService, (UINT_PTR)Address)

#define EzDetourAPI(_Detour_, _DLLName_, _FunctionName_, _FunctionOrdinal_) \
    IS_DetourAPI(pExtension, pISInterface, hMemoryService, (UINT_PTR)_Detour_, (UINT_PTR)_DLLName_, (UINT_PTR)_FunctionName_, (UINT_PTR)_FunctionOrdinal_, -1)

#define EzUnDetourAPI(Address) \
    IS_UnDetourAPI(pExtension, pISInterface, hMemoryService, (UINT_PTR)Address)

// Memory modification macros
#define EzModify(Address, NewData, Length, Reverse) \
    Memory_Modify(pExtension, pISInterface, hMemoryService, (UINT_PTR)Address, NewData, Length, Reverse)

#define EzUnModify(Address) \
    Memory_UnModify(pExtension, pISInterface, hMemoryService, (UINT_PTR)Address)

// HTTP request macro
#define EzHttpRequest(_URL_, _pData_) \
    IS_HttpRequest(pExtension, pISInterface, hHTTPService, _URL_, _pData_)

// Trigger macros
#define EzAddTrigger(Text, Callback, pUserData) \
    IS_AddTrigger(pExtension, pISInterface, hTriggerService, Text, Callback, pUserData)

#define EzRemoveTrigger(ID) \
    IS_RemoveTrigger(pExtension, pISInterface, hTriggerService, ID)

#define EzCheckTriggers(Text) \
    IS_CheckTriggers(pExtension, pISInterface, hTriggerService, Text)

// Enhanced crash filter with logging
static LONG EzCrashFilter(_EXCEPTION_POINTERS *pExceptionInfo, const char *szIdentifier, ...)
{
    unsigned int Code = pExceptionInfo->ExceptionRecord->ExceptionCode;
    if (Code == EXCEPTION_BREAKPOINT || Code == EXCEPTION_SINGLE_STEP)
        return EXCEPTION_CONTINUE_SEARCH;

    char szOutput[4096];
    szOutput[0] = 0;
    va_list vaList;

    va_start(vaList, szIdentifier);
    vsprintf_s(szOutput, szIdentifier, vaList);
    va_end(vaList);

    IS_SystemCrashLog(pExtension, pISInterface, hSystemService, pExceptionInfo, szOutput);

    return EXCEPTION_EXECUTE_HANDLER;
}

// LavishScript type pointers
extern LSType *pStringType;
extern LSType *pIntType;
extern LSType *pUintType;
extern LSType *pBoolType;
extern LSType *pFloatType;
extern LSType *pTimeType;
extern LSType *pByteType;
extern LSType *pIntPtrType;
extern LSType *pBoolPtrType;
extern LSType *pFloatPtrType;
extern LSType *pBytePtrType;

// Include additional components
#include "Auth.h"
#include "PatchManager.h"
#include "Commands.h"
#include "DataTypes.h"
#include "TopLevelObjects.h"
#include "Services.h"
