/*
 * JCheckboxManager - OgreBot Checkbox Profile Management
 * Path: ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/Include/JCheckboxManager.iss
 * 
 * Manages sets of OgreBot UI checkbox states for different scenarios
 * 
 * Features:
 * - Profiles for different roles (tank, healer, dps)
 * - Encounter-specific settings
 * - Bulk checkbox manipulation
 * - Profile save/load
 * - Integration with task system
 */

variable(global) string J_CheckboxManager_Version = "1.0.0"

objectdef JCheckboxManager_obj
{
    variable jsonvalue Profiles
    variable filepath ProfilePath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/config/checkbox_profiles.json"
    variable string CurrentProfile = ""
    variable bool Initialized = FALSE
    
    method Initialize()
    {
        if ${Initialized}
            return
        
        echo ${Time}: [CheckboxMgr] Initializing...
        
        if ${System.FileExists["${ProfilePath}"]}
        {
            Profiles:SetValue["${File.Read["${ProfilePath}"]}"]
            echo ${Time}: [CheckboxMgr] Loaded ${Profiles.Get[profiles].Keys} profiles
        }
        else
        {
            echo ${Time}: [CheckboxMgr] Creating default profiles...
            call This.CreateDefaultProfiles
        }
        
        Initialized:Set[TRUE]
        echo ${Time}: [CheckboxMgr] Ready (v${J_CheckboxManager_Version})
    }
    
    method ApplyProfile(string ProfileName, string ForWho="all")
    {
        if !${Initialized}
            call This.Initialize
        
        if !${Profiles.Has[profiles,"${ProfileName}"]}
        {
            echo ${Time}: [CheckboxMgr] ERROR: Profile '${ProfileName}' not found
            call This.ListProfiles
            return
        }
        
        variable jsonvalue profile
        profile:SetReference["Profiles.Get[profiles].Get[\"${ProfileName}\"]"]
        
        echo ${Time}: ================================================
        echo ${Time}: [CheckboxMgr] Applying profile: ${ProfileName}
        echo ${Time}: Target: ${ForWho}
        echo ${Time}: Description: ${profile.Get[description]}
        echo ${Time}: ================================================
        
        CurrentProfile:Set["${ProfileName}"]
        
        ; Enable required checkboxes
        if ${profile.Has[required_checkboxes]}
        {
            echo ${Time}: [CheckboxMgr] Enabling required checkboxes...
            variable int i
            for (i:Set[0]; ${i}<${profile.Get[required_checkboxes].Size}; i:Inc)
            {
                call This.SetCheckbox "${ForWho}" "${profile.Get[required_checkboxes].Get[${i}]}" TRUE
            }
        }
        
        ; Disable forbidden checkboxes
        if ${profile.Has[disabled_checkboxes]}
        {
            echo ${Time}: [CheckboxMgr] Disabling restricted checkboxes...
            variable int j
            for (j:Set[0]; ${j}<${profile.Get[disabled_checkboxes].Size}; j:Inc)
            {
                call This.SetCheckbox "${ForWho}" "${profile.Get[disabled_checkboxes].Get[${j}]}" FALSE
            }
        }
        
        ; Set specific values
        if ${profile.Has[set_values]}
        {
            echo ${Time}: [CheckboxMgr] Setting custom values...
            variable int k
            variable jsonvalue setValue
            for (k:Set[0]; ${k}<${profile.Get[set_values].Size}; k:Inc)
            {
                setValue:SetReference["profile.Get[set_values].Get[${k}]"]
                call This.SetUIValue "${ForWho}" "${setValue.Get[control]}" "${setValue.Get[value]}"
            }
        }
        
        echo ${Time}: [CheckboxMgr] Profile '${ProfileName}' applied
    }
    
    method SetCheckbox(string ForWho, string CheckboxName, bool Enabled)
    {
        ; Build full UI element path
        variable string fullName
        
        ; Check if already has full path
        if ${CheckboxName.Find["@"]}
        {
            fullName:Set["${CheckboxName}"]
        }
        else
        {
            ; Assume standard OgreBot UI structure
            fullName:Set["${CheckboxName}@frame_TabColumn1Button1@uiXML"]
        }
        
        if ${Enabled}
        {
            relay "${ForWho}" "QB_OgreBotCustomCommand Ogre_Change_UI \"${ForWho}\" \"${fullName}\" SetChecked \"\""
        }
        else
        {
            relay "${ForWho}" "QB_OgreBotCustomCommand Ogre_Change_UI \"${ForWho}\" \"${fullName}\" SetUnchecked \"\""
        }
        
        wait 2
    }
    
    method SetUIValue(string ForWho, string ControlName, string Value)
    {
        relay "${ForWho}" "QB_OgreBotCustomCommand Ogre_Change_UI \"${ForWho}\" \"${ControlName}\" SetValue \"${Value}\""
        wait 2
    }
    
    ; =====================================================
    ; PROFILE CREATION
    ; =====================================================
    
    method CreateDefaultProfiles()
    {
        variable jsonvalue defaults
        defaults:SetValue["$$>
{
  \"version\": \"${J_CheckboxManager_Version}\",
  \"profiles\": {
    \"instance_tank\": {
      \"description\": \"Tank settings for heroic/raid instances\",
      \"required_checkboxes\": [
        \"checkbox_settings_assist\",
        \"checkbox_settings_movetoarea\",
        \"checkbox_settings_movebehind\",
        \"checkbox_settings_facenpc\",
        \"checkbox_settings_meleeattack\"
      ],
      \"disabled_checkboxes\": [
        \"checkbox_autohunt_autohunt\",
        \"checkbox_settings_autofollow\"
      ]
    },
    \"instance_healer\": {
      \"description\": \"Healer settings for instances\",
      \"required_checkboxes\": [
        \"checkbox_settings_assist\",
        \"checkbox_settings_movetoarea\"
      ],
      \"disabled_checkboxes\": [
        \"checkbox_autohunt_autohunt\",
        \"checkbox_settings_disable_group_cures\"
      ]
    },
    \"instance_dps\": {
      \"description\": \"DPS settings for instances\",
      \"required_checkboxes\": [
        \"checkbox_settings_assist\",
        \"checkbox_settings_movetoarea\",
        \"checkbox_settings_movebehind\"
      ],
      \"disabled_checkboxes\": [
        \"checkbox_autohunt_autohunt\"
      ]
    },
    \"joust_encounter\": {
      \"description\": \"Settings for encounters requiring jousting\",
      \"required_checkboxes\": [
        \"checkbox_settings_movetoarea\",
        \"checkbox_settings_castwhilemoving\"
      ]
    },
    \"no_movement\": {
      \"description\": \"Disable all movement for specific encounters\",
      \"disabled_checkboxes\": [
        \"checkbox_settings_movetoarea\",
        \"checkbox_settings_movebehind\",
        \"checkbox_settings_movemelee\",
        \"checkbox_settings_autofollow\"
      ]
    },
    \"burn_mode\": {
      \"description\": \"Maximum DPS - disable cast stack\",
      \"required_checkboxes\": [
        \"checkbox_settings_assist\"
      ],
      \"disabled_checkboxes\": [
        \"checkbox_settings_disablecaststack_combat\",
        \"checkbox_settings_disablecaststack_ca\",
        \"checkbox_settings_disablecaststack_namedca\"
      ]
    }
  }
}
        <$$"]
        
        ProfilePath:WriteFile["${defaults}",multiline]
        Profiles:SetValue["${defaults}"]
        
        echo ${Time}: [CheckboxMgr] Created default profiles
    }
    
    ; =====================================================
    ; BULK OPERATIONS
    ; =====================================================
    
    method EnableCheckboxList(string ForWho, jsonvalue CheckboxList)
    {
        variable int i
        
        for (i:Set[0]; ${i}<${CheckboxList.Size}; i:Inc)
        {
            call This.SetCheckbox "${ForWho}" "${CheckboxList.Get[${i}]}" TRUE
        }
    }
    
    method DisableCheckboxList(string ForWho, jsonvalue CheckboxList)
    {
        variable int i
        
        for (i:Set[0]; ${i}<${CheckboxList.Size}; i:Inc)
        {
            call This.SetCheckbox "${ForWho}" "${CheckboxList.Get[${i}]}" FALSE
        }
    }
    
    ; =====================================================
    ; QUERY METHODS
    ; =====================================================
    
    method ListProfiles()
    {
        if !${Initialized}
            call This.Initialize
        
        echo ${Time}: ================================================
        echo ${Time}: [CheckboxMgr] Available Profiles
        echo ${Time}: ================================================
        
        variable iterator profileIter
        Profiles.Get[profiles]:GetIterator[profileIter]
        
        if ${profileIter:First(exists)}
        {
            do
            {
                echo ${Time}: - ${profileIter.Key}: ${profileIter.Value.Get[description]}
            }
            while ${profileIter:Next(exists)}
        }
        
        echo ${Time}: ================================================
    }
    
    member:bool ProfileExists(string ProfileName)
    {
        if !${Initialized}
            call This.Initialize
        
        return ${Profiles.Has[profiles,"${ProfileName}"]}
    }
    
    member:string GetCurrentProfile()
    {
        return "${CurrentProfile}"
    }
    
    ; =====================================================
    ; SAVE/LOAD
    ; =====================================================
    
    method SaveProfiles()
    {
        ProfilePath:WriteFile["${Profiles}",multiline]
        echo ${Time}: [CheckboxMgr] Saved profiles to ${ProfilePath}
    }
    
    method ReloadProfiles()
    {
        if ${System.FileExists["${ProfilePath}"]}
        {
            Profiles:SetValue["${File.Read["${ProfilePath}"]}"]
            echo ${Time}: [CheckboxMgr] Reloaded profiles
        }
    }
}

; Global instance
variable(global) JCheckboxManager_obj _obJCheckboxMgr

; Console commands
atom(global) a_CheckboxMgr_List()
{
    _obJCheckboxMgr:ListProfiles
}

atom(global) a_CheckboxMgr_Apply(string ProfileName, string ForWho)
{
    _obJCheckboxMgr:ApplyProfile "${ProfileName}" "${ForWho}"
}

