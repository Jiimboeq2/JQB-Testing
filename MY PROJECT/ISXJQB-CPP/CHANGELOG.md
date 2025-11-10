# ISXJQB Changelog

## v1.0.0 - Initial Release

### Added
- Clean C++ extension framework based on streamlined ISXRI Template
- Derivative key encryption system for obfuscated key storage
- Memory patching macros (EzDetour, EzModify, etc.)
- PowerShell module build system
- Visual Studio 2022 project files (Win32 and x64 support)
- Automated Build.ps1 script
- Service connections: Memory, Pulse, HTTP, Triggers, System
- Module system with auto-generation from .dat files
- Sample JQBCore module

### Removed (from ISXRI Template)
- 57+ quest/timeline modules (bloat)
- Hardcoded absolute paths
- Unnecessary complexity

### Changed
- Renamed from ISXRI to ISXJQB
- Simplified project structure
- Cleaner build output paths (bin/ instead of scattered)
- Improved documentation

### Security
- Implemented derivative key system to avoid plaintext encryption keys
- Session-specific salt generation
- Multi-part key storage with XOR obfuscation
