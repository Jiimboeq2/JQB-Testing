#pragma once
#include <vector>
#include <string>
#include <map>
#include <windows.h>
#include <ISXDK.h>
#include "FileHashing.h"

// Forward declarations - avoid circular include with ISXJQB.h
// These are defined in ISXJQB.h but we need them declared here
class ISXJQB;
extern ISInterface *pISInterface;
extern HISXSERVICE hMemoryService;
extern ISXJQB *pExtension;

// Printf macro (also defined in ISXJQB.h, but safe to duplicate)
#ifndef printf
#define printf pISInterface->Printf
#endif

// Note: Macros like EzDetour, EzModify, etc. are defined in ISXJQB.h
// This header is included by ISXJQB.h, so those macros are available when used from ISXJQB.cpp

// Modular patching system for ISXJQB
// Keeps patches organized, reversible, and verifiable

struct Patch
{
    std::string Name;
    std::string Description;
    unsigned int Address;
    std::vector<unsigned char> OriginalBytes;
    std::vector<unsigned char> PatchedBytes;
    bool IsApplied;
    std::string Category;

    Patch(const std::string& name, const std::string& desc, unsigned int addr,
          const std::vector<unsigned char>& original, const std::vector<unsigned char>& patched,
          const std::string& category = "General")
        : Name(name), Description(desc), Address(addr), OriginalBytes(original),
          PatchedBytes(patched), IsApplied(false), Category(category) {}
};

struct Hook
{
    std::string Name;
    std::string Description;
    unsigned int Address;
    void* DetourFunction;
    void* TrampolineFunction;
    bool IsInstalled;
    std::string Category;

    Hook(const std::string& name, const std::string& desc, unsigned int addr,
         void* detour, void* trampoline, const std::string& category = "General")
        : Name(name), Description(desc), Address(addr), DetourFunction(detour),
          TrampolineFunction(trampoline), IsInstalled(false), Category(category) {}
};

class PatchManager
{
private:
    static std::vector<Patch> Patches;
    static std::vector<Hook> Hooks;
    static std::map<std::string, std::string> ExpectedFileHashes;
    static bool IntegrityVerified;

public:
    // Initialize patch manager
    static void Initialize()
    {
        Patches.clear();
        Hooks.clear();
        ExpectedFileHashes.clear();
        IntegrityVerified = false;

        printf("\\ag[ISXJQB PatchManager] Initialized");
    }

    // Register expected file hash for integrity check
    static void RegisterFileHash(const std::string& filename, const std::string& expectedHash)
    {
        ExpectedFileHashes[filename] = expectedHash;
    }

    // Verify game files haven't been tampered with
    static bool VerifyGameIntegrity()
    {
        printf("\\ay[ISXJQB PatchManager] Verifying game file integrity...");

        bool allValid = true;

        for (auto& entry : ExpectedFileHashes)
        {
            std::string filePath = entry.first;
            std::string expectedHash = entry.second;

            if (!FileHasher::VerifyFileHash(filePath, expectedHash, true))
            {
                printf("\\ar[ISXJQB PatchManager] File hash mismatch: %s", filePath.c_str());
                allValid = false;
            }
            else
            {
                printf("\\ag[ISXJQB PatchManager] File verified: %s", filePath.c_str());
            }
        }

        IntegrityVerified = allValid;

        if (allValid)
        {
            printf("\\ag[ISXJQB PatchManager] All files verified successfully");
        }
        else
        {
            printf("\\ar[ISXJQB PatchManager] File verification failed - game may have been updated");
        }

        return allValid;
    }

    // Register a patch
    static void RegisterPatch(const std::string& name, const std::string& description,
                            unsigned int address, const unsigned char* original, size_t originalSize,
                            const unsigned char* patched, size_t patchedSize,
                            const std::string& category = "General")
    {
        std::vector<unsigned char> origBytes(original, original + originalSize);
        std::vector<unsigned char> patchBytes(patched, patched + patchedSize);

        Patches.emplace_back(name, description, address, origBytes, patchBytes, category);

        printf("\\ao[ISXJQB PatchManager] Registered patch: %s (%s)", name.c_str(), category.c_str());
    }

    // Register a hook
    static void RegisterHook(const std::string& name, const std::string& description,
                           unsigned int address, void* detourFunc, void* trampolineFunc,
                           const std::string& category = "General")
    {
        Hooks.emplace_back(name, description, address, detourFunc, trampolineFunc, category);

        printf("\\ao[ISXJQB PatchManager] Registered hook: %s (%s)", name.c_str(), category.c_str());
    }

    // Apply a specific patch by name
    static bool ApplyPatch(const std::string& name)
    {
        for (auto& patch : Patches)
        {
            if (patch.Name == name)
            {
                if (patch.IsApplied)
                {
                    printf("\\ao[ISXJQB PatchManager] Patch already applied: %s", name.c_str());
                    return true;
                }

                bool success = EzModify(patch.Address, patch.PatchedBytes.data(),
                                       patch.PatchedBytes.size(), false);

                if (success)
                {
                    patch.IsApplied = true;
                    printf("\\ag[ISXJQB PatchManager] Applied patch: %s", name.c_str());
                    return true;
                }
                else
                {
                    printf("\\ar[ISXJQB PatchManager] Failed to apply patch: %s", name.c_str());
                    return false;
                }
            }
        }

        printf("\\ar[ISXJQB PatchManager] Patch not found: %s", name.c_str());
        return false;
    }

