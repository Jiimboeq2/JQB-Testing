#pragma once
#include <windows.h>
#include <wincrypt.h>
#include <string>
#include <fstream>
#include <sstream>
#include <iomanip>

#pragma comment(lib, "advapi32.lib")

// File hashing utilities for integrity verification
class FileHasher
{
public:
    // Calculate SHA-256 hash of a file
    static std::string SHA256File(const std::string& filePath)
    {
        HCRYPTPROV hProv = 0;
        HCRYPTHASH hHash = 0;
        BYTE hash[32]; // SHA-256 produces 32 bytes
        DWORD hashLen = 32;
        BYTE buffer[4096];
        DWORD bytesRead = 0;

        std::ifstream file(filePath, std::ios::binary);
        if (!file.is_open())
        {
            return "";
        }

        // Acquire crypto context
        if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT))
        {
            file.close();
            return "";
        }

        // Create hash object
        if (!CryptCreateHash(hProv, CALG_SHA_256, 0, 0, &hHash))
        {
            CryptReleaseContext(hProv, 0);
            file.close();
            return "";
        }

        // Hash file contents
        while (file.read((char*)buffer, sizeof(buffer)) || file.gcount() > 0)
        {
            bytesRead = (DWORD)file.gcount();
            if (!CryptHashData(hHash, buffer, bytesRead, 0))
            {
                CryptDestroyHash(hHash);
                CryptReleaseContext(hProv, 0);
                file.close();
                return "";
            }
        }

        file.close();

        // Get hash value
        if (!CryptGetHashParam(hHash, HP_HASHVAL, hash, &hashLen, 0))
        {
            CryptDestroyHash(hHash);
            CryptReleaseContext(hProv, 0);
            return "";
        }

        // Convert to hex string
        std::stringstream ss;
        for (DWORD i = 0; i < hashLen; i++)
        {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }

        CryptDestroyHash(hHash);
        CryptReleaseContext(hProv, 0);

        return ss.str();
    }

    // Calculate MD5 hash of a file (faster but less secure)
    static std::string MD5File(const std::string& filePath)
    {
        HCRYPTPROV hProv = 0;
        HCRYPTHASH hHash = 0;
        BYTE hash[16]; // MD5 produces 16 bytes
        DWORD hashLen = 16;
        BYTE buffer[4096];
        DWORD bytesRead = 0;

        std::ifstream file(filePath, std::ios::binary);
        if (!file.is_open())
        {
            return "";
        }

        if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
        {
            file.close();
            return "";
        }

        if (!CryptCreateHash(hProv, CALG_MD5, 0, 0, &hHash))
        {
            CryptReleaseContext(hProv, 0);
            file.close();
            return "";
        }

        while (file.read((char*)buffer, sizeof(buffer)) || file.gcount() > 0)
        {
            bytesRead = (DWORD)file.gcount();
            if (!CryptHashData(hHash, buffer, bytesRead, 0))
            {
                CryptDestroyHash(hHash);
                CryptReleaseContext(hProv, 0);
                file.close();
                return "";
            }
        }

        file.close();

        if (!CryptGetHashParam(hHash, HP_HASHVAL, hash, &hashLen, 0))
        {
            CryptDestroyHash(hHash);
            CryptReleaseContext(hProv, 0);
            return "";
        }

        std::stringstream ss;
        for (DWORD i = 0; i < hashLen; i++)
        {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }

        CryptDestroyHash(hHash);
        CryptReleaseContext(hProv, 0);

        return ss.str();
    }

    // Verify file matches expected hash
    static bool VerifyFileHash(const std::string& filePath, const std::string& expectedHash, bool useSHA256 = true)
    {
        std::string actualHash;

        if (useSHA256)
            actualHash = SHA256File(filePath);
        else
            actualHash = MD5File(filePath);

        if (actualHash.empty())
            return false;

        // Case-insensitive comparison
        std::string expected = expectedHash;
        std::transform(actualHash.begin(), actualHash.end(), actualHash.begin(), ::tolower);
        std::transform(expected.begin(), expected.end(), expected.begin(), ::tolower);

        return actualHash == expected;
    }

    // Calculate hash of memory region
    static std::string HashMemory(const void* data, size_t length, bool useSHA256 = true)
    {
        HCRYPTPROV hProv = 0;
        HCRYPTHASH hHash = 0;
        BYTE hash[32]; // Max size (SHA-256)
        DWORD hashLen = useSHA256 ? 32 : 16;

        if (!CryptAcquireContext(&hProv, NULL, NULL, useSHA256 ? PROV_RSA_AES : PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
        {
            return "";
        }

        if (!CryptCreateHash(hProv, useSHA256 ? CALG_SHA_256 : CALG_MD5, 0, 0, &hHash))
        {
            CryptReleaseContext(hProv, 0);
            return "";
        }

        if (!CryptHashData(hHash, (const BYTE*)data, (DWORD)length, 0))
        {
            CryptDestroyHash(hHash);
            CryptReleaseContext(hProv, 0);
            return "";
        }

        if (!CryptGetHashParam(hHash, HP_HASHVAL, hash, &hashLen, 0))
        {
            CryptDestroyHash(hHash);
            CryptReleaseContext(hProv, 0);
            return "";
        }

        std::stringstream ss;
        for (DWORD i = 0; i < hashLen; i++)
        {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }

        CryptDestroyHash(hHash);
        CryptReleaseContext(hProv, 0);

        return ss.str();
    }
};
