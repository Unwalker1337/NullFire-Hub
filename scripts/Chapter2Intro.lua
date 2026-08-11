-- NullFire Hub | Chapter 2 Introduction FINAL
-- RE findings: pure cutscene chapter. ALL waits break on the client-writable
-- workspace attr "FastForwardSuccessful". FastForwarded and DoneWithCutscene
-- are no-arg FireServer remotes. SayThing is client-firable.

local placeId = game.PlaceId
if placeId ~= 109245555679847 then
    warn("NullFire Hub: this script works only in Chapter 2 Introduction. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub | Chapter 2 Intro (FINAL)',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

repeat task.wait() until workspace:GetAttribute("ClientLoadedIn") or #workspace:GetChildren() > 5

local LocalPlayer = game.Players.LocalPlayer
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- ========== Greeting ==========
task.spawn(function()
    local sayThing = ReplicatedStorage:FindFirstChild('SayThing')
    if sayThing then
        pcall(function() sayThing:Fire("Thank you for using NullFire hub", {}) end)
        pcall(function() sayThing:FireServer("Thank you for using NullFire hub", {}) end)
    end
end)

-- ========== Helpers ==========
local function say(text, flags)
    local sayThing = ReplicatedStorage:FindFirstChild('SayThing')
    if not sayThing then return end
    pcall(function() sayThing:Fire(text, flags or {}) end)
    pcall(function() sayThing:FireServer(text, flags or {}) end)
end

local function fire(remoteName, ...)
    local r = ReplicatedStorage:FindFirstChild(remoteName)
    if not r then return false end
    if r:IsA('RemoteEvent') then
        pcall(r.FireServer, r, ...)
    else
        pcall(r.Fire, r, ...)
    end
    return true
end

-- ========== Tabs ==========
local Tabs = {
    Skip = Window:AddTab('Skip'),
    Dialogue = Window:AddTab('Dialogue'),
    Visual = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ========== 1. SKIP ==========
local skipGroup = Tabs.Skip:AddLeftGroupbox('Cutscene skip')

skipGroup:AddButton({ Text = 'SKIP ENTIRE INTRO (FastForwardSuccessful)', Func = function()
    -- the client sets this itself; every improvedWait + video gate aborts on it
    workspace:SetAttribute('FastForwardSuccessful', true)
    local ff = ReplicatedStorage:FindFirstChild('FastForwarded')
    if ff then ff:FireServer() end
    workspace:SetAttribute('PlayersFastForwarded', #game.Players:GetPlayers())
    print('[Skip] FastForwardSuccessful=true - all waits aborted')
end })

skipGroup:AddButton({ Text = 'FastForward vote (FastForwarded)', Func = function()
    fire('FastForwarded')
end })

skipGroup:AddButton({ Text = 'Finish cutscene (DoneWithCutscene)', Func = function()
    fire('DoneWithCutscene')
end })

skipGroup:AddButton({ Text = 'Force EveryoneDoneWithCutscene', Func = function()
    workspace:SetAttribute('EveryoneDoneWithCutscene', true)
end })

skipGroup:AddButton({ Text = 'Complete + show LoadingIntoDream', Func = function()
    workspace:SetAttribute('FastForwardSuccessful', true)
    fire('DoneWithCutscene')
    task.wait(0.5)
    workspace:SetAttribute('EveryoneDoneWithCutscene', true)
    local gui = LocalPlayer.PlayerGui:FindFirstChild('BeginningCutscene')
    if gui and gui.MainFrame and gui.MainFrame:FindFirstChild('LoadingIntoDream') then
        gui.MainFrame.LoadingIntoDream.Visible = true
    end
    print('[Skip] Intro completed - transition shown')
end })

skipGroup:AddToggle('CutsceneUnlock', { Text = 'Keep control (clear locks)', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', nil)
        workspace:SetAttribute('HideAllLimbs', nil)
        workspace:SetAttribute('ScriptedFOV', nil)
        workspace:SetAttribute('NoMotionBlurOverride', nil)
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if root then root.Anchored = false end
        end
    end
end)

-- ========== 2. DIALOGUE ==========
local dialGroup = Tabs.Dialogue:AddLeftGroupbox('SayThing')
local textInput = dialGroup:AddInput('CustomText', { Text = 'Text', Default = 'Hello', Numeric = false, Finished = true })
local styleDrop = dialGroup:AddDropdown('TextStyle', {
    Values = { 'Normal', 'Red', 'Weird', 'Fast', 'Static', 'Big', 'Scared', 'Yellow', 'Green', 'StayForever', 'Objective', 'InfoText' },
    Default = 1,
    Text = 'Style'
})
dialGroup:AddButton({ Text = 'Send text', Func = function()
    local styleMap = {
        ['Normal'] = {}, ['Red'] = {'RedText'}, ['Weird'] = {'WeirdcoreText'},
        ['Fast'] = {'FasterText'}, ['Static'] = {'static'}, ['Big'] = {'big'},
        ['Scared'] = {'scared'}, ['Yellow'] = {'YellowText'}, ['Green'] = {'GreenText'},
        ['StayForever'] = {'stayforever'}, ['Objective'] = {'Objective'}, ['InfoText'] = {'InfoText'}
    }
    say(textInput.Value, styleMap[styleDrop.Value] or {})
end })
dialGroup:AddButton({ Text = 'Replay intro line 1', Func = function()
    say("Don't bring me back there...", {})
end })
dialGroup:AddButton({ Text = 'Replay intro line 2', Func = function()
    say("I-!pause!I need to think of something happy to escape from the nightmares...", {})
end })
dialGroup:AddButton({ Text = 'Clear dialogue (empty)', Func = function()
    say("", {})
end })

-- ========== 3. VISUALS ==========
local visGroup = Tabs.Visual:AddLeftGroupbox('Effects')
local effectToggles = {
    {'DarkCorrection', 'DarkCorrection'},
    {'DepressionColor', 'DepressionColor'},
    {'WakeUpBlur', 'WakeUpBlur'},
    {'TeleportBlur', 'TeleportBlur'}
}
for _, pair in ipairs(effectToggles) do
    local id, name = pair[1], pair[2]
    visGroup:AddToggle(id, { Text = 'Disable ' .. name, Default = false }):OnChanged(function(v)
        local e = Lighting:FindFirstChild(name)
        if e then e.Enabled = not v end
    end)
end
visGroup:AddSlider('ClockTime', { Text = 'ClockTime', Default = 12, Min = 0, Max = 24, Rounding = 0 }):OnChanged(function(v)
    Lighting.ClockTime = v
end)
visGroup:AddSlider('AtmosDensity', { Text = 'Atmosphere density', Default = 0.3, Min = 0, Max = 1, Rounding = 2 }):OnChanged(function(v)
    local a = Lighting:FindFirstChild('Atmosphere')
    if a then a.Density = v end
end)
visGroup:AddButton({ Text = 'Brighten (Fullbright)', Func = function()
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.GlobalShadows = false
end })
visGroup:AddButton({ Text = 'Restore default lighting', Func = function()
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
    Lighting.OutdoorAmbient = Color3.new(0.8, 0.8, 0.8)
    Lighting.GlobalShadows = true
end })

-- ========== 4. MISC ==========
local miscGroup = Tabs.Misc:AddLeftGroupbox('Misc')
miscGroup:AddButton({ Text = 'Force PC mode', Func = function()
    LocalPlayer:SetAttribute('device', 'pc')
end })
miscGroup:AddButton({ Text = 'List all Remotes/Bindables', Func = function()
    print("=== Remotes in ReplicatedStorage ===")
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            print(obj.Name, obj.ClassName)
        end
    end
end })
miscGroup:AddButton({ Text = 'Dump workspace attributes', Func = function()
    for k, v in pairs(workspace:GetAttributes()) do
        print(k, tostring(v))
    end
end })

-- ========== UI Settings ==========
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFire_Ch2Intro_FINAL')
SaveManager:SetFolder('NullFire_Ch2Intro_FINAL')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

-- Watermark
Library:SetWatermarkVisibility(true)
local ft, fc, fps = tick(), 0, 60
RunService.RenderStepped:Connect(function()
    fc = fc + 1
    if tick() - ft >= 1 then
        fps = fc
        ft, fc = tick(), 0
    end
    Library:SetWatermark(('NullFire Ch2Intro FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

print('[NullFire] Chapter 2 Introduction FINAL loaded. PlaceId:', placeId)
