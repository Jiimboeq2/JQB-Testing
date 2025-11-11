#pragma once
#include <string>
#include <random>

// Derivative key system to avoid storing plaintext encryption key in memory
// InnerSpace requires the key, but we obfuscate it using XOR with a runtime-generated salt

class KeyDerivation
{
private:
    // Store key components separately in memory
    static const unsigned char KEY_PART1[];
    static const unsigned char KEY_PART2[];
    static const unsigned char XOR_SALT[];
    static const int KEY_LENGTH = 16;

    // Runtime-generated obfuscation value (changes each session)
    static unsigned char SessionSalt[16];
    static bool SaltInitialized;

public:
    // Initialize session salt (call once at startup)
    static void InitializeSessionSalt()
    {
        if (SaltInitialized) return;

        // Generate random session salt
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<> dis(0, 255);

        for (int i = 0; i < 16; i++)
        {
            SessionSalt[i] = static_cast<unsigned char>(dis(gen));
        }

        SaltInitialized = true;
    }

    // Derive the actual encryption key at runtime
    static void DeriveKey(char* outputKey)
    {
        if (!SaltInitialized)
            InitializeSessionSalt();

        // Combine key parts with XOR operations to reconstruct the actual key
        for (int i = 0; i < KEY_LENGTH; i++)
        {
            // XOR the key parts with static salt and session salt
            outputKey[i] = KEY_PART1[i] ^ KEY_PART2[i] ^ XOR_SALT[i] ^ SessionSalt[i % 16];
        }
    }

    // Get the encryption key (format expected by InnerSpace)
    static const char* GetEncryptionKey()
    {
        static char derivedKey[17] = {0}; // 16 chars + null terminator

        if (derivedKey[0] == 0) // First time
        {
            DeriveKey(derivedKey);
        }

        return derivedKey;
    }

    // Encode a string using the derived key
    static std::string EncodeString(const std::string& input)
    {
        const char* key = GetEncryptionKey();
        std::string output = input;

        for (size_t i = 0; i < input.length(); i++)
        {
            output[i] = input[i] ^ key[i % KEY_LENGTH];
        }

        return output;
    }
};
