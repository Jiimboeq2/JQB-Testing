# ISXJQB Installation & Configuration Guide

## Quick Answer to Your Questions

### Where to generate encryption keys?
Run this in the ISXJQB-CPP folder:
```powershell
.\Generate-New-Key.ps1
```

This generates:
- `KEY_PART1` - First part of split key
- `KEY_PART2` - Second part of split key
- `XOR_SALT` - Static XOR salt

Then copy these into `KeyDerivation.h` replacing the existing values.

### Are we using obfuscation AND salting?
**YES** - Multi-layer security:

1. **Key Splitting**: Key split into 2 parts (KEY_PART1, KEY_PART2)
2. **Static XOR Salt**: XOR_SALT mixed in at compile time
3. **Runtime Session Salt**: Random 16-byte salt generated each session
4. **XOR Derivation**: Final key = `KEY_PART1 ⊕ KEY_PART2 ⊕ XOR_SALT ⊕ SessionSalt`

**Result**: Key never stored in plaintext anywhere!

## Complete Installation

### Step 1: Build Extension

```powershell
cd "MY PROJECT/ISXJQB-CPP"

# 1. Generate UNIQUE encryption keys (DO THIS FIRST!)
.\Generate-New-Key.ps1

# 2. Edit KeyDerivation.h with generated values
# (Replace KEY_PART1, KEY_PART2, XOR_SALT)

# 3. Build
.\Build.ps1
```

Output: `bin\x64\ISXJQB.dll`

### Step 2: Install DLL

Copy to InnerSpace Extensions:

**x64 (recommended)**:
```
Source: bin\x64\ISXJQB.dll
Dest: C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll
```

**Win32** (if needed):
```
Source: bin\Win32\ISXJQB.dll
Dest: C:\Program Files (x86)\InnerSpace\Extensions\ISXDK35\ISXJQB.dll
```

### Step 3: Create Auth File

**Location**: `C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<isxjqb_auth>
    <email>your-paypal-email@example.com</email>
    <license>66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC</license>
</isxjqb_auth>
```

Replace with YOUR credentials!

### Step 4: Load Extension

In EverQuest II (via InnerSpace):
```
ext isxjqb
```

Verify:
```
jqb status
```

## Helper System

Type `jqb ?` for help menu:

```
jqb ?              - Show all commands
jqb status         - Extension status
jqb auth           - Auth info
jqb patches        - List patches
jqb hooks          - List hooks
jqb patch apply <name>    - Apply patch
jqb hook install <name>   - Install hook
```

## Security Features

### Encryption (from Generate-New-Key.ps1)

**What it does**:
- Generates 3 random 16-byte arrays
- KEY_PART1 + KEY_PART2 = Split encryption key
- XOR_SALT = Static obfuscation layer
- Session salt added at runtime

**How it works**:
1. Keys compiled into binary (obfuscated)
2. Runtime generates random session salt
3. XORs all parts together for actual key
4. Key only exists in memory during operation
5. Different every session due to random salt

### File Hashing (FileHashing.h)

**SHA-256** for integrity:
```cpp
std::string hash = FileHasher::SHA256File("C:\\Games\\EQ2\\eq2.exe");
// Returns: "a1b2c3d4..." (64 hex characters)
```

**Verify files**:
```cpp
PatchManager::RegisterFileHash("C:\\Games\\EQ2\\eq2.exe", "expected_hash");
PatchManager::VerifyGameIntegrity(); // Checks all registered files
```

## Modular Patching System

### Clean, Organized Patches

```cpp
// Register patch
unsigned char orig[] = { 0x74, 0x05 };  // JZ instruction
unsigned char patch[] = { 0x90, 0x90 }; // NOP NOP

PatchManager::RegisterPatch(
    "DisableCheck",                // Name
    "Disables safety check",       // Description
    0x00401234,                    // Address
    orig, sizeof(orig),
    patch, sizeof(patch),
    "Safety"                       // Category
);

// Apply it
PatchManager::ApplyPatch("DisableCheck");

// Or apply all in category
PatchManager::ApplyPatchesByCategory("Safety");

// Or apply everything
PatchManager::ApplyAllPatches();

// Remove when done
PatchManager::RemovePatch("DisableCheck");
```

