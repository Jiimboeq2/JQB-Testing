variable string J_Movement_Version = "2.0.0"
variable string J_Movement_ReleaseDate = "2025-10-18"
variable bool J_Movement_DeveloperMode = FALSE
variable string J_Movement_ScriptName

; Core Variables
variable(global) bool J_Movement_EncounterActive = FALSE
variable(global) string J_Movement_CurrentZoneObject
variable(global) bool J_Movement_ZoneSupported = FALSE

; Movement Object
variable(global) JMovementobj _obJMovement

; Config Paths
variable filepath J_Movement_ConfigPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/config/"

; Include dynamic zone manager and utilities
#include ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/JZoneManager.iss
#include ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/JMovement/jmovement_commands.iss
#include ${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/JB/jconfig_manager.iss

; Actor Index for Movement
variable(global) index:actor J_Movement_ActorIndex
variable(global) iterator J_Movement_ActorIndex_Iterator

function main()
{
    echo ${Time}: J Movement Script Started - Release: ${J_Movement_ReleaseDate}, Version: ${J_Movement_Version}

    if ${J_Movement_DeveloperMode}
    {
        J_Movement_ScriptName:Set[JMovement]
    }
    else
    {
        J_Movement_ScriptName:Set[Buffer:JMovement]
    }

    ; Load zone configuration dynamically
    _obJZoneManager:LoadZonesConfig

    ; Load JSON command configurations
    _obJConfig:LoadZoneConfig

    ; Attach event handlers
    Event[EQ2_FinishedZoning]:AttachAtom[JMovement_Main_FinishedZoning]
    Event[EQ2_onIncomingChatText]:AttachAtom[JMovement_onIncomingChatText]
    Event[EQ2_onAnnouncement]:AttachAtom[JMovement_onAnnouncement]
    Event[EQ2_onIncomingText]:AttachAtom[JMovement_onIncomingText]
    Event[EQ2_ActorSpawned]:AttachAtom[JMovement_ActorSpawned]
    Event[EQ2_ActorDespawned]:AttachAtom[JMovement_ActorDespawned]
    Event[EQ2_onGroupMemberAfflicted]:AttachAtom[JMovement_onGroupMemberAfflicted]
    Event[EQ2_onMeAfflicted]:AttachAtom[JMovement_onMeAfflicted]

    ; Initialize zone encounter coding dynamically
    call InitializeZoneEncounterCoding

    ; Main loop
    while 1
    {
        ExecuteQueued

        ; Call zone-specific main loop if zone object exists
        if ${_ob${Zone.ShortName}(exists)}
        call _ob${Zone.ShortName}.Main

        waitframe
    }
}

function InitializeZoneEncounterCoding()
{
    ; Use dynamic zone manager instead of hardcoded lists
    J_Movement_ZoneSupported:Set[${_obJZoneManager.IsZoneSupported}]

    if ${J_Movement_ZoneSupported}
    {
        echo ${Time}: [${Script.Filename}]: Zone [${Zone.Name}] is supported
        echo ${Time}: [${Script.Filename}]: Encounter file: ${_obJZoneManager.GetEncounterFile}

        ; Dynamically create zone object
        declarevariable _ob${Zone.ShortName} ${_obJZoneManager.GetZoneObjectType} global
        J_Movement_CurrentZoneObject:Set["${_obJZoneManager.GetZoneObjectName}"]

        _obJMovement:SetStatus[FALSE]
    }
    else
    {
        echo ${Time}: [${Script.Filename}]: Zone [${Zone.Name}] not supported
        echo ${Time}: [${Script.Filename}]: To add this zone, edit config/zones.json
    }
}

function ReInitializeZoneEncounterCoding()
{
    ; Clean up old zone object
    if ${J_Movement_CurrentZoneObject(exists)} && (${J_Movement_CurrentZoneObject.NotEqual[NULL]} && ${J_Movement_CurrentZoneObject.NotEqual[ ]})
    {
        DeleteVariable ${J_Movement_CurrentZoneObject}
        J_Movement_CurrentZoneObject:Set[NULL]
    }

    ; Dynamically check new zone
    J_Movement_ZoneSupported:Set[${_obJZoneManager.IsZoneSupported}]

    if ${J_Movement_ZoneSupported}
    {
        echo ${Time}: [${Script.Filename}]: Zone [${Zone.Name}] is supported
        echo ${Time}: [${Script.Filename}]: Encounter file: ${_obJZoneManager.GetEncounterFile}

        ; Dynamically create zone object
        declarevariable _ob${Zone.ShortName} ${_obJZoneManager.GetZoneObjectType} global
        J_Movement_CurrentZoneObject:Set["${_obJZoneManager.GetZoneObjectName}"]

        _obJMovement:SetStatus[FALSE]
    }
    else
    {
        echo ${Time}: [${Script.Filename}]: Zone [${Zone.Name}] not supported
    }
}

