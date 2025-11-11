#pragma once
#include <string>
#include <fstream>
#include <sstream>

// ISXJQB Authentication System
// Handles license verification against backend database

class JQBAuth
{
private:
    static std::string PayPalEmail;
    static std::string LicenseKey;
    static bool IsAuthenticated;
    static std::string AuthFilePath;

    // Private constructor (singleton pattern)
    JQBAuth() {}

public:
    // Initialize auth system
    static void Initialize()
    {
        // Default auth file location
        AuthFilePath = "C:\\Program Files (x86)\\InnerSpace\\x64\\Extensions\\isxjqb_auth.xml";

        IsAuthenticated = false;
        PayPalEmail = "";
        LicenseKey = "";
    }

    // Load auth credentials from XML file
    static bool LoadAuthFile()
    {
        std::ifstream authFile(AuthFilePath);

        if (!authFile.is_open())
        {
            printf("\\ar[ISXJQB Auth] Auth file not found: %s", AuthFilePath.c_str());
            printf("\\ay[ISXJQB Auth] Please create isxjqb_auth.xml with your credentials");
            return false;
        }

        // Simple XML parsing (looking for email and license key)
        std::string line;
        bool foundEmail = false;
        bool foundKey = false;

        while (std::getline(authFile, line))
        {
            // Find <email> tag
            size_t emailStart = line.find("<email>");
            if (emailStart != std::string::npos)
            {
                emailStart += 7; // Length of "<email>"
                size_t emailEnd = line.find("</email>", emailStart);
                if (emailEnd != std::string::npos)
                {
                    PayPalEmail = line.substr(emailStart, emailEnd - emailStart);
                    // Trim whitespace
                    PayPalEmail.erase(0, PayPalEmail.find_first_not_of(" \t\r\n"));
                    PayPalEmail.erase(PayPalEmail.find_last_not_of(" \t\r\n") + 1);
                    foundEmail = true;
                }
            }

            // Find <license> tag
            size_t licenseStart = line.find("<license>");
            if (licenseStart != std::string::npos)
            {
                licenseStart += 9; // Length of "<license>"
                size_t licenseEnd = line.find("</license>", licenseStart);
                if (licenseEnd != std::string::npos)
                {
                    LicenseKey = line.substr(licenseStart, licenseEnd - licenseStart);
                    // Trim whitespace
                    LicenseKey.erase(0, LicenseKey.find_first_not_of(" \t\r\n"));
                    LicenseKey.erase(LicenseKey.find_last_not_of(" \t\r\n") + 1);
                    foundKey = true;
                }
            }
        }

        authFile.close();

        if (!foundEmail || !foundKey)
        {
            printf("\\ar[ISXJQB Auth] Invalid auth file format");
            return false;
        }

        printf("\\ag[ISXJQB Auth] Loaded credentials for: %s", PayPalEmail.c_str());
        return true;
    }

    // Verify license with backend server
    // TODO: Implement actual backend verification
    static bool VerifyLicense()
    {
        if (PayPalEmail.empty() || LicenseKey.empty())
        {
            printf("\\ar[ISXJQB Auth] No credentials loaded");
            return false;
        }

        printf("\\ay[ISXJQB Auth] Verifying license...");

        // TODO: Make HTTP request to backend API
        // Example: POST to https://your-domain.com/api/verify
        // Body: { "email": PayPalEmail, "license": LicenseKey }
        //
        // Expected response:
        // { "valid": true/false, "message": "...", "expires": "2025-12-31" }
        //
        // For now, placeholder verification
        // Use EzHttpRequest macro when backend is ready

        // PLACEHOLDER: Remove this when backend is implemented
        printf("\\ao[ISXJQB Auth] TODO: Backend verification not implemented yet");
        printf("\\ao[ISXJQB Auth] License: %s", LicenseKey.c_str());

        // For development, always return true
        // Change this to false when ready to enforce auth
        IsAuthenticated = true;

        if (IsAuthenticated)
        {
            printf("\\ag[ISXJQB Auth] License verified successfully!");
        }
        else
        {
            printf("\\ar[ISXJQB Auth] License verification failed!");
        }

        return IsAuthenticated;
    }

    // Check if currently authenticated
    static bool IsAuthed()
    {
        return IsAuthenticated;
    }

    // Get current email
    static const char* GetEmail()
    {
        return PayPalEmail.c_str();
    }

    // Get current license key (obfuscated display)
    static std::string GetLicenseKeyMasked()
    {
        if (LicenseKey.length() < 8)
            return "****";

        // Show first 4 and last 4 chars
        return LicenseKey.substr(0, 4) + "-****-****-" + LicenseKey.substr(LicenseKey.length() - 4);
    }

    // Create sample auth file
    static void CreateSampleAuthFile()
    {
        std::string samplePath = "C:\\Program Files (x86)\\InnerSpace\\x64\\Extensions\\isxjqb_auth_sample.xml";
        std::ofstream sampleFile(samplePath);

        if (!sampleFile.is_open())
        {
            printf("\\ar[ISXJQB Auth] Could not create sample auth file");
            return;
        }

        sampleFile << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        sampleFile << "<isxjqb_auth>\n";
        sampleFile << "    <!-- Your PayPal email used for purchase -->\n";
        sampleFile << "    <email>your-email@example.com</email>\n";
        sampleFile << "    \n";
        sampleFile << "    <!-- Your license key from the website -->\n";
        sampleFile << "    <!-- Format: XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX -->\n";
        sampleFile << "    <license>66B0-00B8-558A-5B6A-7B91-246E-9E98-B5DC</license>\n";
        sampleFile << "</isxjqb_auth>\n";

        sampleFile.close();

        printf("\\ag[ISXJQB Auth] Sample auth file created: %s", samplePath.c_str());
        printf("\\ay[ISXJQB Auth] Rename to isxjqb_auth.xml and update with your credentials");
    }

    // Force re-authentication
    static void ReAuth()
    {
        IsAuthenticated = false;
        PayPalEmail = "";
        LicenseKey = "";

        if (LoadAuthFile())
        {
            VerifyLicense();
        }
    }
};
