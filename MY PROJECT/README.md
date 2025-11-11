# ISXJQB - InnerSpace Extension for EverQuest II

Clean, streamlined InnerSpace extension with authentication and modular patching.

## What is this?

An InnerSpace/LavishScript extension for EverQuest II. Includes:
- Encryption system (keys never stored in plaintext)
- License verification with backend database
- Patch manager (organized, reversible memory patches)
- Hook system for function detouring
- File integrity checking

## Quick Start

### You need:
- Windows 10/11
- Visual Studio 2022 (any edition - Community is free)
- InnerSpace installed
- EverQuest II

### Build it:

```powershell
cd "MY PROJECT/ISXJQB-CPP"
.\BuildAll.ps1
```

That's it. The script does everything:
1. Generates encryption keys
2. Updates module includes
3. Finds MSBuild
4. Builds the DLL

**You don't need to open Visual Studio.** The script uses MSBuild directly.

Output: `bin\x64\ISXJQB.dll`

### Install it:

Copy the DLL to your InnerSpace extensions folder:
```
bin\x64\ISXJQB.dll
  -> C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll
```

Create an auth file at:
```
C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml
```

With:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<isxjqb_auth>
    <email>your-email@example.com</email>
    <license>66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC</license>
</isxjqb_auth>
```

### Use it:

In EQ2 via InnerSpace console:
```
ext isxjqb
jqb ?
```

## Adding Your Patches

Edit `ISXJQB-CPP/ISXJQB.cpp` in the `RegisterExtension()` function:

```cpp
// Your original bytes at the target address
unsigned char originalBytes[] = { 0x74, 0x05 };  // JZ instruction

// What you want to replace them with
unsigned char patchBytes[] = { 0x90, 0x90 };     // NOP NOP

PatchManager::RegisterPatch(
    "NopJumpCheck",                  // Give it a name
    "Removes the jump check at X",   // What it does
    0x00401234,                      // Memory address
    originalBytes, sizeof(originalBytes),
    patchBytes, sizeof(patchBytes),
    "Safety"                         // Category
);

// Apply it
PatchManager::ApplyPatch("NopJumpCheck");
```

Then rebuild with `.\BuildAll.ps1`.

To apply patches in-game:
```
jqb patch apply NopJumpCheck
jqb patch remove NopJumpCheck
jqb patches
```

## Project Structure

```
ISXJQB-CPP/          C++ extension source
├── BuildAll.ps1     ONE SCRIPT TO RULE THEM ALL
├── ISXJQB.h/cpp     Main extension code
├── Auth.h           License verification
├── PatchManager.h   Patch system
├── KeyDerivation.h  Encryption
└── third-party/     ISXDK (InnerSpace SDK)

ISXJQB/             LavishScript helpers
└── jqb_helper.iss  Commands (jqb ?, jqb status, etc)

backend/            License server
├── api/            PHP verification API
└── database/       PostgreSQL schema
```

## Backend (Optional)

The extension includes a license verification system with PostgreSQL backend.

**Three permission tiers:**
- **god**: Unlimited everything
- **oracle**: Multi-character, premium features
- **acolyte**: Single character, basic features

See `backend/README.md` for setup. Currently auth is in dev mode (always passes).

## Visual Studio Version

You need **Visual Studio 2022** (any edition):
- Community (free): https://visualstudio.microsoft.com/downloads/
- Professional
- Enterprise
- Or just Build Tools for Visual Studio 2022

The build script finds MSBuild automatically. You don't need to open Visual Studio.

## Troubleshooting

**"MSBuild not found"**
Install Visual Studio 2022. The script looks in these locations:
- VS Community
- VS Professional
- VS Enterprise
- Build Tools

**Build fails with errors**
Make sure you have:
- C++ desktop development workload
- Windows 10/11 SDK
- MSVC v143 toolset

**Extension won't load in InnerSpace**
- Check InnerSpace console for errors
- Verify using x64 InnerSpace (not 32-bit)
- Make sure ISXDK version matches (35)

**Can't find InnerSpace folder**
Default: `C:\Program Files (x86)\InnerSpace\`
If installed elsewhere, adjust the path.

## Documentation

- `START_HERE.md` - First-time setup walkthrough
- `ISXJQB-CPP/INSTALLATION_GUIDE.md` - Detailed install steps
- `ISXJQB-CPP/QUICK_START.md` - Code examples
- `backend/README.md` - Backend setup
- `backend/SECURITY.md` - Security practices

## Development

After making changes, just run:
```powershell
.\BuildAll.ps1
```

It rebuilds everything.

To skip key generation (use existing keys):
```powershell
.\BuildAll.ps1 -SkipKeyGeneration
```

## License System

Uses XML file auth with optional backend verification.

**Local auth** (current mode):
- Reads `isxjqb_auth.xml`
- Always returns valid in dev mode

**Backend verification** (production):
- Uncomment HTTP request code in `Auth.h`
- Deploy `backend/api/verify_license.php`
- Set up PostgreSQL database
- Extension checks license against server

## Security

Encryption keys are randomized on first build. They're split and XOR'd at runtime so the plaintext key never exists in memory.

**Don't commit:**
- `NewKeyComponents.txt` (generated keys)
- `.env` files with database credentials
- Your auth XML files

## Contributing

This is a personal project but if you want to add features:
1. Make your changes
2. Test it
3. Commit with clear messages

## Support

Check the docs folder. If you're stuck:
- Read the error messages (seriously)
- Check InnerSpace console output
- Verify file paths
- Make sure game version matches your patches

## License

Do whatever you want with this code. No warranty. Don't sue me if something breaks.

---

Built for EverQuest II with InnerSpace/LavishScript.