; Event Handlers
atom(global) JMovement_Main_FinishedZoning()
{
    call ReInitializeZoneEncounterCoding
}

atom(global) JMovement_onIncomingChatText(int ChatType, string Message, string Speaker, string ChatTarget, bool SpeakerIsNPC, string ChannelName)
{
    if ${Message.Find["J Shuffle"](exists)}
    {
        relay all "Script:End[JMovement]"
        relay all "run Eq2JCommon/JMovement/JMovement"
    }

    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        if ${Message.Find["Set up for J..."](exists)} && ${Speaker.Equal[${Me.Name}]}
        {
            ; Reload zone config
            _obJZoneManager:LoadZonesConfig
            _obJConfig:LoadZoneConfig
        }

        ; Forward to zone object dynamically
        _ob${Zone.ShortName}:EQ2_onIncomingChatText[${ChatType},"${Message.Escape}",${Speaker},${ChatTarget},${SpeakerIsNPC},${ChannelName}]
    }
}

atom(global) JMovement_onAnnouncement(string Text, string SoundType, float Timer)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_onAnnouncement["${Text.Escape}",${SoundType},${Timer}]
    }
}

atom(global) JMovement_onIncomingText(string Text)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_onIncomingText["${Text.Escape}"]
    }
}

atom(global) JMovement_ActorSpawned(string ID, string Name, string Level)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_ActorSpawned[${ID},"${Name.Escape}",${Level}]
    }
}

atom(global) JMovement_ActorDespawned(string ID, string Name)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_ActorDespawned[${ID},"${Name.Escape}"]
    }
}

atom(global) JMovement_onGroupMemberAfflicted(int ActorID, int TraumaCounter, int ArcaneCounter, int NoxiousCounter, int ElementalCounter, int CursedCounter)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_onGroupMemberAfflicted[${ActorID},${TraumaCounter},${ArcaneCounter},${NoxiousCounter},${ElementalCounter},${CursedCounter}]
    }
}

atom(global) JMovement_onMeAfflicted(int TraumaCounter, int ArcaneCounter, int NoxiousCounter, int ElementalCounter, int CursedCounter)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:EQ2_onMeAfflicted[${TraumaCounter},${ArcaneCounter},${NoxiousCounter},${ElementalCounter},${CursedCounter}]
    }
}

atom(global) JMovement_ZoneSpecific(string Sender, string EncounterName, string ForWho, string Message, string SpellName)
{
    if ${J_Movement_CurrentZoneObject(exists)} && ${J_Movement_CurrentZoneObject.NotEqual[NULL]}
    {
        _ob${Zone.ShortName}:JMovement_ZoneSpecific[${Sender},${EncounterName},${ForWho},${Message},${SpellName}]
    }
}

