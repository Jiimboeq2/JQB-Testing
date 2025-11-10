/*
 * JB_Commands_Travel.iss
 * Zone travel and navigation commands
 *
 * Commands:
 * - TravelBell - Use travel bell system
 * - TravelSpire - Use spire network
 * - TravelDruid - Use druid rings
 * - Door - Use zone door
 * - WaitForZoned - Wait for zone transition
 * - PortalToGuildHall - Portal to guild hall
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; TRAVEL BELL
; ============================================
objectdef Cmd_TravelBell inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["TravelBell", "Travel", "Travel using bell network\nParam: Destination"]
    }

    method ExecuteThread(string destination)
    {
        echo [TravelBell] Traveling to '${destination}' via bell

        ; Use OgreBot API for bell travel
        eq2execute oc !ci -TravelBell "${destination}"
        wait 10

        ; Wait for zoning
        variable int waited = 0
        while !${EQ2.Zoning} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        ; Wait for zone complete
        waited:Set[0]
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [TravelBell] Arrived at destination
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; TRAVEL SPIRE
; ============================================
objectdef Cmd_TravelSpire inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["TravelSpire", "Travel", "Travel using spire network\nParam: Destination"]
    }

    method ExecuteThread(string destination)
    {
        echo [TravelSpire] Traveling to '${destination}' via spire

        ; Use OgreBot API for spire travel
        eq2execute oc !ci -TravelSpires "${destination}"
        wait 10

        ; Wait for zoning
        variable int waited = 0
        while !${EQ2.Zoning} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        ; Wait for zone complete
        waited:Set[0]
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [TravelSpire] Arrived at destination
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; TRAVEL DRUID
; ============================================
objectdef Cmd_TravelDruid inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["TravelDruid", "Travel", "Travel using druid rings\nParam: Destination"]
    }

    method ExecuteThread(string destination)
    {
        echo [TravelDruid] Traveling to '${destination}' via druid ring

        ; Use OgreBot API for druid ring travel
        eq2execute oc !ci -TravelDruid "${destination}"
        wait 10

        ; Wait for zoning
        variable int waited = 0
        while !${EQ2.Zoning} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        ; Wait for zone complete
        waited:Set[0]
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [TravelDruid] Arrived at destination
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; DOOR
; ============================================
objectdef Cmd_Door inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["Door", "Travel", "Use zone door with option number\nParam: OptionNumber"]
    }

    method ExecuteThread(string optionNumber)
    {
        echo [Door] Using door option ${optionNumber}

        ; Execute door command
        eq2execute /useabilityonobject ${optionNumber}
        wait 10

        ; Wait for potential zoning
        variable int waited = 0
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [Door] Door used successfully
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; WAIT FOR ZONED
; ============================================
objectdef Cmd_WaitForZoned inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["WaitForZoned", "Travel", "Wait for zone transition to complete\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [WaitForZoned] Waiting for zone transition...

        ; Wait for zoning to start
        variable int waited = 0
        while !${EQ2.Zoning} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        ; Wait for zoning to complete
        waited:Set[0]
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        ; Additional wait for zone to stabilize
        wait 20

        echo [WaitForZoned] Zone transition complete
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; PORTAL TO GUILD HALL
; ============================================
objectdef Cmd_PortalToGuildHall inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["PortalToGuildHall", "Travel", "Portal to your guild hall\nParam: none"]
    }

    method ExecuteThread(string params)
    {
        echo [PortalToGuildHall] Portaling to guild hall

        ; Use guild hall portal ability
        eq2execute /useability Portal to Guild Hall
        wait 10

        ; Wait for zoning
        variable int waited = 0
        while !${EQ2.Zoning} && ${waited} < 100
        {
            wait 1
            waited:Inc
        }

        ; Wait for zone complete
        waited:Set[0]
        while ${EQ2.Zoning} && ${waited} < 300
        {
            wait 1
            waited:Inc
        }

        echo [PortalToGuildHall] Arrived at guild hall
        Success:Set[TRUE]
        This:Cleanup
    }
}
