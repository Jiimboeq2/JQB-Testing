# ISXJQB - Ready to Build

Everything is set up and ready to compile.

## Quick Start - Just Run This

```powershell
cd "MY PROJECT/ISXJQB-CPP"
.\BuildAll.ps1
```

That's it. One script does everything:
- Generates new encryption keys (if needed)
- Updates modules
- Builds the DLL
- Shows you what to do next

## What You Have

### C++ Extension (ISXJQB-CPP/)
- Complete InnerSpace extension framework
- Derivative key encryption system (multi-layer security)
- XML-based authentication system
- Modular patch management (organized, reversible)
- Hook management system
- File integrity verification (SHA-256/MD5)
- LavishScript helper commands (`jqb ?`)
- ISXDK 35 (all headers and x64 libraries)

### Backend API (backend/)
- PostgreSQL database schema
- Three-tier permission system:
  - **god**: Unlimited characters, all features, API access
  - **oracle**: Multi-character (up to limit), premium features
  - **acolyte**: Single character, basic features
- PHP verification API with audit logging
- License management (create, extend, deactivate)
- Security documentation

### Database Setup
Your Neon PostgreSQL database:
```
Host: ep-sweet-king-ah50tgzg.c-3.us-east-1.aws.neon.tech
Database: neondb
Region: us-east-1
SSL: Required
```

## What to Do After Building

1. **Install the DLL**:
   ```
   Copy: MY PROJECT\ISXJQB-CPP\bin\x64\ISXJQB.dll
   To: C:\Program Files (x86)\InnerSpace\x64\Extensions\ISXDK35\ISXJQB.dll
   ```

2. **Create auth file**:
   ```
   Location: C:\Program Files (x86)\InnerSpace\x64\Extensions\isxjqb_auth.xml

   Content:
   <?xml version="1.0" encoding="UTF-8"?>
   <isxjqb_auth>
       <email>your-email@example.com</email>
       <license>66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC</license>
   </isxjqb_auth>
   ```

3. **Load in game** (EverQuest II via InnerSpace):
   ```
   ext isxjqb
   ```

4. **Test it**:
   ```
   jqb ?
   jqb status
   ```

## Adding Your Game Patches

Edit `ISXJQB-CPP/ISXJQB.cpp` in the `RegisterExtension()` function:

```cpp
// Register your patches
unsigned char origBytes[] = { 0x74, 0x05 };  // Original bytes
unsigned char patchBytes[] = { 0x90, 0x90 }; // Your patch

PatchManager::RegisterPatch(
    "MyPatch",                        // Name
    "Description of what this does",  // Description
    0x00401234,                       // Address in memory
    origBytes, sizeof(origBytes),
    patchBytes, sizeof(patchBytes),
    "Category"                        // Category (for grouping)
);

// Apply it
PatchManager::ApplyPatch("MyPatch");
```

Then rebuild:
```powershell
.\BuildAll.ps1
```

## Backend Setup (Optional - for production)

1. **Initialize database**:
   ```bash
   psql "postgresql://neondb_owner:npg_Xedr6xVanI5h@ep-sweet-king-ah50tgzg.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require" < backend/database/schema.sql
   ```

2. **Deploy API**:
   - Upload `backend/api/verify_license.php` to your web server
   - Set environment variable: `DATABASE_URL=<your connection string>`
   - Use HTTPS only

3. **Integrate with C++**:
   - Update `Auth.h` line 108 with actual HTTP requests
   - Currently auth is in dev mode (always returns true)

## File Structure

```
MY PROJECT/
├── ISXJQB-CPP/              C++ extension source
│   ├── BuildAll.ps1         ONE SCRIPT TO RUN
│   ├── ISXJQB.h/cpp         Main extension
│   ├── Auth.h               Authentication
│   ├── PatchManager.h       Patch system
│   ├── KeyDerivation.h      Encryption
│   └── third-party/ISXDK/   InnerSpace SDK
│
├── ISXJQB/                  LavishScript files
│   └── jqb_helper.iss       Helper commands
│
└── backend/                 License verification
    ├── api/                 PHP API
    ├── database/            PostgreSQL schema
    └── README.md            Backend docs
```

## Key Features

**Security**:
- Multi-layer key derivation (no plaintext keys)
- XML auth with backend verification
- Tier-based permissions
- File integrity checking
- Audit logging

**Patch Management**:
- Named patches with descriptions
- Categories for organization
- Apply/remove individual or all
- Reversible (restore original bytes)
- Status tracking

**Development**:
- Single build script
- Auto-generates encryption keys
- Module system for organization
- Clean, documented code
- x64 only (simplified)

## Troubleshooting

**Build fails**:
- Install Visual Studio 2022 Community (free)
- Or install Build Tools for Visual Studio 2022

**Can't find InnerSpace folder**:
- Adjust paths in the output instructions
- InnerSpace must be installed first

**Extension won't load**:
- Check InnerSpace console for errors
- Verify ISXDK version matches (35)
- Make sure using x64 InnerSpace

## Need Help?

Check these files:
- `ISXJQB-CPP/README.md` - Detailed C++ docs
- `ISXJQB-CPP/INSTALLATION_GUIDE.md` - Installation details
- `backend/README.md` - Backend API docs
- `backend/SECURITY.md` - Security best practices

## That's It

Run `BuildAll.ps1` and you're ready to go.
