; =====================================================
; JMapper - Waypoint Recorder
; Simple console-based waypoint recorder
; =====================================================

variable(global) bool g_Recording = FALSE
variable(global) string g_PathName = "NewPath"
variable(global) float g_Distance = 5.0
variable(global) int g_Count = 0
variable(global) float g_LastX = 0
variable(global) float g_LastY = 0
variable(global) float g_LastZ = 0
variable(global) collection:string g_Waypoints

function main(string pathName="NewPath")
{
    g_PathName:Set["${pathName}"]

    echo ================================================
    echo JMapper - Waypoint Recorder
    echo ================================================
    echo Path: ${g_PathName}
    echo Distance: ${g_Distance}m
    echo
    echo Commands:
    echo   startrecording
    echo   stoprecording
    echo   addwaypoint
    echo   setdistance X
    echo   save
    echo ================================================

    ; Main loop
    do
    {
        if ${QueuedCommands}
        ExecuteQueued

        if ${g_Recording}
        {
            call CheckDistance
        }
        wait 5
    }
    while 1
}

atom(script) startrecording()
{
    g_Recording:Set[TRUE]
    g_LastX:Set[${Me.X}]
    g_LastY:Set[${Me.Y}]
    g_LastZ:Set[${Me.Z}]
    echo Recording started - move around to record waypoints
}

atom(script) stoprecording()
{
    g_Recording:Set[FALSE]
    echo Recording stopped - ${g_Count} waypoints
}

atom(script) addwaypoint()
{
    call AddWaypoint "${Me.X}" "${Me.Y}" "${Me.Z}"
    echo Added waypoint ${g_Count} at current position
}

atom(script) setdistance(float dist)
{
    g_Distance:Set[${dist}]
    echo Distance set to ${g_Distance}m
}

atom(script) save()
{
    if ${g_Count} == 0
    {
        echo ERROR: No waypoints to save
        return
    }

    echo Saving ${g_Count} waypoints...
    call SaveWaypoints
}

function CheckDistance()
{
    variable float dx
    variable float dy
    variable float dz
    variable float dist

    dx:Set[${Math.Calc[${Me.X} - ${g_LastX}]}]
    dy:Set[${Math.Calc[${Me.Y} - ${g_LastY}]}]
    dz:Set[${Math.Calc[${Me.Z} - ${g_LastZ}]}]

    dist:Set[${Math.Sqrt[${Math.Calc[${dx}*${dx} + ${dy}*${dy} + ${dz}*${dz}]}]}]

    if ${dist} >= ${g_Distance}
    {
        call AddWaypoint "${Me.X}" "${Me.Y}" "${Me.Z}"
        g_LastX:Set[${Me.X}]
        g_LastY:Set[${Me.Y}]
        g_LastZ:Set[${Me.Z}]
    }
}

function AddWaypoint(string x, string y, string z)
{
    g_Count:Inc
    g_Waypoints:Set["${g_Count}","${x},${y},${z}"]
}

function SaveWaypoints()
{
    variable string filePath = "${Script.CurrentDirectory}/JB/waypoints/${g_PathName}.xml"
    variable file myFile
    variable iterator iter

    echo Writing to: ${filePath}

    myFile:SetFilename["${filePath}"]
    myFile:Open[write]

    myFile:Write["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"]
    myFile:Write["<Waypoints>\n"]

    g_Waypoints:GetIterator[iter]
    if ${iter:First(exists)}
    {
        do
        {
            variable string coords = "${iter.Value}"
            variable string x
            variable string y
            variable string z

            x:Set["${coords.Token[1,","]}"]
            y:Set["${coords.Token[2,","]}"]
            z:Set["${coords.Token[3,","]}"]

            myFile:Write["    <Waypoint X=\"${x}\" Y=\"${y}\" Z=\"${z}\" />\n"]
        }
        while ${iter:Next(exists)}
    }

    myFile:Write["</Waypoints>\n"]
    myFile:Close

    echo ================================================
    echo SUCCESS!
    echo Saved ${g_Count} waypoints to:
    echo ${filePath}
    echo ================================================

    wait 20
    Script:End
}

function atexit()
{
    echo JMapper shut down - ${g_Count} waypoints recorded
}