### Clean, Organized Hooks

```cpp
// Define your detour
typedef void (*OrigFunc)(int);
OrigFunc pOrig = nullptr;

void MyDetour(int param) {
    printf("\\ag[JQB] Hooked: %d", param);
    pOrig(param); // Call original
}

// Register hook
PatchManager::RegisterHook(
    "HookTarget",                  // Name
    "Hooks target function",       // Description
    0x00405678,                    // Address
    (void*)MyDetour,               // Detour
    (void*)&pOrig,                 // Trampoline
    "Hooks"                        // Category
);

// Install it
PatchManager::InstallHook("HookTarget");

// Or by category
PatchManager::InstallHooksByCategory("Hooks");

// Or all
PatchManager::InstallAllHooks();

// Remove when done
PatchManager::RemoveHook("HookTarget");
```

### Why This Is Better

**Old way** (messy):
```cpp
// Scattered throughout code
EzModify(0x123456, bytes, 5, false);
Ez Detour(0x789ABC, func, orig);
// No organization, hard to track
```

**New way** (clean):
```cpp
// All patches registered in one place
// Easy to enable/disable
// Categorized
// Named
// Described
// Reversible
```

## Backend Auth (TODO)

### What You Need to Implement

**Backend API Endpoint**: `https://your-domain.com/api/verify`

**Request**:
```json
POST /api/verify
{
    "email": "user@example.com",
    "license": "66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC"
}
```

**Response**:
```json
{
    "valid": true,
    "message": "License verified",
    "expires": "2025-12-31",
    "features": ["basic", "premium"]
}
```

**In Code** (Auth.h, VerifyLicense function):
```cpp
// TODO: Replace placeholder with actual HTTP request
// Use EzHttpRequest macro:
std::string url = "https://your-domain.com/api/verify";
std::string body = "{\"email\":\"" + PayPalEmail + "\",\"license\":\"" + LicenseKey + "\"}";

// Make request (implement response parsing)
// EzHttpRequest(url.c_str(), body.c_str());
```

### Current Behavior

**Development mode**: Always returns true
**Production**: Change `IsAuthenticated = true;` to `= false;` in Auth.h:282

## Troubleshooting

### Can't Find DLL Path

Check InnerSpace installation:
```
dir "C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\"
```

If doesn't exist:
```
mkdir "C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35"
```

### Extension Won't Load

1. Check architecture (x64 vs Win32)
2. Run InnerSpace as Administrator
3. Check InnerSpace console for errors
4. Verify ISXDK version matches (35)

### Patches Don't Work

1. Verify game file integrity:
   ```
   jqb integrity
   ```

2. Check addresses haven't changed (game update)

3. Enable debug:
   ```
   jqb debug on
   ```

## File Locations Reference

| File | Location |
|------|----------|
| Extension DLL | `C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll` |
| Auth File | `C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml` |
| Helper Script | `[InnerSpace Scripts]\jqb_helper.iss` |
| Source Code | `MY PROJECT/ISXJQB-CPP/` |
| LavishScript | `MY PROJECT/ISXJQB/` |

## Next Steps

1. ✅ Generate encryption keys
2. ✅ Build extension
3. ✅ Install DLL
4. ✅ Create auth file
5. ✅ Load in EQ2
6. ⏹️ Implement backend auth
7. ⏹️ Add your patches/hooks
8. ⏹️ Test in-game

---

**Version**: 1.0.0
**Extension**: ISXJQB for EverQuest II
**Load Command**: `ext isxjqb`
**Help Command**: `jqb ?`
