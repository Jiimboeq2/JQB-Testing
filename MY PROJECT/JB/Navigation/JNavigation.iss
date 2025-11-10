; JNavigation - Enhanced Waypoint Navigation System
; Path: ${LavishScript.HomeDirectory}/Scripts/Eq2Jcommon/JB/JNavigation.iss
; Version: 2.1.0

; Include the objectdef library
#include "${Script.CurrentDirectory}/../JB/Navigation/JNavigation_Lib.iss"


; =====================================================
; GLOBAL INSTANCE
; =====================================================

variable(global) JNavigation_obj Obj_JNav

; =====================================================
; COMMAND WRAPPERS FOR INSTANCE RUNNER
; =====================================================

function JCmd_Navigate(string pathName, string reverse, string preBuff, string ignoreAggro)
{
    variable bool bReverse = FALSE
    variable bool bPreBuff = FALSE
    variable bool bIgnoreAggro = FALSE

    if ${reverse.Equal[true]} || ${reverse.Equal[TRUE]} || ${reverse.Equal[1]}
    bReverse:Set[TRUE]

    if ${preBuff.Equal[true]} || ${preBuff.Equal[TRUE]} || ${preBuff.Equal[1]}
    bPreBuff:Set[TRUE]

    if ${ignoreAggro.Equal[true]} || ${ignoreAggro.Equal[TRUE]} || ${ignoreAggro.Equal[1]}
    bIgnoreAggro:Set[TRUE]

    ; This requires J_Instance_CurrentTask to be available
    ; Used by JInstanceRunner
    if ${J_Instance_CurrentTask(exists)}
    {
        call Obj_JNav.NavigatePathFromInstance "${pathName}" "${J_Instance_CurrentTask}" ${bReverse} ${bPreBuff} ${bIgnoreAggro}
    }
    else
    {
        echo ${Time}:  ERROR: JCmd_Navigate requires J_Instance_CurrentTask variable
        echo ${Time}: Use Obj_JNav:NavigatePath directly or provide instance data
    }
}

; =====================================================
; CONSOLE COMMANDS FOR TESTING
; =====================================================

atom(global) a_Nav_Status()
{
    Obj_JNav:ShowStatus
}

atom(global) a_Nav_GoTo(string X, string Y, string Z)
{
    Obj_JNav:NavigateToWaypoint ${X} ${Y} ${Z} 3.0
}

atom(global) a_Nav_Stop()
{
    Obj_JNav:StopMovement
}

atom(global) a_Nav_TestPath()
{
    variable jsonvalue testPath

    ; Create simple test path
    testPath:SetValue["$$>
    [
    {\"x\": ${Me.X}, \"y\": ${Me.Y}, \"z\": ${Me.Z}},
    {\"x\": ${Math.Calc[${Me.X}+10]}, \"y\": ${Me.Y}, \"z\": ${Me.Z}},
    {\"x\": ${Math.Calc[${Me.X}+10]}, \"y\": ${Me.Y}, \"z\": ${Math.Calc[${Me.Z}+10]}},
    {\"x\": ${Me.X}, \"y\": ${Me.Y}, \"z\": ${Math.Calc[${Me.Z}+10]}},
    {\"x\": ${Me.X}, \"y\": ${Me.Y}, \"z\": ${Me.Z}}
    ]
    <$$"]

    echo ${Time}: [Navigation] Testing with square path around current position

    Obj_JNav:NavigatePath "${testPath}" FALSE FALSE TRUE
}

; =====================================================
; MAIN FUNCTION
; =====================================================

function main()
{
    echo ================================================
    echo JNavigation v${J_Nav_Version} Loaded
    echo ================================================
    echo Global object Obj_JNav is ready
    echo
    echo Console commands:
    echo - a_Nav_Status - Show navigation status
    echo - a_Nav_GoTo X Y Z - Navigate to coordinates
    echo - a_Nav_Stop - Stop movement
    echo - a_Nav_TestPath - Test navigation with square path
    echo ================================================

    ; Keep script running
    while 1
    {
        waitframe
    }
}

function atexit()
{
    echo ${Time}: JNavigation unloaded
}