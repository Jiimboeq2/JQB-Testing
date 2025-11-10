# ISXJQB - JQuestBot C++ Extension

A streamlined InnerSpace extension for JQuestBot with memory patching capabilities and derivative key encryption.

## Features

- **Memory Patching Macros**: Easy-to-use `EzDetour`, `EzModify`, and related macros for function hooking and memory modification
- **Derivative Key Encryption**: Obfuscated key storage system to avoid plaintext encryption keys in memory
- **Module System**: Automated PowerShell build system for managing extension modules
- **Service Integration**: Built-in connections to InnerSpace services (Memory, Pulse, HTTP, Triggers, System)

## Project Structure

```
ISXJQB-CPP/
├── ISXJQB.h/cpp          # Main extension implementation
├── KeyDerivation.h       # Derivative key encryption system
├── Commands.h/cpp        # LavishScript command definitions
├── DataTypes.h/cpp       # Custom data type definitions
├── TopLevelObjects.h/cpp # Top-level object (TLO) definitions
├── Services.h/cpp        # Custom service implementations
├── include/              # Module directories (auto-processed)
├── ModuleScripts/        # PowerShell build automation
├── third-party/          # ISXDK headers and libraries
└── bin/                  # Build output (generated)
```

## Getting Started

### Prerequisites

- Visual Studio 2022 (v143 toolset)
- Windows SDK 10.0
- PowerShell 5.1 or later
- InnerSpace with ISXDK 35

### Building

1. **Update Include Paths** (first time or when adding new modules):
   ```powershell
   .\ModuleScripts\Update-Modules.ps1
   ```

2. **Build in Visual Studio**:
   - Open `ISXJQB.sln`
   - Select `Release` configuration
   - Choose `Win32` or `x64` platform
   - Build Solution (Ctrl+Shift+B)

3. **Output**:
   - DLL will be in `bin\Win32\` or `bin\x64\`
   - Copy to your InnerSpace Extensions folder

### Encryption Key Setup

**IMPORTANT**: Before compiling, update the encryption key in `KeyDerivation.h`:

```cpp
// Replace these with your actual key components
const unsigned char KeyDerivation::KEY_PART1[] = {
    0x4A, 0x51, 0x42, 0x2D, // Your key part 1 (8-16 bytes)
    // ... more bytes
};

const unsigned char KeyDerivation::KEY_PART2[] = {
    0x58, 0x4F, 0x52, 0x2D, // Your key part 2 (8-16 bytes)
    // ... more bytes
};

const unsigned char KeyDerivation::XOR_SALT[] = {
    0x3C, 0x1E, 0x30, 0x02, // Static XOR salt (16 bytes)
    // ... more bytes
};
```

The key is split into parts and XORed with salts to avoid storing it in plaintext. The actual key is reconstructed at runtime with an additional session-specific salt for extra obfuscation.

## Creating Modules

Modules are organized in the `include/` directory with this structure:

```
include/
└── MyModule/
    ├── _metadata.json
    ├── Feature1.dat
    └── Feature2.dat
```

### Module Metadata (_metadata.json)

```json
{
    "Category": "My Module Category",
    "Type": "Module Type"
}
```

### Data Files (.dat)

`.dat` files are automatically converted to C++ header files with string arrays. Example:

```
My Feature Name
Command line 1
Command line 2
...
```

Becomes:

```cpp
string MyFeatureName[] = {
    "My Feature Name",
    "Command line 1",
    "Command line 2"
};
```

### Running Module Generator

```powershell
# Process all modules
.\ModuleScripts\Update-Modules.ps1

# Process specific module
.\ModuleScripts\Update-Modules.ps1 -moduleName "MyModule"
```

## Memory Patching Examples

### Function Hooking (Detour)

```cpp
// Original function pointer
typedef int (*OriginalFunction)(int param);
OriginalFunction OriginalFunc = nullptr;

// Detour function
int MyDetour(int param)
{
    printf("Function called with param: %d", param);
    return OriginalFunc(param); // Call original
}

// Install detour
void InstallHook()
{
    unsigned int targetAddress = 0x12345678;
    EzDetour(targetAddress, MyDetour, OriginalFunc);
}

// Remove detour
void RemoveHook()
{
    unsigned int targetAddress = 0x12345678;
    EzUnDetour(targetAddress);
}
```

### Memory Modification

```cpp
// Patch memory with new bytes
unsigned char newBytes[] = { 0x90, 0x90, 0x90 }; // NOP instructions
unsigned int address = 0x12345678;
EzModify(address, newBytes, sizeof(newBytes), false);

// Restore original bytes
EzUnModify(address);
```

## Available Macros

| Macro | Description |
|-------|-------------|
| `EzDetour` | Hook a function at a specific address |
| `EzUnDetour` | Remove a function hook |
| `EzDetourAPI` | Hook a Windows API function by name |
| `EzUnDetourAPI` | Remove an API hook |
| `EzModify` | Modify memory at an address |
| `EzUnModify` | Restore original memory |
| `EzHttpRequest` | Make HTTP requests |
| `EzAddTrigger` | Add a text trigger |
| `EzRemoveTrigger` | Remove a trigger |
| `EzCrashFilter` | Exception handler with logging |

## Service Handles

The following service handles are available globally:

- `hMemoryService` - Memory manipulation
- `hPulseService` - Periodic callbacks
- `hHTTPService` - HTTP requests
- `hTriggerService` - Text triggers
- `hSystemService` - System utilities

## LavishScript Type Pointers

Pre-initialized type pointers:

- `pStringType`, `pIntType`, `pUintType`, `pBoolType`
- `pFloatType`, `pTimeType`, `pByteType`
- `pIntPtrType`, `pBoolPtrType`, `pFloatPtrType`, `pBytePtrType`

## Notes

- This is a **significantly streamlined** C++ extension framework
- No 57+ quest/timeline modules - start clean and add only what you need
- Derivative key system provides obfuscation (not true security)
- The module system auto-generates C++ headers from .dat files
- PowerShell scripts handle all the tedious header file generation

## License

Private project - not for distribution.
