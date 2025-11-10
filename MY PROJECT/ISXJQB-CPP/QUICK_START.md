# ISXJQB Quick Start Guide

## Setup (First Time)

### 1. Generate Your Encryption Key

```powershell
.\Generate-New-Key.ps1
```

This creates unique key components. Copy the output into `KeyDerivation.h` to replace the default keys.

**IMPORTANT**: Keep your keys secret! Don't commit `NewKeyComponents.txt` to git.

### 2. Build the Extension

```powershell
.\Build.ps1
```

This will:
- Process all modules in `include/`
- Generate include paths
- Compile the extension
- Output `ISXJQB.dll` to `bin\x64\` or `bin\Win32\`

### 3. Install the Extension

Copy `bin\x64\ISXJQB.dll` to:
```
C:\InnerSpace\Extensions\
```

Or wherever your InnerSpace Extensions folder is located.

### 4. Load in InnerSpace

In InnerSpace console:
```
extension isxjqb
```

You should see:
```
ISXJQB v1.0.0 Loading...
[ISXJQB] Connected to Memory Service
[ISXJQB] Connected to Pulse Service
...
ISXJQB v1.0.0 Loaded Successfully!
```

## Adding Your First Module

### 1. Create Module Directory

```powershell
mkdir include\MyModule
```

### 2. Create Metadata File

`include\MyModule\_metadata.json`:
```json
{
    "Category": "My Custom Module",
    "Type": "Utility"
}
```

### 3. Add Data Files

`include\MyModule\MyFeature.dat`:
```
My Feature Name
line 1
line 2
line 3
```

### 4. Rebuild

```powershell
.\Build.ps1
```

The module system will:
- Convert `MyFeature.dat` → `MyFeature.h`
- Create `_InitializeModule.h`
- Update include paths
- Compile everything

## Adding Memory Patches

Edit `ISXJQB.cpp` in the `RegisterExtension()` or create module-specific files:

```cpp
// Example: NOP out a function call
void PatchExample()
{
    unsigned char nops[] = { 0x90, 0x90, 0x90, 0x90, 0x90 };
    unsigned int address = 0x12345678; // Your target address

    EzModify(address, nops, sizeof(nops), false);
    printf("\\ag[ISXJQB] Patch applied at 0x%X", address);
}

// Example: Hook a function
typedef void (*OriginalFunc)(int param);
OriginalFunc pOriginalFunc = nullptr;

void MyDetour(int param)
{
    printf("\\ag[ISXJQB] Function called with: %d", param);
    pOriginalFunc(param); // Call original
}

void InstallHook()
{
    unsigned int address = 0x87654321;
    EzDetour(address, MyDetour, pOriginalFunc);
    printf("\\ag[ISXJQB] Hook installed at 0x%X", address);
}
```

Then call from `RegisterExtension()`:
```cpp
void ISXJQB::RegisterExtension()
{
    ConnectServices();

    // Your custom patches
    PatchExample();
    InstallHook();

    RegisterCommands();
    RegisterDataTypes();
    RegisterTopLevelObjects();
    RegisterServices();
    RegisterTriggers();
}
```

## Common Build Options

```powershell
# Build x64 Release (default)
.\Build.ps1

# Build Win32 Release
.\Build.ps1 -Platform Win32

# Only update modules (no build)
.\Build.ps1 -UpdateModulesOnly

# Build without updating modules
.\Build.ps1 -SkipModuleUpdate

# Build Debug version
.\Build.ps1 -Configuration Debug
```

## Project Structure Reference

```
ISXJQB-CPP/
├── ISXJQB.h/cpp          ← Main extension code
├── KeyDerivation.h       ← Encryption key (CUSTOMIZE THIS!)
├── Commands.h/cpp        ← Add custom commands here
├── DataTypes.h/cpp       ← Add custom data types
├── TopLevelObjects.h/cpp ← Add TLOs here
├── include/              ← Your modules go here
│   └── MyModule/
│       ├── _metadata.json
│       └── Feature.dat
├── ModuleScripts/        ← Build automation (don't touch)
├── third-party/          ← ISXDK (don't touch)
└── bin/                  ← Build output
```

## Troubleshooting

### "MSBuild not found"
- Install Visual Studio 2022 Community (free)
- Or install Build Tools for Visual Studio 2022

### "Cannot find ISXDK"
- Check `third-party/ISXDK/35/` exists
- Should have `include/` and `lib/` or `lib64/` folders

### Extension doesn't load in InnerSpace
- Check InnerSpace version matches ISXDK version
- Make sure you're using the correct architecture (32-bit vs 64-bit)
- Check InnerSpace console for error messages

### "Access denied" when building
- Close InnerSpace (DLL may be locked)
- Run Visual Studio as Administrator

## Next Steps

1. Read `README.md` for detailed documentation
2. Explore the example module in `include/JQBCore/`
3. Review memory patching examples above
4. Create your own custom modules as needed
5. Add your own modules and patches!

## Getting Help

- Review existing code in `ISXJQB.cpp`
- Check PowerShell scripts in `ModuleScripts/`
- Review the included example modules
- InnerSpace forums: https://www.lavishsoft.com/

## Remember

- **Keep your encryption keys secret!**
- **Test in a safe environment first**
- **Back up your work regularly**
- **Don't commit sensitive data to git**

Happy coding! 🚀
