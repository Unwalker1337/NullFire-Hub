-- NullFire Hub | Chapter 0 (Reality) FINAL
-- RE findings: FastForwarded/ReachedHouse/ReachedBed/DoneWithIntro are no-arg fire-and-forget,
-- GameState 0-3 is a client-wait machine, all cutscene locks (Cutscene/HideAllLimbs/ScriptedFOV)
-- are client-set workspace attrs, intro is driven by RealDays.PlaybackSpeed (client settable),
-- teleport CFrame attrs are client-readable, there is NO SprintRemote in this chapter.

local placeId = game.PlaceId
if placeId ~= 108798177610650 then
    warn("NullFire Hub: this script works only in Chapter 0 (Reality). Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub | Chapter 0 (FINAL)',
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
local CollectionService = game:GetService('CollectionService')

-- ========== Greeting ==========
task.spawn(function()
    local sayThing = ReplicatedStorage:FindFirstChild('SayThing')
    if sayThing then
        pcall(function() sayThing:Fire("Thank you for using NullFire hub (FINAL)", {}) end)
        pcall(function() sayThing:FireServer("Thank you for using NullFire hub (FINAL)", {}) end)
    end
end)

-- ========== Helpers ==========
local function say(text, flags)
    local sayThing = ReplicatedStorage:FindFirstChild('SayThing')
    if not sayThing then return end
    pcall(function() sayThing:Fire(text, flags or {}) end)
    pcall(function() sayThing:FireServer(text, flags or {}) end)
end

local function setGameState(state)
    workspace:SetAttribute('GameState', state)
end

local function teleportToAttribute(attrName)
    local cf = workspace:GetAttribute(attrName)
    if cf and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
        return true
    end
    return false
end

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ========== Intro / progression exploits ==========
local function skipIntroFastForward()
    -- client-side waits all poll RealDays.PlaybackSpeed > 1
    local realDays = ReplicatedStorage:FindFirstChild('RealDays')
    if realDays then realDays.PlaybackSpeed = 10 end
    local ff = ReplicatedStorage:FindFirstChild('FastForwarded')
    if ff then ff:FireServer() end
    workspace:SetAttribute('PlayersFastForwarded', #game.Players:GetPlayers())
    print('[NullFire] Intro fast-forwarded (PlaybackSpeed=10)')
end

local function finishIntro()
    skipIntroFastForward()
    task.wait(1)
    local done = ReplicatedStorage:FindFirstChild('DoneWithIntro')
    if done then done:FireServer() end
    workspace:SetAttribute('EveryoneDoneWithIntro', true)
    print('[NullFire] DoneWithIntro fired')
end

local function triggerBedSequence()
    -- zone detection is client-authoritative: ShouldDetect + Inside -> ReachedBed
    local bedZone = workspace:FindFirstChild('SmallerRegionZones') and workspace.SmallerRegionZones:FindFirstChild('BedZone')
    if bedZone then
        bedZone:SetAttribute('ShouldDetect', true)
        task.wait(0.5)
        bedZone:SetAttribute('Inside', true)
    end
    local reachedBed = ReplicatedStorage:FindFirstChild('ReachedBed')
    if reachedBed then reachedBed:FireServer() end
    print('[NullFire] ReachedBed fired (bed sequence)')
end

local function triggerHouseSequence()
    local reachedHouse = ReplicatedStorage:FindFirstChild('ReachedHouse')
    if reachedHouse then reachedHouse:FireServer() end
    print('[NullFire] ReachedHouse fired')
end

local function startPillEnding()
    -- GameState >= 3 drives the pill cutscene client-side
    workspace:SetAttribute('GameState', 3)
    workspace:SetAttribute('Cutscene', true)
    workspace:SetAttribute('HideAllLimbs', true)
    workspace:SetAttribute('ScriptedFOV', true)
    teleportToAttribute('EatingPillsCFrame')
    local pillOST = ReplicatedStorage:FindFirstChild('PillOST')
    if pillOST then pcall(function() pillOST:Play() end) end
    local gui = LocalPlayer.PlayerGui:FindFirstChild('BeginningCutscene')
    if gui and gui.MainFrame and gui.MainFrame:FindFirstChild('LoadingIntoDream') then
        gui.MainFrame.LoadingIntoDream.Visible = true
    end
    print('[NullFire] Pill ending started')
end

local function endChapterFully()
    -- complete the whole chapter in one shot: intro -> bed -> day2 -> pills
    finishIntro()
    task.wait(0.5)
    triggerHouseSequence()
    triggerBedSequence()
    task.wait(1)
    workspace:SetAttribute('GameState', 2)
    task.wait(1)
    startPillEnding()
end

-- ========== Effects ==========
local function setRainVolume(volume)
    local outsideRain = ReplicatedStorage:FindFirstChild('OutsideRain')
    local yourHouseRain = ReplicatedStorage:FindFirstChild('YourHouseRain')
    local blackNoise = ReplicatedStorage:FindFirstChild('BlackNoise')
    if outsideRain then outsideRain.Volume = volume end
    if yourHouseRain then yourHouseRain.Volume = volume end
    if blackNoise and volume == 0 then blackNoise.Volume = 0 end
end

local function disableRain()
    setRainVolume(0)
    for _, name in ipairs({'OutsideRain', 'YourHouseRain', 'BlackNoise'}) do
        local s = ReplicatedStorage:FindFirstChild(name)
        if s then pcall(function() s.Playing = false end) end
    end
    local rainChange = ReplicatedStorage:FindFirstChild('RainChange')
    if rainChange then pcall(function() rainChange:Fire(false) end) end
    print('[NullFire] Rain disabled')
end

local function disableAllPostProcessing()
    local effects = {"DepressionColor", "SleepingColorCorrection", "DarkCorrection", "WakeUpBlur",
                     "CouchBehindDepthOfField", "TeleportBlur", "FallBright", "WarpEffect"}
    for _, name in ipairs(effects) do
        local effect = Lighting:FindFirstChild(name)
        if effect then effect.Enabled = false end
    end
    local atmos = Lighting:FindFirstChild('Atmosphere')
    if atmos then atmos.Density = 0 end
    print('[NullFire] All post-processing disabled')
end

local function listRemotes()
    print("=== Remotes in ReplicatedStorage ===")
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            print(obj.Name, obj.ClassName)
        end
    end
end

-- Door helpers (door opening via OpenDoor remote; doors tagged "Door", prompt named "MainDoor")
local function findDoor()
    local candidates = {
        function()
            local map = workspace:FindFirstChild('Map')
            if map and map:FindFirstChild('YourHouse') then
                return map.YourHouse:FindFirstChild('OutsideDoor')
            end
        end,
        function()
            for _, d in ipairs(CollectionService:GetTagged('Door')) do
                if d:FindFirstChild('MainDoor') then return d end
            end
            return nil
        end
    }
    for _, f in ipairs(candidates) do
        local ok, res = pcall(f)
        if ok and res then return res end
    end
    return nil
end

local function openDoorOnce()
    local door = findDoor()
    local remote = ReplicatedStorage:FindFirstChild('OpenDoor')
    if door and remote then
        remote:FireServer(door)
        print('[NullFire] OpenDoor fired:', door.Name)
    else
        warn('Door or OpenDoor remote not found')
    end
end

-- ========== Tabs ==========
local Tabs = {
    Skip = Window:AddTab('Skip'),
    Teleport = Window:AddTab('Teleport'),
    Effects = Window:AddTab('Effects'),
    Door = Window:AddTab('Door'),
    Misc = Window:AddTab('Misc'),
    Auto = Window:AddTab('Auto'),
    Dev = Window:AddTab('Dev'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ========== 1. SKIP ==========
local skipGroup = Tabs.Skip:AddLeftGroupbox('Skip Intro')
skipGroup:AddButton({ Text = 'Fast-forward intro (PlaybackSpeed=10)', Func = skipIntroFastForward })
skipGroup:AddButton({ Text = 'Finish intro entirely (DoneWithIntro)', Func = finishIntro })
skipGroup:AddButton({ Text = 'Skip to daytime (GameState=2 + Spawn3)', Func = function()
    workspace:SetAttribute('GameState', 2)
    workspace:SetAttribute('Cutscene', nil)
    workspace:SetAttribute('HideAllLimbs', nil)
    workspace:SetAttribute('ScriptedFOV', nil)
    local spawn3 = workspace:FindFirstChild('SpawnLocation3')
    if spawn3 then safeTeleport(spawn3.CFrame + Vector3.new(0, 1, 0)) end
end })
skipGroup:AddButton({ Text = 'Skip ALL cutscenes (clear locks)', Func = function()
    workspace:SetAttribute('Cutscene', nil)
    workspace:SetAttribute('HideAllLimbs', nil)
    workspace:SetAttribute('ScriptedFOV', nil)
    workspace:SetAttribute('NoMotionBlurOverride', nil)
    workspace:SetAttribute('CharacterShudder', nil)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
end })
local speedSlider = skipGroup:AddSlider('RealDaysSpeed', { Text = 'RealDays speed', Default = 1, Min = 0.5, Max = 20, Rounding = 1 })
skipGroup:AddButton({ Text = 'Apply speed', Func = function()
    local realDays = ReplicatedStorage:FindFirstChild('RealDays')
    if realDays then realDays.PlaybackSpeed = speedSlider.Value end
end })

-- ========== 2. TELEPORT ==========
local teleGroup = Tabs.Teleport:AddLeftGroupbox('Teleport to scenes')
local scenes = { 'CerealEaterCFrame', 'CleaningCFrame', 'CouchCFrame', 'SleepingCFrame', 'LastLookCFrame' }
for _, scene in ipairs(scenes) do
    local name = scene:gsub('CFrame', '')
    teleGroup:AddButton({ Text = name, Func = function() teleportToAttribute(scene) end })
end
teleGroup:AddButton({ Text = 'Spawn 2', Func = function()
    local spawn = workspace:FindFirstChild('SpawnLocation2')
    if spawn then safeTeleport(spawn.CFrame) end
end })
teleGroup:AddButton({ Text = 'Spawn 3', Func = function()
    local spawn = workspace:FindFirstChild('SpawnLocation3')
    if spawn then safeTeleport(spawn.CFrame + Vector3.new(0, 1, 0)) end
end })
teleGroup:AddButton({ Text = 'Bed', Func = function()
    local bed = workspace:FindFirstChild('SmallerRegionZones') and workspace.SmallerRegionZones:FindFirstChild('BedZone')
    if bed and bed:FindFirstChild('Part') then
        safeTeleport(bed.Part.CFrame * CFrame.new(0, 2, 0))
    end
end })
teleGroup:AddButton({ Text = 'Door', Func = function()
    local door = findDoor()
    if door then safeTeleport(door.CFrame * CFrame.new(0, 1, 2)) end
end })
teleGroup:AddButton({ Text = 'Package', Func = function()
    local package = workspace:FindFirstChild('CardboardBoxClosed') or workspace:FindFirstChild('CardboardBoxOpen')
    if package then safeTeleport(package.CFrame * CFrame.new(0, 1, 1.5)) end
end })
teleGroup:AddButton({ Text = 'Pill scene (EatingPillsCFrame)', Func = function() teleportToAttribute('EatingPillsCFrame') end })
teleGroup:AddButton({ Text = 'Package scene root', Func = function() teleportToAttribute('PackageSceneRootHolder') end })

-- ========== 3. EFFECTS ==========
local effectsGroup = Tabs.Effects:AddLeftGroupbox('Visual Effects')
local effectToggles = {
    {'DepressionColor', 'DepressionColor'},
    {'SleepingCorrection', 'SleepingColorCorrection'},
    {'DarkCorrection', 'DarkCorrection'},
    {'WakeUpBlur', 'WakeUpBlur'},
    {'CouchDOF', 'CouchBehindDepthOfField'},
    {'TeleportBlur', 'TeleportBlur'}
}
for _, pair in ipairs(effectToggles) do
    local id, name = pair[1], pair[2]
    effectsGroup:AddToggle(id, { Text = 'Disable ' .. name, Default = false }):OnChanged(function(v)
        local e = Lighting:FindFirstChild(name)
        if e then e.Enabled = not v end
    end)
end
effectsGroup:AddToggle('DisableWaterRipples', { Text = 'Disable water ripples', Default = false }):OnChanged(function(v)
    local gui = LocalPlayer.PlayerGui:FindFirstChild('ScreenEffectGui')
    if gui and gui:FindFirstChild('WaterFrame') then
        gui.WaterFrame.Visible = not v
    end
end)
effectsGroup:AddSlider('OutsideRainVolume', { Text = 'OutsideRain volume', Default = 1, Min = 0, Max = 5, Rounding = 2 }):OnChanged(function(v)
    local r = ReplicatedStorage:FindFirstChild('OutsideRain')
    if r then r.Volume = v end
end)
effectsGroup:AddSlider('YourHouseRainVolume', { Text = 'YourHouseRain volume', Default = 1, Min = 0, Max = 8, Rounding = 2 }):OnChanged(function(v)
    local r = ReplicatedStorage:FindFirstChild('YourHouseRain')
    if r then r.Volume = v end
end)
effectsGroup:AddSlider('AtmosDensity', { Text = 'Atmosphere density', Default = 0.3, Min = 0, Max = 1, Rounding = 2 }):OnChanged(function(v)
    local a = Lighting:FindFirstChild('Atmosphere')
    if a then a.Density = v end
end)
effectsGroup:AddSlider('FogStart', { Text = 'FogStart', Default = -1, Min = -1, Max = 5000, Rounding = 0 }):OnChanged(function(v)
    if v >= 0 then Lighting.FogStart = v end
end)
effectsGroup:AddSlider('FogEnd', { Text = 'FogEnd', Default = -1, Min = -1, Max = 10000, Rounding = 0 }):OnChanged(function(v)
    if v >= 0 then Lighting.FogEnd = v end
end)
effectsGroup:AddButton({ Text = 'Disable ALL post-processing', Func = disableAllPostProcessing })
effectsGroup:AddButton({ Text = 'Disable rain completely', Func = disableRain })
effectsGroup:AddButton({ Text = 'Set time to night (0)', Func = function() Lighting.ClockTime = 0 end })
effectsGroup:AddButton({ Text = 'Set time to day (12)', Func = function() Lighting.ClockTime = 12 end })
effectsGroup:AddButton({ Text = 'Set time to 15 (day 2)', Func = function() Lighting.ClockTime = 15 end })

-- ========== 4. DOOR ==========
local doorGroup = Tabs.Door:AddLeftGroupbox('Door Opening')
doorGroup:AddButton({ Text = 'Open door (once)', Func = openDoorOnce })
doorGroup:AddButton({ Text = 'Unlock ALL tagged doors', Func = function()
    for _, d in ipairs(CollectionService:GetTagged('Door')) do
        d:SetAttribute('Locked', nil)
        d:SetAttribute('DoorOpenBinded', nil)
    end
    print('[NullFire] All doors unlocked client-side')
end })
local doorRemote = ReplicatedStorage:FindFirstChild('OpenDoor')
local doorSpamConn = nil
local function startDoorSpam(delay)
    if doorSpamConn then return end
    doorSpamConn = RunService.Heartbeat:Connect(function()
        local door = findDoor()
        if doorRemote and door then
            doorRemote:FireServer(door)
            task.wait(delay)
        end
    end)
end
local function stopDoorSpam()
    if doorSpamConn then
        doorSpamConn:Disconnect()
        doorSpamConn = nil
    end
end
local autoDoor = doorGroup:AddToggle('AutoDoorSpam', { Text = 'Spam door', Default = false })
local doorDelay = doorGroup:AddSlider('DoorSpamDelay', { Text = 'Delay', Default = 0.1, Min = 0.01, Max = 1, Rounding = 2 })
autoDoor:OnChanged(function(v)
    if v then startDoorSpam(doorDelay.Value) else stopDoorSpam() end
end)
doorDelay:OnChanged(function()
    if autoDoor.Value then
        stopDoorSpam()
        startDoorSpam(doorDelay.Value)
    end
end)

-- ========== 5. MISC ==========
local miscGroup = Tabs.Misc:AddLeftGroupbox('Misc')
miscGroup:AddButton({ Text = 'Activate bed (zone detection)', Func = triggerBedSequence })
miscGroup:AddButton({ Text = 'ReachedHouse', Func = triggerHouseSequence })
miscGroup:AddButton({ Text = 'Show wall scratches', Func = function()
    for _, s in ipairs(CollectionService:GetTagged('WallScratch')) do
        local d = s:FindFirstChild('Decal')
        if d then d.Transparency = 0 end
    end
end })
miscGroup:AddButton({ Text = 'Force PC mode', Func = function()
    LocalPlayer:SetAttribute('device', 'pc')
end })
miscGroup:AddButton({ Text = 'Reset camera', Func = function()
    local resetCam = ReplicatedStorage:FindFirstChild('ResetCamera')
    if resetCam then pcall(function() resetCam:Fire() end) end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
end })

-- Custom SayThing
local textInput = miscGroup:AddInput('CustomText', { Text = 'Text', Default = 'Hello', Numeric = false, Finished = true })
local styleDrop = miscGroup:AddDropdown('TextStyle', {
    Values = { 'Normal', 'Red', 'Weird', 'Fast', 'Static', 'Big', 'Scared', 'Yellow', 'Green', 'StayForever', 'Objective', 'InfoText' },
    Default = 1,
    Text = 'Style'
})
miscGroup:AddButton({ Text = 'Send text', Func = function()
    local styleMap = {
        ['Normal'] = {}, ['Red'] = {'RedText'}, ['Weird'] = {'WeirdcoreText'},
        ['Fast'] = {'FasterText'}, ['Static'] = {'static'}, ['Big'] = {'big'},
        ['Scared'] = {'scared'}, ['Yellow'] = {'YellowText'}, ['Green'] = {'GreenText'},
        ['StayForever'] = {'stayforever'}, ['Objective'] = {'Objective'}, ['InfoText'] = {'InfoText'}
    }
    say(textInput.Value, styleMap[styleDrop.Value] or {})
end })

-- ========== 6. AUTO ==========
local autoGroup = Tabs.Auto:AddLeftGroupbox('Automation')
autoGroup:AddButton({ Text = 'COMPLETE CHAPTER (full chain)', Func = endChapterFully })
autoGroup:AddButton({ Text = 'Start pill ending (GameState 3)', Func = startPillEnding })
autoGroup:AddButton({ Text = 'Force GameState to 3', Func = function() setGameState(3) end })
autoGroup:AddButton({ Text = 'Force GameState to 2', Func = function() setGameState(2) end })
autoGroup:AddButton({ Text = 'Force GameState to 1', Func = function() setGameState(1) end })
autoGroup:AddButton({ Text = 'Force GameState to 0', Func = function() setGameState(0) end })

-- ========== 7. DEV ==========
local devGroup = Tabs.Dev:AddLeftGroupbox('Developer Tools')
devGroup:AddButton({ Text = 'List all Remotes/Bindables', Func = listRemotes })
devGroup:AddInput('ForceGameStateInput', { Text = 'Set GameState (0-3)', Default = '0', Numeric = true, Finished = true }):OnChanged(function(v)
    setGameState(tonumber(v))
end)
devGroup:AddButton({ Text = 'Dump workspace attributes', Func = function()
    for k, v in pairs(workspace:GetAttributes()) do
        print(k, tostring(v))
    end
end })

-- ========== UI Settings ==========
local uiGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
uiGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
uiGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFireHub_Chapter0_FINAL')
SaveManager:SetFolder('NullFireHub_Chapter0_FINAL')
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
    Library:SetWatermark(('NullFire Ch0 FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

Library:OnUnload(function()
    stopDoorSpam()
end)

print('[NullFire] Chapter 0 FINAL loaded. PlaceId:', placeId)
