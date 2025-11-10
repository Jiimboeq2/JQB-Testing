/*
 * JB_PermissionManager.iss
 * User permission and license management system
 *
 * Permission Tiers:
 * - God: Unrestricted access, ignores all limits
 * - Oracle: Developer/tester access with minimal restrictions
 * - Acolyte: Base user tier with feature restrictions
 */

; ============================================
; PERMISSION LEVELS
; ============================================

variable(global) string PERM_LEVEL_GOD = "God"
variable(global) string PERM_LEVEL_ORACLE = "Oracle"
variable(global) string PERM_LEVEL_ACOLYTE = "Acolyte"

; ============================================
; PERMISSION MANAGER OBJECT
; ============================================

objectdef JB_PermissionManager
{
    ; Current user's permission level
    variable string UserLevel = "Acolyte"  ; Default to base tier
    variable string LicenseKey = ""
    variable bool LicenseValid = FALSE

    ; User authentication (for database validation)
    variable string Username = "Guest"
    variable string UserID = ""  ; Unique user ID from database

    ; Subscription info
    variable string ExpirationDate = "Never"  ; Format: YYYY-MM-DD
    variable int DaysRemaining = -1  ; -1 = unlimited/no expiration
    variable string SubscriptionStatus = "Active"  ; Active, Expired, Trial, Invalid

    ; Trial mode
    variable bool IsTrialMode = FALSE
    variable bool TrialEnabled = FALSE  ; Can be toggled on/off remotely

    ; IP and Machine tracking (for database validation)
    variable string CurrentIP = "127.0.0.1"
    variable string CurrentMachineID = "UNKNOWN"
    variable int RegisteredIPs = 0  ; How many IPs user has registered
    variable int RegisteredMachines = 0  ; How many machines user has registered

    ; IP/Machine limits by tier
    variable int MaxIPs = 2  ; Default: 2 IPs for Acolyte/Oracle
    variable int MaxMachines = 3  ; Default: 3 machines for Acolyte/Oracle

    ; Permission cache
    variable bool PermissionsLoaded = FALSE

    ; ============================================
    ; INITIALIZATION
    ; ============================================

    method Initialize()
    {
        ; Prevent double-initialization
        if ${PermissionsLoaded}
        {
            if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
                echo [Debug:Permissions] Already initialized - skipping
            return
        }

        ; TODO: Load license from file or server
        ; For now, default to Acolyte
        UserLevel:Set["${PERM_LEVEL_ACOLYTE}"]

        ; TODO: Get current IP and machine ID
        ; CurrentIP:Set["${System.GetExternalIP}"]
        ; CurrentMachineID:Set["${System.GetMachineID}"]

        ; TODO: Validate license key
        LicenseValid:Set[FALSE]

        ; TODO: Load subscription info from server
        ; Placeholder values
        ExpirationDate:Set["2025-12-31"]
        DaysRemaining:Set[365]
        SubscriptionStatus:Set["Active"]

        ; Set IP/Machine limits based on tier
        This:UpdateLimitsForTier

        PermissionsLoaded:Set[TRUE]

        ; Display subscription status with colors
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Initialized - Level:${UserLevel}, LicenseValid:${LicenseValid}, DaysRemaining:${DaysRemaining}
    }

    ; Display subscription status with colors
    method DisplaySubscriptionStatus()
    {
        variable string colorWhite = "\\aw"
        variable string colorReset = "\\ax"
        variable string colorOrange = "\\ao"
        variable string tierColor = "\\ax"
        variable string statusColor = "\\ax"
        variable string daysColor = "\\ax"
        variable string expiryText = "${ExpirationDate}"

        ; Determine tier color (Purple=God, Blue=Oracle, Yellow=Acolyte)
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
            tierColor:Set["\\ap"]
        elseif ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
            tierColor:Set["\\ab"]
        else
            tierColor:Set["\\ay"]

        ; Determine status color (Green=Active, Yellow=Trial, Red=Expired/Invalid)
        if ${SubscriptionStatus.Equal["Active"]}
            statusColor:Set["\\ag"]
        elseif ${SubscriptionStatus.Equal["Trial"]}
            statusColor:Set["\\ay"]
        elseif ${SubscriptionStatus.Equal["Expired"]}
            statusColor:Set["\\ar"]
        else
            statusColor:Set["\\ar"]

        ; Determine days remaining color (Green=30+, Yellow=7-29, Red=<7)
        if ${DaysRemaining} < 0
        {
            daysColor:Set["\\ag"]
            expiryText:Set["Never (Unlimited)"]
        }
        elseif ${DaysRemaining} >= 30
        {
            daysColor:Set["\\ag"]
        }
        elseif ${DaysRemaining} >= 7
        {
            daysColor:Set["\\ay"]
        }
        else
        {
            daysColor:Set["\\ar"]
        }

        ; Display formatted subscription info
        echo ${colorReset}========================================
        echo ${colorOrange}   JQUESTBOT SUBSCRIPTION STATUS
        echo ${colorReset}========================================
        echo ${colorWhite} Tier:        ${tierColor}${UserLevel}${colorReset}
        echo ${colorWhite} Status:      ${statusColor}${SubscriptionStatus}${colorReset}
        echo ${colorWhite} Expires:     ${daysColor}${expiryText}${colorReset}
        if ${DaysRemaining} >= 0
            echo ${colorWhite} Days Left:   ${daysColor}${DaysRemaining} days${colorReset}
        echo ${colorReset}========================================
    }

    ; Update IP/Machine limits based on tier
    method UpdateLimitsForTier()
    {
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
        {
            MaxIPs:Set[4]
            MaxMachines:Set[8]
        }
        elseif ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
        {
            MaxIPs:Set[2]
            MaxMachines:Set[3]
        }
        else
        {
            ; Acolyte
            MaxIPs:Set[2]
            MaxMachines:Set[3]
        }

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Limits updated - MaxIPs:${MaxIPs}, MaxMachines:${MaxMachines}
    }

    ; ============================================
    ; USER AUTHENTICATION (Database Integration)
    ; ============================================

    method Login(string username, string password)
    {
        echo [PermissionManager] Logging in user: ${username}

        Username:Set["${username}"]

        ; TODO: Validate username/password against database
        ; TODO: Get user info from database:
        ;   - UserID
        ;   - UserLevel (God/Oracle/Acolyte)
        ;   - LicenseKey
        ;   - ExpirationDate
        ;   - SubscriptionStatus
        ;   - IsTrialMode
        ;   - TrialEnabled
        ;   - RegisteredIPs
        ;   - RegisteredMachines

        ; TODO: Validate current IP and machine against database
        ; if !${This.ValidateIPAndMachine}
        ; {
        ;     echo [PermissionManager] ERROR: IP or machine limit exceeded
        ;     LicenseValid:Set[FALSE]
        ;     return
        ; }

        ; Placeholder response
        echo [PermissionManager] Login successful
        LicenseValid:Set[TRUE]
        UserLevel:Set["${PERM_LEVEL_ACOLYTE}"]
        This:UpdateLimitsForTier

        ; Display subscription status
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Login complete - Username:${Username}, Level:${UserLevel}
    }

    ; Validate current IP and machine against registered limits
    member:bool ValidateIPAndMachine()
    {
        ; TODO: Check with database if current IP is registered
        ; TODO: Check with database if current machine is registered
        ; TODO: If not registered:
        ;   - If under limit, register and allow
        ;   - If at limit, deny access

        ; PLACEHOLDER VALIDATION
        ; if ${RegisteredIPs} >= ${MaxIPs}
        ; {
        ;     echo [PermissionManager] IP limit reached (${RegisteredIPs}/${MaxIPs})
        ;     return FALSE
        ; }
        ;
        ; if ${RegisteredMachines} >= ${MaxMachines}
        ; {
        ;     echo [PermissionManager] Machine limit reached (${RegisteredMachines}/${MaxMachines})
        ;     return FALSE
        ; }

        ; Allow for now
        return TRUE
    }

    ; ============================================
    ; TRIAL MODE MANAGEMENT
    ; ============================================

    ; Enable trial mode for user (beta testing)
    method EnableTrial(string username, int daysValid)
    {
        echo [PermissionManager] Enabling trial for user: ${username}

        Username:Set["${username}"]
        IsTrialMode:Set[TRUE]
        TrialEnabled:Set[TRUE]
        SubscriptionStatus:Set["Trial"]
        LicenseValid:Set[TRUE]

        ; Set trial duration
        DaysRemaining:Set[${daysValid}]
        ; TODO: Calculate expiration date from current date + daysValid
        ExpirationDate:Set["2025-12-31"]  ; Placeholder

        ; TODO: Save to database
        ; - Mark user as trial
        ; - Set trial expiration
        ; - Set TrialEnabled = TRUE

        echo [PermissionManager] Trial enabled - ${daysValid} days
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Trial activated - Username:${Username}, Days:${daysValid}, Enabled:${TrialEnabled}
    }

    ; Disable trial mode (yoink access)
    method DisableTrial(string username)
    {
        echo [PermissionManager] Disabling trial for user: ${username}

        TrialEnabled:Set[FALSE]
        LicenseValid:Set[FALSE]
        SubscriptionStatus:Set["Expired"]

        ; TODO: Update database
        ; - Set TrialEnabled = FALSE
        ; - Don't delete trial record (so it can be reinstated)

        echo [PermissionManager] Trial access revoked for ${username}
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Trial disabled - Username:${Username}, Enabled:${TrialEnabled}
    }

    ; Reinstate trial mode (restore access)
    method ReinstateTrial(string username)
    {
        echo [PermissionManager] Reinstating trial for user: ${username}

        ; TODO: Load trial info from database
        ; TODO: Check if trial hasn't expired

        TrialEnabled:Set[TRUE]
        LicenseValid:Set[TRUE]
        SubscriptionStatus:Set["Trial"]

        ; TODO: Update database
        ; - Set TrialEnabled = TRUE

        echo [PermissionManager] Trial access reinstated for ${username}
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] Trial reinstated - Username:${Username}, Enabled:${TrialEnabled}
    }

    ; Check if trial is valid
    member:bool IsTrialValid()
    {
        if !${IsTrialMode}
            return FALSE

        if !${TrialEnabled}
        {
            echo [PermissionManager] Trial has been disabled
            return FALSE
        }

        if ${DaysRemaining} <= 0
        {
            echo [PermissionManager] Trial has expired
            return FALSE
        }

        return TRUE
    }

    ; ============================================
    ; LICENSE MANAGEMENT
    ; ============================================

    method LoadLicense(string licenseKey)
    {
        echo [PermissionManager] Loading license: ${licenseKey.Left[8]}...

        LicenseKey:Set["${licenseKey}"]

        ; TODO: Validate license key with server
        ; TODO: Determine permission level from license
        ; TODO: Get expiration date from server
        ; TODO: Check if trial mode

        ; Placeholder validation
        if ${licenseKey.Equal["GOD-KEY-PLACEHOLDER"]}
        {
            UserLevel:Set["${PERM_LEVEL_GOD}"]
            LicenseValid:Set[TRUE]
            SubscriptionStatus:Set["Active"]
            ExpirationDate:Set["Never"]
            DaysRemaining:Set[-1]
            IsTrialMode:Set[FALSE]
        }
        elseif ${licenseKey.Equal["ORACLE-KEY-PLACEHOLDER"]}
        {
            UserLevel:Set["${PERM_LEVEL_ORACLE}"]
            LicenseValid:Set[TRUE]
            SubscriptionStatus:Set["Active"]
            ExpirationDate:Set["2026-12-31"]
            DaysRemaining:Set[730]
            IsTrialMode:Set[FALSE]
        }
        elseif ${licenseKey.Equal["TRIAL-KEY-PLACEHOLDER"]}
        {
            UserLevel:Set["${PERM_LEVEL_ACOLYTE}"]
            LicenseValid:Set[TRUE]
            SubscriptionStatus:Set["Trial"]
            ExpirationDate:Set["2025-12-31"]
            DaysRemaining:Set[30]
            IsTrialMode:Set[TRUE]
            TrialEnabled:Set[TRUE]
        }
        else
        {
            UserLevel:Set["${PERM_LEVEL_ACOLYTE}"]
            LicenseValid:Set[FALSE]
            SubscriptionStatus:Set["Invalid"]
            ExpirationDate:Set["Unknown"]
            DaysRemaining:Set[0]
            IsTrialMode:Set[FALSE]
        }

        ; Update IP/Machine limits for tier
        This:UpdateLimitsForTier

        ; Display updated subscription status
        This:DisplaySubscriptionStatus

        if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
            echo [Debug:Permissions] License loaded - Level:${UserLevel}, Valid:${LicenseValid}, DaysRemaining:${DaysRemaining}, Trial:${IsTrialMode}
    }

    ; ============================================
    ; PERMISSION CHECKS
    ; ============================================

    ; Check if user has permission for a feature
    member:bool HasPermission(string feature)
    {
        ; God mode bypasses all checks
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
        {
            if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
                echo [Debug:Permissions] God mode - Permission granted: ${feature}
            return TRUE
        }

        ; Oracle level checks
        if ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
        {
            return ${This.CheckOraclePermission["${feature}"]}
        }

        ; Acolyte level checks
        if ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
        {
            return ${This.CheckAcolytePermission["${feature}"]}
        }

        ; Unknown level - deny by default
        echo [PermissionManager] WARNING: Unknown permission level ${UserLevel}
        return FALSE
    }

    ; Oracle permission checks
    member:bool CheckOraclePermission(string feature)
    {
        ; Oracle has most features enabled
        ; Only critical restrictions apply

        switch ${feature}
        {
            ; PLACEHOLDER RESTRICTIONS FOR ORACLE
            ; Uncomment when ready to implement

            ; case CanModifyCoreSystems
            ;     echo [PermissionManager] Oracle denied: ${feature}
            ;     return FALSE

            ; case CanAccessProductionServers
            ;     echo [PermissionManager] Oracle denied: ${feature}
            ;     return FALSE

            default
                ; Allow everything else for Oracle
                if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
                    echo [Debug:Permissions] Oracle - Permission granted: ${feature}
                return TRUE
        }
    }

    ; Acolyte permission checks
    member:bool CheckAcolytePermission(string feature)
    {
        ; Acolyte has restricted access
        ; Most limitations apply here

        switch ${feature}
        {
            ; PLACEHOLDER RESTRICTIONS FOR ACOLYTE
            ; Uncomment when ready to implement

            ; Instance Looping
            ; case CanLoopInstances
            ;     echo [PermissionManager] Acolyte denied: Instance looping requires upgrade
            ;     return FALSE

            ; case CanRunUnlimitedInstances
            ;     echo [PermissionManager] Acolyte denied: Limited to 5 instance runs per day
            ;     return FALSE

            ; Zone Access
            ; case CanEnterRaidZones
            ;     echo [PermissionManager] Acolyte denied: Raid zones require upgrade
            ;     return FALSE

            ; case CanEnterAdvancedZones
            ;     echo [PermissionManager] Acolyte denied: Advanced zones require upgrade
            ;     return FALSE

            ; Quest Access
            ; case CanBotEpicQuests
            ;     echo [PermissionManager] Acolyte denied: Epic quests require upgrade
            ;     return FALSE

            ; case CanBotSignatureQuests
            ;     echo [PermissionManager] Acolyte denied: Signature quests require upgrade
            ;     return FALSE

            ; Advanced Commands
            ; case CanUseTravelCommands
            ;     echo [PermissionManager] Acolyte denied: Travel commands require upgrade
            ;     return FALSE

            ; case CanUseAdvancedCrafting
            ;     echo [PermissionManager] Acolyte denied: Advanced crafting requires upgrade
            ;     return FALSE

            ; Runtime Limits
            ; case CanRunUnlimited
            ;     echo [PermissionManager] Acolyte denied: 2 hour runtime limit
            ;     return FALSE

            ; case CanBypassCooldowns
            ;     echo [PermissionManager] Acolyte denied: Cooldown bypass requires upgrade
            ;     return FALSE

            default
                ; Allow basic features for Acolyte
                if ${JBUI_Debug_System(exists)} && ${JBUI_Debug_System}
                    echo [Debug:Permissions] Acolyte - Permission granted: ${feature}
                return TRUE
        }
    }

    ; Get maximum instance runs allowed
    member:int GetMaxInstanceRuns()
    {
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
            return -1  ; Unlimited

        if ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
            return -1  ; Unlimited

        ; if ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
        ;     return 5  ; 5 per day limit

        return -1  ; Unlimited for now
    }

    ; Get maximum runtime in minutes
    member:int GetMaxRuntime()
    {
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
            return -1  ; Unlimited

        if ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
            return -1  ; Unlimited

        ; if ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
        ;     return 120  ; 2 hour limit

        return -1  ; Unlimited for now
    }

    ; Check if zone is allowed
    member:bool IsZoneAllowed(string zoneName)
    {
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
            return TRUE

        if ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
            return TRUE

        ; PLACEHOLDER ZONE RESTRICTIONS FOR ACOLYTE
        ; if ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
        ; {
        ;     ; Block raid zones
        ;     if ${zoneName.Find["Raid"]} >= 0
        ;         return FALSE
        ;
        ;     ; Block specific high-end zones
        ;     if ${zoneName.Equal["Plane of War"]}
        ;         return FALSE
        ; }

        return TRUE  ; Allow all zones for now
    }

    ; Check if quest is allowed
    member:bool IsQuestAllowed(string questName)
    {
        if ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
            return TRUE

        if ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
            return TRUE

        ; PLACEHOLDER QUEST RESTRICTIONS FOR ACOLYTE
        ; if ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
        ; {
        ;     ; Block epic quests
        ;     if ${questName.Find["Epic"]} >= 0
        ;         return FALSE
        ;
        ;     ; Block signature quests
        ;     if ${questName.Find["Signature"]} >= 0
        ;         return FALSE
        ; }

        return TRUE  ; Allow all quests for now
    }

    ; ============================================
    ; STATUS & INFORMATION
    ; ============================================

    member:string GetUserLevel()
    {
        return ${UserLevel}
    }

    member:bool IsGod()
    {
        return ${UserLevel.Equal["${PERM_LEVEL_GOD}"]}
    }

    member:bool IsOracle()
    {
        return ${UserLevel.Equal["${PERM_LEVEL_ORACLE}"]}
    }

    member:bool IsAcolyte()
    {
        return ${UserLevel.Equal["${PERM_LEVEL_ACOLYTE}"]}
    }

    method PrintStatus()
    {
        ; Display color-coded subscription status
        This:DisplaySubscriptionStatus

        ; Additional info
        echo \\aw  License Key:  \\ax${LicenseKey.Left[8]}...
        echo \\aw  Max Runs:     \\ax${This.GetMaxInstanceRuns}
        echo \\aw  Max Runtime:  \\ax${This.GetMaxRuntime} minutes
        echo \\ax========================================
    }
}

; ============================================
; GLOBAL INSTANCE
; ============================================

variable(global) JB_PermissionManager JBPermManager