    // Remove a specific patch by name
    static bool RemovePatch(const std::string& name)
    {
        for (auto& patch : Patches)
        {
            if (patch.Name == name)
            {
                if (!patch.IsApplied)
                {
                    printf("\\ao[ISXJQB PatchManager] Patch not applied: %s", name.c_str());
                    return true;
                }

                bool success = EzUnModify(patch.Address);

                if (success)
                {
                    patch.IsApplied = false;
                    printf("\\ag[ISXJQB PatchManager] Removed patch: %s", name.c_str());
                    return true;
                }
                else
                {
                    printf("\\ar[ISXJQB PatchManager] Failed to remove patch: %s", name.c_str());
                    return false;
                }
            }
        }

        printf("\\ar[ISXJQB PatchManager] Patch not found: %s", name.c_str());
        return false;
    }

    // Install a specific hook by name
    static bool InstallHook(const std::string& name)
    {
        for (auto& hook : Hooks)
        {
            if (hook.Name == name)
            {
                if (hook.IsInstalled)
                {
                    printf("\\ao[ISXJQB PatchManager] Hook already installed: %s", name.c_str());
                    return true;
                }

                bool success = EzDetour(hook.Address, hook.DetourFunction, hook.TrampolineFunction);

                if (success)
                {
                    hook.IsInstalled = true;
                    printf("\\ag[ISXJQB PatchManager] Installed hook: %s", name.c_str());
                    return true;
                }
                else
                {
                    printf("\\ar[ISXJQB PatchManager] Failed to install hook: %s", name.c_str());
                    return false;
                }
            }
        }

        printf("\\ar[ISXJQB PatchManager] Hook not found: %s", name.c_str());
        return false;
    }

    // Remove a specific hook by name
    static bool RemoveHook(const std::string& name)
    {
        for (auto& hook : Hooks)
        {
            if (hook.Name == name)
            {
                if (!hook.IsInstalled)
                {
                    printf("\\ao[ISXJQB PatchManager] Hook not installed: %s", name.c_str());
                    return true;
                }

                bool success = EzUnDetour(hook.Address);

                if (success)
                {
                    hook.IsInstalled = false;
                    printf("\\ag[ISXJQB PatchManager] Removed hook: %s", name.c_str());
                    return true;
                }
                else
                {
                    printf("\\ar[ISXJQB PatchManager] Failed to remove hook: %s", name.c_str());
                    return false;
                }
            }
        }

        printf("\\ar[ISXJQB PatchManager] Hook not found: %s", name.c_str());
        return false;
    }

    // Apply all patches in a category
    static void ApplyPatchesByCategory(const std::string& category)
    {
        printf("\\ay[ISXJQB PatchManager] Applying patches in category: %s", category.c_str());

        for (auto& patch : Patches)
        {
            if (patch.Category == category && !patch.IsApplied)
            {
                ApplyPatch(patch.Name);
            }
        }
    }

    // Install all hooks in a category
    static void InstallHooksByCategory(const std::string& category)
    {
        printf("\\ay[ISXJQB PatchManager] Installing hooks in category: %s", category.c_str());

        for (auto& hook : Hooks)
        {
            if (hook.Category == category && !hook.IsInstalled)
            {
                InstallHook(hook.Name);
            }
        }
    }

    // Apply all registered patches
    static void ApplyAllPatches()
    {
        printf("\\ay[ISXJQB PatchManager] Applying all patches...");

        for (auto& patch : Patches)
        {
            if (!patch.IsApplied)
            {
                ApplyPatch(patch.Name);
            }
        }
    }

    // Install all registered hooks
    static void InstallAllHooks()
    {
        printf("\\ay[ISXJQB PatchManager] Installing all hooks...");

        for (auto& hook : Hooks)
        {
            if (!hook.IsInstalled)
            {
                InstallHook(hook.Name);
            }
        }
    }

    // Remove all patches
    static void RemoveAllPatches()
    {
        printf("\\ay[ISXJQB PatchManager] Removing all patches...");

        for (auto& patch : Patches)
        {
            if (patch.IsApplied)
            {
                RemovePatch(patch.Name);
            }
        }
    }

    // Remove all hooks
    static void RemoveAllHooks()
    {
        printf("\\ay[ISXJQB PatchManager] Removing all hooks...");

        for (auto& hook : Hooks)
        {
            if (hook.IsInstalled)
            {
                RemoveHook(hook.Name);
            }
        }
    }

    // List all patches
    static void ListPatches()
    {
        printf("\\ay[ISXJQB PatchManager] Registered patches:");

        for (const auto& patch : Patches)
        {
            const char* status = patch.IsApplied ? "\\ag[ACTIVE]" : "\\ar[INACTIVE]";
            printf("%s %s - %s (0x%X)", status, patch.Name.c_str(),
                   patch.Description.c_str(), patch.Address);
        }
    }

    // List all hooks
    static void ListHooks()
    {
        printf("\\ay[ISXJQB PatchManager] Registered hooks:");

        for (const auto& hook : Hooks)
        {
            const char* status = hook.IsInstalled ? "\\ag[INSTALLED]" : "\\ar[NOT INSTALLED]";
            printf("%s %s - %s (0x%X)", status, hook.Name.c_str(),
                   hook.Description.c_str(), hook.Address);
        }
    }

    // Get patch count
    static int GetPatchCount() { return (int)Patches.size(); }

    // Get hook count
    static int GetHookCount() { return (int)Hooks.size(); }

    // Get applied patch count
    static int GetAppliedPatchCount()
    {
        int count = 0;
        for (const auto& patch : Patches)
            if (patch.IsApplied) count++;
        return count;
    }

    // Get installed hook count
    static int GetInstalledHookCount()
    {
        int count = 0;
        for (const auto& hook : Hooks)
            if (hook.IsInstalled) count++;
        return count;
    }
};

// Static member initialization
std::vector<Patch> PatchManager::Patches;
std::vector<Hook> PatchManager::Hooks;
std::map<std::string, std::string> PatchManager::ExpectedFileHashes;
bool PatchManager::IntegrityVerified = false;