; Movement Object Definition
objectdef JMovementobj
{
    variable uint _ActorID
    variable float _ActorHeading
    variable float _ActorHeadingTo
    variable point3f _ActorLoc
    variable float _ActorDistance

    method SetStatus(bool DesiredStatus)
    {
        if !${J_Movement_EncounterActive} && ${DesiredStatus}
        {
            J_Movement_EncounterActive:Set[TRUE]
        }
        elseif ${J_Movement_EncounterActive} && !${DesiredStatus}
        {
            J_Movement_EncounterActive:Set[FALSE]
        }
    }

    member:bool ActiveState()
    {
        return ${J_Movement_EncounterActive}
    }

    method SetCampSpotBehind(string ForWho, uint ActorID, int Distance)
    {
        oc !c -ChangeCampSpotWho ${ForWho} ${This.ActorPosition_LocationBehind_X[${ActorID},${Distance}]} 0 ${This.ActorPosition_LocationBehind_Z[${ActorID},${Distance}]}
    }

    method SetCampSpotFront(string ForWho, uint ActorID, int Distance)
    {
        oc !c -ChangeCampSpotWho ${ForWho} ${This.ActorPosition_LocationFront_X[${ActorID},${Distance}]} 0 ${This.ActorPosition_LocationFront_Z[${ActorID},${Distance}]}
    }

    member:float ActorPosition_AdjustOpposingHeading(uint ActorID)
    {
        if ${Actor[id,${ActorID}].Heading} >= 0 && ${Actor[id,${ActorID}].Heading} < 90
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}+90]}
        elseif ${Actor[id,${ActorID}].Heading} >= 90 && ${Actor[id,${ActorID}].Heading} < 180
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}+90]}
        elseif ${Actor[id,${ActorID}].Heading} >= 180 && ${Actor[id,${ActorID}].Heading} < 270
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}-90]}
        else
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}-90]}
    }

    member:float ActorPosition_AdjustHeading(uint ActorID)
    {
        if ${Actor[id,${ActorID}].Heading} >= 0 && ${Actor[id,${ActorID}].Heading} < 90
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}-90]}
        elseif ${Actor[id,${ActorID}].Heading} >= 90 && ${Actor[id,${ActorID}].Heading} < 180
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}-90]}
        elseif ${Actor[id,${ActorID}].Heading} >= 180 && ${Actor[id,${ActorID}].Heading} < 270
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}+90]}
        else
        return ${Math.Calc[${Actor[id,${ActorID}].Heading}+90]}
    }

    member:float ActorPosition_LocationBehind_X(uint ActorID, int Distance)
    {
        variable float Actor_Loc_X = ${Actor[id,${ActorID}].X}
        variable int Point_Distance = ${Distance}
        variable float Actor_Heading = ${This.ActorPosition_AdjustOpposingHeading[${ActorID}]}
        return ${Math.Calc[${Actor_Loc_X}+${Point_Distance}*${Math.Cos[${Actor_Heading}]}]}
    }

    member:float ActorPosition_LocationBehind_Z(uint ActorID, int Distance)
    {
        variable float Actor_Loc_Z = ${Actor[id,${ActorID}].Z}
        variable int Point_Distance = ${Distance}
        variable float Actor_Heading = ${This.ActorPosition_AdjustOpposingHeading[${ActorID}]}
        return ${Math.Calc[${Actor_Loc_Z}+${Point_Distance}*${Math.Sin[${Actor_Heading}]}]}
    }

    member:float ActorPosition_LocationFront_X(uint ActorID, int Distance)
    {
        variable float Actor_Loc_X = ${Actor[id,${ActorID}].X}
        variable int Point_Distance = ${Distance}
        variable float Actor_Heading = ${This.ActorPosition_AdjustHeading[${ActorID}]}
        return ${Math.Calc[${Actor_Loc_X}+${Point_Distance}*${Math.Cos[${Actor_Heading}]}]}
    }

    member:float ActorPosition_LocationFront_Z(uint ActorID, int Distance)
    {
        variable float Actor_Loc_Z = ${Actor[id,${ActorID}].Z}
        variable int Point_Distance = ${Distance}
        variable float Actor_Heading = ${This.ActorPosition_AdjustHeading[${ActorID}]}
        return ${Math.Calc[${Actor_Loc_Z}+${Point_Distance}*${Math.Sin[${Actor_Heading}]}]}
    }

    method GetActors(string ActorType, int ActorRange)
    {
        J_Movement_ActorIndex:Clear

        if ${ActorType.Equal[All]}
        EQ2:GetActors[J_Movement_ActorIndex,range,${ActorRange}]
        else
        EQ2:GetActors[J_Movement_ActorIndex,${ActorType},range,${ActorRange}]

        J_Movement_ActorIndex:GetIterator[J_Movement_ActorIndex_Iterator]
    }

    method DoubleClickActor(string ActorType, int ActorRange)
    {
        This:GetActors[${ActorType},${ActorRange}]

        if ${J_Movement_ActorIndex_Iterator:First(exists)}
        {
            do
            {
                if ${J_Movement_ActorIndex_Iterator.Value.Interactable}
                Actor[id,${J_Movement_ActorIndex_Iterator.Value.ID}]:DoubleClick
            }
            while ${J_Movement_ActorIndex_Iterator:Next(exists)}
        }
    }

    member:int GroupRole()
    {
        return 0
    }
}

function atexit()
{
    echo ${Time}: Shutting Down J Movement...

    ; Detach events
    Event[EQ2_FinishedZoning]:DetachAtom[JMovement_Main_FinishedZoning]
    Event[EQ2_onIncomingChatText]:DetachAtom[JMovement_onIncomingChatText]
    Event[EQ2_onAnnouncement]:DetachAtom[JMovement_onAnnouncement]
    Event[EQ2_onIncomingText]:DetachAtom[JMovement_onIncomingText]
    Event[EQ2_ActorSpawned]:DetachAtom[JMovement_ActorSpawned]
    Event[EQ2_ActorDespawned]:DetachAtom[JMovement_ActorDespawned]
    Event[EQ2_onGroupMemberAfflicted]:DetachAtom[JMovement_onGroupMemberAfflicted]
    Event[EQ2_onMeAfflicted]:DetachAtom[JMovement_onMeAfflicted]
}