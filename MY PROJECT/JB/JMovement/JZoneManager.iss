; =====================================================
; J Zone Manager - Dynamic Zone Loading System
; =====================================================

variable(global) jsonvalue JZones_Config
variable(global) JZoneManager _obJZoneManager

objectdef JZoneManager
{
    variable string ConfigPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/config/"

    method LoadZonesConfig()
    {
        variable filepath ConfigFile = "${This.ConfigPath}zones.json"

        if ${ConfigFile.FileExists}
        {
            JZones_Config:SetValue["${File.Read["${ConfigFile}"]}"]
            echo ${Time}: [JZoneManager] Loaded zones config
        }
        else
        {
            echo ${Time}: [JZoneManager] zones.json not found, creating default
            This:CreateDefaultConfig
        }
    }

    method CreateDefaultConfig()
    {
        execute mkdir "${LavishScript.HomeDirectory.Replace[/,\\]}\\Scripts\\Eq2JCommon\\JB\\JMovement\\config"

        variable filepath ConfigFile = "${This.ConfigPath}zones.json"
        redirect "${ConfigFile}" echo {"version":"1.0","zones":{}}

        JZones_Config:SetValue["${File.Read["${ConfigFile}"]}"]
        echo ${Time}: [JZoneManager] Created default zones.json
    }

    member:bool IsZoneSupported()
    {
        if !${JZones_Config.Has[zones]}
        return FALSE

        variable string zoneKey = "${Zone.ShortName}"
        return ${JZones_Config.Get[zones].Has["${zoneKey}"]}
    }

    member:string GetEncounterFile()
    {
        if ${This.IsZoneSupported}
        {
            variable string zoneKey = "${Zone.ShortName}"
            if ${JZones_Config.Get[zones,"${zoneKey}"].Has[encounter_file]}
            return "${JZones_Config.Get[zones,"${zoneKey}"].Get[encounter_file]}"
        }
        return ""
    }

    member:string GetZoneObjectType()
    {
        if ${This.IsZoneSupported}
        {
            variable string zoneKey = "${Zone.ShortName}"
            if ${JZones_Config.Get[zones,"${zoneKey}"].Has[object_type]}
            return "${JZones_Config.Get[zones,"${zoneKey}"].Get[object_type]}"
        }
        return "JZone_Generic"
    }

    member:string GetZoneObjectName()
    {
        return "_ob${Zone.ShortName}"
    }
}