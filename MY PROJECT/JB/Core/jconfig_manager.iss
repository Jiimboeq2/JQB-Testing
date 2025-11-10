; =====================================================
; JSON Configuration Manager for JMovement
; =====================================================


variable(global) filepath JConfigDir = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/config/"
variable(global) jsonvalue JCommands
variable(global) jsonvalue JCurrentZoneConfig
variable(global) string JCurrentZoneKey
variable(global) JConfigManager _obJConfig

objectdef JConfigManager
{
    method LoadZoneConfig()
    {
        variable string ZoneKey = "${Zone.ShortName}*${Zone.Name}"
        JCurrentZoneKey:Set["${ZoneKey}"]

        if !${JCommands:ParseFile["${JConfigDir}commands.json"](exists)}
        {
            echo ${Time}: JConfig: Commands file not found, creating default
            This:CreateDefaultCommandsFile
            JCommands:ParseFile["${JConfigDir}commands.json"]
        }

        if ${JCommands.Has[zones,"${ZoneKey}"]}
        {
            JCurrentZoneConfig:SetReference["JCommands.Get[zones,\"${ZoneKey}\"]"]
            echo ${Time}: JConfig: Loaded config for ${Zone.Name}
            return TRUE
        }
        else
        {
            echo ${Time}: JConfig: No config found for ${Zone.Name}
            return FALSE
        }
    }

    member:string GetCommand(string CommandName)
    {
        variable int i
        variable jsonvalue cmds

        if !${JCurrentZoneConfig.Has[commands]}
        return ""

        cmds:SetReference["JCurrentZoneConfig.Get[commands]"]

        for (i:Set[0]; ${i}<${cmds.Size}; i:Inc)
        {
            if ${cmds.Get[${i}].Get[name].Equal["${CommandName}"]}
            return "${cmds.Get[${i}].Get[name]}"
        }

        return ""
    }

    member:int GetCommandCount()
    {
        if ${JCurrentZoneConfig.Has[commands]}
        return ${JCurrentZoneConfig.Get[commands].Size}
        return 0
    }

    member:string GetCommandByIndex(int Index)
    {
        if ${JCurrentZoneConfig.Has[commands]}
        {
            if ${Index} < ${JCurrentZoneConfig.Get[commands].Size}
            return "${JCurrentZoneConfig.Get[commands].Get[${Index}].Get[name]}"
        }
        return ""
    }

    member:string GetPosition(string CommandName, string PositionType)
    {
        variable int i
        variable jsonvalue cmds

        if !${JCurrentZoneConfig.Has[commands]}
        return ""

        cmds:SetReference["JCurrentZoneConfig.Get[commands]"]

        for (i:Set[0]; ${i}<${cmds.Size}; i:Inc)
        {
            if ${cmds.Get[${i}].Get[name].Equal["${CommandName}"]}
            {
                if ${cmds.Get[${i}].Has[positions]}
                {
                    if ${cmds.Get[${i}].Get[positions].Has["${PositionType}"]}
                    return "${cmds.Get[${i}].Get[positions].Get["${PositionType}"]}"
                }

                if ${cmds.Get[${i}].Has[position]}
                return "${cmds.Get[${i}].Get[position]}"
            }
        }

        return ""
    }

    member:int GetScanRadius(string CommandName)
    {
        variable int i
        variable jsonvalue cmds

        if !${JCurrentZoneConfig.Has[commands]}
        return 40

        cmds:SetReference["JCurrentZoneConfig.Get[commands]"]

        for (i:Set[0]; ${i}<${cmds.Size}; i:Inc)
        {
            if ${cmds.Get[${i}].Get[name].Equal["${CommandName}"]}
            {
                if ${cmds.Get[${i}].Has[scan_radius]}
                return ${cmds.Get[${i}].Get[scan_radius]}
            }
        }

        return 40
    }

    method SaveConfig()
    {
        variable string configText = "${JCommands}"
        redirect "${JConfigDir}commands.json" echo ${configText}
        echo ${Time}: JConfig: Saved configuration
    }

    method CreateDefaultCommandsFile()
    {
        execute mkdir "${LavishScript.HomeDirectory.Replace[/,\\]}\\Scripts\\Eq2JCommon\\JB\\JMovement\\config"

        variable filepath ConfigFile = "${JConfigDir}commands.json"
        redirect "${ConfigFile}" echo {"version":"1.0","description":"Zone-specific movement commands for J Movement system","zones":{}}

        echo ${Time}: JConfig: Created default commands.json
    }
}