# ISUI XML Patterns Guide - Adapted from Legacy Examples

This guide documents UI patterns extracted from the `new-branch-name` branch examples and adapted for the Eq2JCommon system.

## Table of Contents
1. [Template System](#template-system)
2. [Window Structure](#window-structure)
3. [Variable Declarations](#variable-declarations)
4. [Button Patterns](#button-patterns)
5. [Frame-Based Tab System](#frame-based-tab-system)
6. [Dynamic Updates with OnRender](#dynamic-updates-with-onrender)
7. [Script Communication](#script-communication)
8. [Skin Loading](#skin-loading)
9. [Color Schemes](#color-schemes)

---

## Template System

**Pattern**: Define reusable templates to avoid repetition.

### Example from BJQuestBot:
```xml
<Template Name='Static_Buttons'>
    <Width>80</Width>
    <Height>20</Height>
    <Alignment>Center</Alignment>
    <Font Template='commandbutton.Font' />
    <Texture Template='commandbutton.Texture' />
    <TextureHover Template='commandbutton.TextureHover' />
    <TexturePressed Template='commandbutton.TexturePressed' />
</Template>

<!-- Use the template -->
<CommandButton Name="BJQB_Main_Button" template='Static_Buttons'>
    <X>10</X>
    <Y>10</Y>
    <Text>Main</Text>
    <OnLeftClick>...</OnLeftClick>
</CommandButton>
```

### Adapted for JB System:
```xml
<Template Name='JB_StandardButton'>
    <Width>120</Width>
    <Height>25</Height>
    <Alignment>Center</Alignment>
    <Font>
        <Bold>1</Bold>
        <Size>12</Size>
    </Font>
</Template>
```

---

## Window Structure

### Standard Window Pattern:
```xml
<Window Name='WindowName' Template='Window'>
    <X>20</X>
    <Y>20</Y>
    <Width>980</Width>
    <Height>500</Height>
    <Client Template="Window.Client" />
    <StorePosition>1</StorePosition>
    <Visible>0</Visible>  <!-- Main windows hidden by default -->
    <Title>Title with ${Dynamic_Vars}</Title>

    <OnLoad>
        declarevariable JBUI_WindowName int global ${This.ID}
        <!-- More setup -->
    </OnLoad>

    <TitleBar Template="Window.TitleBar">
        <!-- Close button, minimize, etc -->
    </TitleBar>

    <Children>
        <!-- UI elements -->
    </Children>
</Window>
```

### Key Points:
- **StorePosition**: Remembers window position between sessions
- **Visible**: Main windows start hidden (0), mini windows start visible (1)
- **Dynamic Titles**: Use `${VariableName}` in titles for real-time updates

---

## Variable Declarations

### Pattern from Examples:
```xml
<OnLoad>
    declarevariable BJQBUI_BJQuestBotMain int global ${This.ID}
    declarevariable QuestBot_Version_Number string global
    declarevariable QuestBot_Developer_Mode bool global
    declarevariable BJQB_ElapsedTime_Hours int global

    QuestBot_Version_Number:Set[${QuestBot_Version_Number_Temp}]
    QuestBot_Developer_Mode:Set[${QuestBot_Developer_Mode_Temp}]
    BJQB_ElapsedTime_Hours:Set[00]
</OnLoad>
```

### Naming Convention:
- UI Element IDs: `JBUI_ElementName` (stores ${This.ID})
- Private vars: `_sVariableName` (string), `_bVariableName` (bool), `_iVariableName` (int)
- Public state vars: `JB_VariableName`

### Adapted for JB System:
```xml
<OnLoad>
    declarevariable JBUI_Main_Window int global ${This.ID}
    declarevariable J_System_Version string global "3.0.1"
    declarevariable _bJB_Active bool global
    declarevariable _sJB_SelectedInstance string global

    _bJB_Active:Set[FALSE]
    _sJB_SelectedInstance:Set[""]
</OnLoad>
```

---

## Button Patterns

### Show/Hide Main Window Pattern:
```xml
<!-- Show Main Button -->
<CommandButton Name="ShowMainButton">
    <OnLeftClick>
        UIElement[${BJInventoryMainVar}]:Show
        This.Parent.FindChild[HideMainButton]:Show
        This:Hide
    </OnLeftClick>
    <OnLoad>
        declarevariable ShowMainButtonVar int global ${This.ID}
    </OnLoad>
</CommandButton>

<!-- Hide Main Button -->
<CommandButton Name="HideMainButton">
    <Visible>0</Visible>
    <OnLeftClick>
        UIElement[${BJInventoryMainVar}]:Hide
        This.Parent.FindChild[ShowMainButton]:Show
        This:Hide
    </OnLeftClick>
</CommandButton>
```

### Action Button Pattern:
```xml
<CommandButton Name="Start_Button">
    <Text>Start Instance</Text>
    <OnLeftClick>
        if ${_sJB_SelectedInstance.Length}
        {
            UIElement[${JBUI_Stop_Button}]:Show
            runscript "JB/JInstanceRunner" "${_sJB_SelectedInstance}"
            This:Hide
        }
        else
        {
            echo ${Time}: ERROR: No instance selected!
        }
    </OnLeftClick>
    <OnLoad>
        declarevariable JBUI_Start_Button int global ${This.ID}
        UIElement[${JBUI_Start_Button}].Font:SetColor[FF00FF00]
    </OnLoad>
</CommandButton>
```

---

## Frame-Based Tab System

### Pattern from BJQuestBot (Multi-Frame Tabs):
```xml
<Frame Name='Static_Buttons_Frame'>
    <Border>2</Border>
    <Children>
        <CommandButton Name="Main_Tab_Button">
            <OnLeftClick>
                Script[Controller]:QueueCommand[call DisplayFrame Main]
            </OnLeftClick>
            <OnLoad>
                UIElement[${This.ID}].Font:SetColor[FF00FF00]  <!-- Highlighted -->
            </OnLoad>
        </CommandButton>
        <CommandButton Name="Settings_Tab_Button">
            <OnLeftClick>
                Script[Controller]:QueueCommand[call DisplayFrame Settings]
            </OnLeftClick>
        </CommandButton>
    </Children>
</Frame>

<Frame Name='Main_Content_Frame'>
    <Visible>1</Visible>  <!-- Default visible -->
    <Children>...</Children>
</Frame>

<Frame Name='Settings_Content_Frame'>
    <Visible>0</Visible>
    <Children>...</Children>
</Frame>
```

### Controller Function (ISS):
```iss
function DisplayFrame(string frameName)
{
    ; Hide all frames
    UIElement[${JBUI_Main_Content_Frame}]:Hide
    UIElement[${JBUI_Settings_Content_Frame}]:Hide

    ; Reset all button colors
    UIElement[${JBUI_Main_Tab_Button}].Font:SetColor[FFFFFFFF]
    UIElement[${JBUI_Settings_Tab_Button}].Font:SetColor[FFFFFFFF]

    ; Show selected frame and highlight button
    switch ${frameName}
    {
        case Main
            UIElement[${JBUI_Main_Content_Frame}]:Show
            UIElement[${JBUI_Main_Tab_Button}].Font:SetColor[FF00FF00]
            break
        case Settings
            UIElement[${JBUI_Settings_Content_Frame}]:Show
            UIElement[${JBUI_Settings_Tab_Button}].Font:SetColor[FF00FF00]
            break
    }
}
```

---

## Dynamic Updates with OnRender

### Pattern from bjmagic:
```xml
<Text name='StatusVariable'>
    <Text>Status:</Text>
    <OnRender>
        This:SetText[${statusvar}]
    </OnRender>
</Text>

<Text name='AttemptNumberVar'>
    <OnRender>
        This:SetText[${count}]
    </OnRender>
</Text>

<Text name='TimeRunningVar'>
    <OnRender>
        This:SetText[${timerunning}]
    </OnRender>
</Text>
```

### Use Cases:
- Real-time status updates
- Counters (steps completed, failures, etc.)
- Time displays
- Progress indicators

### Adapted for JB System:
```xml
<Text name='CurrentStep_Display'>
    <OnRender>
        This:SetText[Step: ${J_Instance_CurrentStep} / ${J_Instance_MaxSteps}]
    </OnRender>
</Text>

<Text name='Status_Display'>
    <OnRender>
        if ${_bJB_Active}
        {
            if ${_bJB_Paused}
                This:SetText[Paused]
            else
                This:SetText[Running]
        }
        else
        {
            This:SetText[Idle]
        }
    </OnRender>
</Text>
```

---

## Script Communication

### Pattern: QueueCommand for Thread-Safe Communication
```xml
<OnLeftClick>
    Script[${QuestBotController_ScriptName}]:QueueCommand[call FunctionName arg1 arg2]
</OnLeftClick>
```

### Pattern: ExecuteAtom for Immediate Calls
```xml
<OnLeftClick>
    if ${Script[JInstanceRunner](exists)}
        Script[JInstanceRunner]:ExecuteAtom[a_Instance_Stop]
</OnLeftClick>
```

### Pattern: Check Script Existence
```xml
if ${Script[JInstanceRunner](exists)}
    endscript JInstanceRunner
if ${Script[JQuestBot](exists)}
    endscript JQuestBot
```

### Developer Mode Pattern:
```xml
<OnLoad>
    declarevariable JB_DeveloperMode bool global
    JB_DeveloperMode:Set[FALSE]
</OnLoad>

<OnLeftClick>
    if ${JB_DeveloperMode}
        runscript "JB/JInstanceRunner" "${_sJB_SelectedInstance}"
    else
        run JInstanceRunner "${_sJB_SelectedInstance}"
</OnLeftClick>
```

**Why**: `runscript` loads source in foreground (easier debugging), `run` uses compiled buffer.

---

## Skin Loading

### Pattern from Examples:

#### Shell/Loader Script (ISS):
```iss
function main()
{
    ui -reload "${LavishScript.HomeDirectory}/Interface/skins/eq2/eq2.xml"
    ui -reload -skin eq2 "${LavishScript.HomeDirectory}/Scripts/path/to/UI.xml"
}
```

#### OnLoad in XML:
```xml
<OnLoad>
    ui -load -skin EQ2BJ "${LavishScript.HomeDirectory}/Scripts/EQ2BJCommon/UI/MainWindow.xml"
</OnLoad>
```

### Adapted for JB System (Bootstrap):
```iss
function LoadUI()
{
    variable filepath skinPath = "${LavishScript.HomeDirectory}/Interface/Skins/EQ2-Green/EQ2-Green.xml"
    variable filepath miniUIPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMini.xml"
    variable filepath mainUIPath = "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMain.xml"

    ; Load skin
    if ${skinPath.FileExists}
    {
        ui -reload "${skinPath}"
        wait 10

        ; Load UI with skin
        ui -load -skin EQ2-Green "${miniUIPath}"
        wait 20
        ui -load -skin EQ2-Green "${mainUIPath}"
        wait 20
    }
}
```

---

## Color Schemes

### Standard Colors from Examples:

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Green | `FF00FF00` | Active buttons, success, "go" actions |
| Orange | `FFFF9933` | Titles, section headers |
| Yellow | `FFFFFF00` | Status text, warnings |
| Red | `FFFF0000` | Stop button, errors, danger |
| Blue | `FF1a4b61` | Console backgrounds |
| White | `FFFFFFFF` | Default text, inactive buttons |
| Custom Orange | `FFBE5522` | bjmagic status text |

### Application Example:
```xml
<!-- Success/Active -->
<OnLoad>
    UIElement[${JBUI_Start_Button}].Font:SetColor[FF00FF00]
</OnLoad>

<!-- Danger/Stop -->
<OnLoad>
    UIElement[${JBUI_Stop_Button}].Font:SetColor[FFFF0000]
</OnLoad>

<!-- Title -->
<Text name='Title'>
    <Font>
        <Color>FFFF9933</Color>
        <Size>16</Size>
        <Bold>1</Bold>
    </Font>
</Text>

<!-- Status -->
<Text name='Status'>
    <Font>
        <Color>FFFFFF00</Color>
    </Font>
</Text>
```

---

## UI File Organization Patterns

### From Examples (EQ2BJCommon):
```
Scripts/
  eq2bjcommon/
    BJInventory/
      ui/
        BJInventoryMainXML.xml
        BJInventoryMiniXML.xml
      BJInventorySaveLoadSettings.iss
      BJInventoryController.iss
    BJQuestBot/
      UI/
        BJQuestBotMainXML.xml
        BJQuestBotMiniXML.xml
      BJQuestBotController.iss
    bjmagic/
      UI/
        bjmagicXML.xml
      bjmagicSHELL.iss
      bjmagic.iss
```

### Adapted for Eq2JCommon:
```
Scripts/
  Eq2JCommon/
    UI/
      JBMain.xml         (main interface)
      JBMini.xml         (control panel)
      JB_UI_Functions.iss (UI event handlers)
    JB/
      JInstanceRunner.iss
      JNavigation.iss
    JQuestBot/
      JQuestBot.iss
    J_System_Bootstrap.iss (loads everything)
```

---

## Complete Working Example: Mini + Main Window

### Mini Window (Compact Control):
```xml
<Window Name='JB_Mini_Window' Template='Window'>
    <Width>140</Width>
    <Height>180</Height>
    <Visible>1</Visible>
    <Title>JB Control</Title>

    <OnLoad>
        declarevariable JBUI_Mini_Window int global ${This.ID}
        ui -load -skin EQ2-Green "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMain.xml"
    </OnLoad>

    <OnUnLoad>
        ui -unload "${LavishScript.HomeDirectory}/Scripts/Eq2JCommon/UI/JBMain.xml"
    </OnUnLoad>

    <Children>
        <CommandButton Name="ShowMain_Button">
            <Text>Show Main</Text>
            <OnLeftClick>
                UIElement[${JBUI_Main_Window}]:Show
                UIElement[${JBUI_HideMain_Button}]:Show
                This:Hide
            </OnLeftClick>
        </CommandButton>
    </Children>
</Window>
```

### Main Window (Full Interface):
```xml
<Window Name='JB_Main_Window' Template='Window'>
    <Width>1000</Width>
    <Height>650</Height>
    <Visible>0</Visible>
    <Title>JB System - Version ${J_System_Version}</Title>

    <OnLoad>
        declarevariable JBUI_Main_Window int global ${This.ID}
        declarevariable J_System_Version string global "3.0.1"
    </OnLoad>

    <Children>
        <!-- Tabbed interface, controls, etc. -->
    </Children>
</Window>
```

---

## Key Takeaways

1. **Use Templates** for repeated UI elements (buttons, text styles)
2. **Declare Variables** in OnLoad with proper naming conventions
3. **Use Frames** for tab-like interfaces instead of TabControl
4. **OnRender** for dynamic text that updates frequently
5. **QueueCommand** for cross-script communication
6. **Color Consistency** - Green=go, Red=stop, Yellow=status
7. **Developer Mode** flag for runscript vs run
8. **StorePosition** to remember window locations
9. **Skin Loading** pattern: reload skin, then load UI with -skin flag
10. **Mini controls Main** - Mini window loads/unloads main window

---

## Next Steps for Improvements

1. Fix path references (Scripts/JB → Scripts/Eq2JCommon)
2. Update skin name (EQ2BJ → EQ2-Green)
3. Add Templates to JBMain.xml for button consistency
4. Implement OnRender for real-time status updates
5. Add frame-based tab switching for better performance
6. Create consistent color scheme across all UI elements
7. Add developer mode toggle
8. Implement settings persistence (LavishSettings pattern)
