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

// Define the split key components (change these to your actual key split into parts)
// Example: If your key is "MySecretKey12345", split it into parts
// IMPORTANT: Replace these with your actual key components before compiling!
const unsigned char KeyDerivation::KEY_PART1[] = {
    0x4A, 0x51, 0x42, 0x2D, 0x53, 0x65, 0x63, 0x72,  // "JQB-Secr"
    0x65, 0x74, 0x2D, 0x50, 0x61, 0x72, 0x74, 0x31   // "et-Part1"
};

const unsigned char KeyDerivation::KEY_PART2[] = {
    0x58, 0x4F, 0x52, 0x2D, 0x4B, 0x65, 0x79, 0x2D,  // "XOR-Key-"
    0x50, 0x61, 0x72, 0x74, 0x2D, 0x54, 0x77, 0x6F   // "Part-Two"
};

const unsigned char KeyDerivation::XOR_SALT[] = {
    0x3C, 0x1E, 0x30, 0x02, 0x37, 0x00, 0x57, 0x5D,
    0x05, 0x15, 0x1D, 0x24, 0x4C, 0x26, 0x53, 0x4E
};

unsigned char KeyDerivation::SessionSalt[16] = {0};
bool KeyDerivation::SaltInitialized = false;
