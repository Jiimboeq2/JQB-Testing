# Start Here - Build Your Extension

## The Simple Version

You just need to run one PowerShell script. That's it.

```powershell
cd "MY PROJECT/ISXJQB-CPP"
.\BuildAll.ps1
```

**Do you need to open Visual Studio?** Nope.

The script uses MSBuild directly (Visual Studio's compiler). You need Visual Studio **installed**, but you don't need to open it or click anything. The script handles everything.

## What You Need Installed

### Visual Studio 2022

Download **Visual Studio 2022 Community** (it's free):
https://visualstudio.microsoft.com/downloads/

When installing, select:
- "Desktop development with C++"

That's the only workload you need. It installs:
- MSVC compiler (v143 toolset)
- Windows SDK
- MSBuild

**Any edition works:**
- Community (free) - perfect
- Professional - if you have it
- Enterprise - if you're fancy
- Build Tools - minimal version, also works

### InnerSpace

You probably already have this since you're making an extension for it.

### EverQuest II

Same deal - you're making an extension for it.

## Build Steps (First Time)

1. **Open PowerShell**
   - Right-click Start menu
   - Click "Windows PowerShell" or "Terminal"

2. **Navigate to the project**
   ```powershell
   cd "C:\path\to\JQB-Testing\MY PROJECT\ISXJQB-CPP"
   ```

3. **Run the build script**
   ```powershell
   .\BuildAll.ps1
   ```

That's it. The script does:
- Checks if you have default encryption keys
- Generates new random keys if needed
- Updates module includes
- Finds MSBuild on your system
- Compiles the C++ code
- Outputs ISXJQB.dll

Takes about 30 seconds on first build.

## What The Script Does

```
[1/4] Checking encryption keys...
  Default keys detected - generating new keys...
  Keys generated and updated in KeyDerivation.h

[2/4] Updating modules...
  (processes any .dat files in include/ folder)

[3/4] Locating MSBuild...
  Found: C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe

[4/4] Building ISXJQB (x64 Release)...
  (compiler output)

========================================
     BUILD SUCCESSFUL!
========================================

Output DLL:
  Location: bin\x64\ISXJQB.dll
  Size: 45.2 KB
  Modified: 2025-11-11 3:45 PM

========================================
NEXT STEPS:
========================================
(tells you where to copy the DLL)
```

## After Building

### 1. Copy the DLL

From:
```
MY PROJECT\ISXJQB-CPP\bin\x64\ISXJQB.dll
```

To:
```
C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll
```

If that folder doesn't exist, create it.

### 2. Create Auth File

Location:
```
C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml
```

Contents:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<isxjqb_auth>
    <email>your-email@example.com</email>
    <license>66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC</license>
</isxjqb_auth>
```

Use your actual email and license key. Format for the key is:
```
XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
```

### 3. Load It

Open EverQuest II via InnerSpace, then in the console:
```
ext isxjqb
```

You should see:
```
ISXJQB v1.0.0 Loading...
[ISXJQB] Connected to Memory Service
[ISXJQB] Connected to Pulse Service
[ISXJQB] Loading authentication...
[ISXJQB Auth] Loaded credentials for: your-email@example.com
[ISXJQB] TODO: Backend verification not implemented yet
[ISXJQB] License verified successfully!
[ISXJQB] Loaded: 0 patches, 0 hooks registered
ISXJQB v1.0.0 Loaded Successfully!
```

### 4. Test It

```
jqb ?
```

Shows all available commands.

```
jqb status
```

Shows extension status.

## Adding Your Game Patches

Now that it builds, you probably want to add actual patches for EQ2.

Edit this file:
```
MY PROJECT\ISXJQB-CPP\ISXJQB.cpp
```

Find the `RegisterExtension()` function (around line 85).

Add your patches:
```cpp
void ISXJQB::RegisterExtension()
{
    ConnectServices();

    // Initialize systems
    JQBAuth::Initialize();
    PatchManager::Initialize();

    // YOUR PATCHES GO HERE

    // Example: Remove a jump instruction
    unsigned char origBytes[] = { 0x74, 0x05 };  // JZ +5
    unsigned char nopBytes[] = { 0x90, 0x90 };   // NOP NOP

    PatchManager::RegisterPatch(
        "RemoveCheck",
        "Removes safety check at 0x401234",
        0x00401234,                    // <- YOUR ADDRESS HERE
        origBytes, sizeof(origBytes),
        nopBytes, sizeof(nopBytes),
        "Safety"
    );

    // Apply it
    PatchManager::ApplyPatch("RemoveCheck");

    // END YOUR PATCHES

    // Load auth
    if (JQBAuth::LoadAuthFile())
        JQBAuth::VerifyLicense();
    else
        JQBAuth::CreateSampleAuthFile();

    // Register InnerSpace stuff
    RegisterCommands();
    RegisterAliases();
    RegisterDataTypes();
    RegisterTopLevelObjects();
    RegisterServices();
    RegisterTriggers();
}
```

Then rebuild:
```powershell
.\BuildAll.ps1
```

Copy the new DLL to InnerSpace, reload:
```
ext -unload isxjqb
ext isxjqb
```

## Rebuilding After Changes

Anytime you change code, just:
```powershell
.\BuildAll.ps1
```

If you want to skip key generation (use existing keys):
```powershell
.\BuildAll.ps1 -SkipKeyGeneration
```

## Troubleshooting

**"MSBuild not found"**

You don't have Visual Studio 2022 installed, or you didn't install the C++ workload.

Fix:
1. Open Visual Studio Installer
2. Click "Modify" on Visual Studio 2022
3. Select "Desktop development with C++"
4. Click "Modify" to install

**"Access denied" or file locked**

InnerSpace is using the DLL.

Fix:
1. Close InnerSpace completely
2. Run `.\BuildAll.ps1`
3. Copy new DLL
4. Restart InnerSpace

**Extension won't load**

Check InnerSpace console (the text output window). It will tell you what's wrong.

Common issues:
- Wrong folder (needs to be in ISXDK35 folder)
- Using 32-bit InnerSpace (extension is x64 only)
- Missing ISXDK version (needs ISXDK 35)

**Build fails with errors**

Read the error message. Usually it's:
- Missing semicolon
- Typo in variable name
- Wrong memory address format

Fix the error in the .cpp file and rebuild.

## Next Steps

Once you've got it building and loading:

1. **Find memory addresses** in EQ2
   - Use Cheat Engine or similar
   - Find what you want to patch/hook

2. **Add patches** in ISXJQB.cpp
   - Register them with PatchManager
   - Test one at a time

3. **Add hooks** for function detouring
   - Same process as patches
   - Use PatchManager::RegisterHook()

4. **Test everything** carefully
   - Make backups before testing
   - Test in safe environments first

## Documentation

More detailed info:
- `README.md` - Overview and features
- `ISXJQB-CPP/INSTALLATION_GUIDE.md` - Install details
- `ISXJQB-CPP/QUICK_START.md` - Code examples
- `backend/README.md` - Backend setup (optional)

## Summary

Run this:
```powershell
.\BuildAll.ps1
```

Copy DLL to InnerSpace.

Create auth XML file.

Load with `ext isxjqb`.

That's it. You're done.
