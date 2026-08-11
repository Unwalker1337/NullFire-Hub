-- NullFire Cloud Theatre | FINAL
-- Based on the shared A Broken Dream client stack: SayThing is client-firable,
-- DidComputer(computer) / TrainCall(station) / UpdateOnTrain(bool) are FireServer,
-- chapter state is CurrentZone + FirstTowerComputers (NO GameState attr in this chapter),
-- walls are client-side visuals, WindShake module is client-side and pausable,
-- DreadPeak finale chaser is client-simulated (MoveTo Dread1->Dread2).

local placeId = game.PlaceId
if placeId ~= 74323372320017 then
    warn("NullFire Hub: this script works only in Cloud Theater. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
if not Library then
    warn("Failed to load LinoriaLib. Check your internet connection.")
    return
end
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Cloud Theatre FINAL',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- ========== Greeting ==========
task.spawn(function()
    local sayThing = game:GetService("ReplicatedStorage"):FindFirstChild("SayThing")
    if sayThing then
        pcall(function() sayThing:Fire("Thank you for using NullFire hub", {}) end)
        pcall(function() sayThing:FireServer("Thank you for using NullFire hub", {}) end)
    end
end)

repeat task.wait() until workspace:GetAttribute("ClientLoadedIn") or #workspace:GetChildren() > 5

local LocalPlayer = game.Players.LocalPlayer
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')

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

local function setGameState(state)
    workspace:SetAttribute('GameState', state)
end

local function teleportToCFrame(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ========== Tabs ==========
local Tabs = {
    Progress = Window:AddTab('Progress'),
    Train = Window:AddTab('Train'),
    Towers = Window:AddTab('Towers'),
    Visual = Window:AddTab('Visuals'),
    Exploit = Window:AddTab('Cheats'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ==================== 1. PROGRESS ====================
local progGroup = Tabs.Progress:AddLeftGroupbox('Chapter Control')

local zones = {"FirstTowerZone", "SecondTowerZone", "ThirdTowerZone", "TrainZone"}
local zoneDrop = progGroup:AddDropdown('CurrentZone', { Values = zones, Default = 1, Text = 'Current zone' })
zoneDrop:OnChanged(function(v) workspace:SetAttribute('CurrentZone', v) end)

progGroup:AddSlider('FirstTowerComputers', { Text = 'FirstTowerComputers (0 = done)', Default = 2, Min = 0, Max = 10, Rounding = 0 }):OnChanged(function(v)
    workspace:SetAttribute('FirstTowerComputers', v)
end)
progGroup:AddSlider('SecondTowerComputers', { Text = 'SecondTowerComputers', Default = 2, Min = 0, Max = 10, Rounding = 0 }):OnChanged(function(v)
    workspace:SetAttribute('SecondTowerComputers', v)
end)
progGroup:AddSlider('ThirdTowerComputers', { Text = 'ThirdTowerComputers', Default = 2, Min = 0, Max = 10, Rounding = 0 }):OnChanged(function(v)
    workspace:SetAttribute('ThirdTowerComputers', v)
end)

progGroup:AddButton({ Text = 'Reset FirstTower computers', Func = function()
    workspace:SetAttribute('FirstTowerComputers', 0)
end })
progGroup:AddButton({ Text = 'Reset SecondTower computers', Func = function()
    workspace:SetAttribute('SecondTowerComputers', 0)
end })
progGroup:AddButton({ Text = 'Reset ThirdTower computers', Func = function()
    workspace:SetAttribute('ThirdTowerComputers', 0)
end })
progGroup:AddButton({ Text = 'Open passages (FirstWall)', Func = function()
    local wall = workspace.DreamChangers:FindFirstChild('FirstWall')
    if wall then
        wall.Transparency = 1
        wall.CanCollide = false
    end
    local wall2 = workspace.DreamChangers:FindFirstChild('FirstWall2')
    if wall2 then
        wall2.Transparency = 0
        wall2.CanCollide = true
    end
end })
progGroup:AddButton({ Text = 'Open ALL walls (hideWall spam)', Func = function()
    for _, obj in ipairs(workspace.DreamChangers:GetChildren()) do
        for _, part in ipairs(obj:GetDescendants()) do
            if part:IsA('BasePart') then
                part.Transparency = 1
                part.CanCollide = false
                part.CanQuery = false
            end
        end
        if obj:IsA('BasePart') then
            obj.Transparency = 1
            obj.CanCollide = false
            obj.CanQuery = false
        end
    end
    for _, name in ipairs({'FirstWall', 'FirstWall2', 'SecondWall', 'ThirdWall', 'ThirdTowerWall', 'FirstTowerOut'}) do
        local w = workspace.DreamChangers:FindFirstChild(name)
        if w then
            w.Transparency = 1
            w.CanCollide = false
            w.CanQuery = false
        end
    end
    print('[Progress] All walls opened (client-side)')
end })
progGroup:AddToggle('DisableCutscenes', { Text = 'Disable cutscenes', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', nil)
        workspace:SetAttribute('HideAllLimbs', nil)
        workspace:SetAttribute('ScriptedFOV', nil)
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if root then root.Anchored = false end
        end
    end
end)

-- ==================== 2. TRAIN ====================
local trainGroup = Tabs.Train:AddLeftGroupbox('SkyTrain Control')
local train = workspace:FindFirstChild('SkyTrain')

trainGroup:AddButton({ Text = 'Call train (nearest stop)', Func = function()
    fire('TrainCall', "NextExit")
end })
trainGroup:AddButton({ Text = 'Call train "NextExit"', Func = function()
    fire('TrainCall', "NextExit")
end })
trainGroup:AddButton({ Text = 'UpdateOnTrain(true)', Func = function()
    fire('UpdateOnTrain', true)
end })
trainGroup:AddButton({ Text = 'UpdateOnTrain(false)', Func = function()
    fire('UpdateOnTrain', false)
end })

local controllers = {}
if workspace:FindFirstChild('TrainControllers') then
    for _, c in ipairs(workspace.TrainControllers:GetChildren()) do
        if c:IsA('Model') then
            local name = c.Name:gsub('TrainController', '')
            if name ~= '' then
                table.insert(controllers, name)
            end
        end
    end
end
if #controllers > 0 then
    local controllerDrop = trainGroup:AddDropdown('TrainControllerSelect', { Values = controllers, Default = 1, Text = 'Controller #' })
    trainGroup:AddButton({ Text = 'Call train to selected controller', Func = function()
        fire('TrainCall', controllerDrop.Value)
    end })
    trainGroup:AddButton({ Text = 'Teleport to selected controller', Func = function()
        local tc = workspace:FindFirstChild('TrainControllers')
        if tc then
            for _, c in ipairs(tc:GetChildren()) do
                if c.Name:gsub('TrainController', '') == controllerDrop.Value then
                    teleportToCFrame(c.CFrame * CFrame.new(0, 2, 0))
                    break
                end
            end
        end
    end })
end

trainGroup:AddButton({ Text = 'Teleport inside train', Func = function()
    if train then teleportToCFrame(train.MainHull.CFrame + Vector3.new(0, 2, 0)) end
end })
trainGroup:AddButton({ Text = 'Teleport to train roof', Func = function()
    if train then teleportToCFrame(train.MainHull.CFrame + Vector3.new(0, 5, 0)) end
end })
trainGroup:AddToggle('TrainMovinEffect', { Text = 'Train movement effect', Default = false }):OnChanged(function(v)
    local ev = ReplicatedStorage:FindFirstChild('TrainMovinEffect')
    if ev then
        if v then ev:FireServer(true) else ev:FireServer(false) end
    end
end)

-- ==================== 3. TOWERS ====================
local towerGroup = Tabs.Towers:AddLeftGroupbox('Hacking towers')
towerGroup:AddButton({ Text = 'Complete ALL computers in current tower', Func = function()
    local zone = workspace:GetAttribute('CurrentZone')
    if zone == 'FirstTowerZone' or zone == 'SecondTowerZone' or zone == 'ThirdTowerZone' then
        local computers = workspace:FindFirstChild('Computers')
        if computers then
            for _, comp in ipairs(computers:GetChildren()) do
                fire('DidComputer', comp)
                task.wait(0.05)
            end
        end
    end
end })
towerGroup:AddButton({ Text = 'Complete ALL computers (all towers)', Func = function()
    local computers = workspace:FindFirstChild('Computers')
    if computers then
        for _, comp in ipairs(computers:GetChildren()) do
            fire('DidComputer', comp)
            task.wait(0.05)
        end
    end
end })
towerGroup:AddButton({ Text = 'Teleport to first computer', Func = function()
    local computers = workspace:FindFirstChild('Computers')
    if computers and computers:FindFirstChildOfClass('BasePart') then
        teleportToCFrame(computers:FindFirstChildOfClass('BasePart').CFrame * CFrame.new(0, 2, 0))
    end
end })
towerGroup:AddToggle('DisableTowerWalls', { Text = 'Make tower walls transparent', Default = false }):OnChanged(function(v)
    for _, obj in ipairs(workspace.DreamChangers:GetChildren()) do
        if obj:GetAttribute('TowerIn') then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.Transparency = v and 1 or 0
                    part.CanCollide = not v
                end
            end
        end
    end
end)

towerGroup:AddButton({ Text = 'Teleport to FirstTower', Func = function()
    local entrance = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('FirstTowerEntrance')
    if entrance then teleportToCFrame(entrance.CFrame) end
end })
towerGroup:AddButton({ Text = 'Teleport to SecondTower', Func = function()
    local entrance = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('SecondTowerEntrance')
    if entrance then teleportToCFrame(entrance.CFrame) end
end })
towerGroup:AddButton({ Text = 'Teleport to ThirdTower', Func = function()
    local entrance = workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('ThirdTowerEntrance')
    if entrance then teleportToCFrame(entrance.CFrame) end
end })

-- ==================== 4. VISUALS ====================
local visGroup = Tabs.Visual:AddLeftGroupbox('Effects & Lighting')
local noFog = visGroup:AddToggle('NoFog', { Text = 'Remove fog', Default = false })
local fullbright = visGroup:AddToggle('Fullbright', { Text = 'Fullbright', Default = false })
local origFogS, origFogE, origFogC = Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor
noFog:OnChanged(function(v)
    if v then Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = 999999, 999999, Color3.new(0,0,0)
    else Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = origFogS, origFogE, origFogC end
end)
local origBright, origAmb, origOut = Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient
fullbright:OnChanged(function(v)
    if v then
        Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = 2, Color3.new(1,1,1), Color3.new(1,1,1), false
    else
        Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = origBright, origAmb, origOut, true
    end
end)
visGroup:AddSlider('SkyboxRotation', { Text = 'Skybox rotation', Default = 0, Min = 0, Max = 360, Rounding = 0 }):OnChanged(function(v)
    local skybox = Lighting:FindFirstChild('Skybox')
    if skybox then skybox.SkyboxOrientation = Vector3.new(0, v, 0) end
end)
visGroup:AddSlider('MotionBlur', { Text = 'Motion blur', Default = 0, Min = 0, Max = 20, Rounding = 1 }):OnChanged(function(v)
    local blur = Lighting:FindFirstChild('MotionBlur')
    if blur then blur.Size = v end
end)
visGroup:AddToggle('DarkCorrection', { Text = 'Disable DarkCorrection', Default = false }):OnChanged(function(v)
    local dc = Lighting:FindFirstChild('DarkCorrection')
    if dc then dc.Enabled = not v end
end)

-- ========== Wind (WindShake module is client-side) ==========
local windGroup = Tabs.Visual:AddRightGroupbox('Wind & Ambience')
local windToggle = windGroup:AddToggle('DisableWindShake', { Text = 'Disable wind shake (Pause)', Default = false })
local windShakeModule = ReplicatedStorage:FindFirstChild('WindShake')
windToggle:OnChanged(function(v)
    if not windShakeModule then return end
    local ok, mod = pcall(require, windShakeModule)
    if not ok or type(mod) ~= 'table' then return end
    if v then
        pcall(function() mod:Pause() end)
        windShakeModule:SetAttribute('WindPower', 0)
        windShakeModule:SetAttribute('WindSpeed', 0)
    else
        pcall(function() mod:Resume() end)
        windShakeModule:SetAttribute('WindPower', 0.5)
        windShakeModule:SetAttribute('WindSpeed', 20)
    end
end)
windGroup:AddButton({ Text = 'Kill wind ambience', Func = function()
    local wa = ReplicatedStorage:FindFirstChild('WindAmbience')
    if wa then
        wa.Volume = 0
        wa.Playing = false
    end
end })
windGroup:AddSlider('WindAmbienceVolume', { Text = 'WindAmbience volume', Default = 1, Min = 0, Max = 3, Rounding = 2 }):OnChanged(function(v)
    local wa = ReplicatedStorage:FindFirstChild('WindAmbience')
    if wa then wa.Volume = v end
end)
windGroup:AddSlider('TrainAmbienceVolume', { Text = 'TrainAmbience volume', Default = 1, Min = 0, Max = 3, Rounding = 2 }):OnChanged(function(v)
    local st = workspace:FindFirstChild('SkyTrain')
    local sh = st and st:FindFirstChild('ShadowPart')
    local ta = sh and sh:FindFirstChild('TrainAmbience')
    if ta then ta.Volume = v end
end)
windGroup:AddSlider('AirConditionerVolume', { Text = 'AirConditioner volume', Default = 1, Min = 0, Max = 3, Rounding = 2 }):OnChanged(function(v)
    local ac = ReplicatedStorage:FindFirstChild('AirConditioner')
    if ac then ac.Volume = v end
end)
windGroup:AddSlider('Zone1SoundVolume', { Text = 'Zone1Sound volume', Default = 1, Min = 0, Max = 3, Rounding = 2 }):OnChanged(function(v)
    local z1 = ReplicatedStorage:FindFirstChild('Zone1Sound')
    if z1 then z1.Volume = v end
end)

-- ==================== 5. CHEATS ====================
local cheatGroup = Tabs.Exploit:AddLeftGroupbox('Speed, noclip, auto')
local speedSlider = cheatGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Default = 16, Min = 0, Max = 250, Rounding = 1 })
local jumpSlider = cheatGroup:AddSlider('JumpPower', { Text = 'JumpPower', Default = 50, Min = 0, Max = 200, Rounding = 1 })
local function updateMove()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild('Humanoid') then
        c.Humanoid.WalkSpeed = speedSlider.Value
        c.Humanoid.JumpPower = jumpSlider.Value
    end
end
speedSlider:OnChanged(updateMove)
jumpSlider:OnChanged(updateMove)
LocalPlayer.CharacterAdded:Connect(function(c) c:WaitForChild('Humanoid'); updateMove() end)

local noclipToggle = cheatGroup:AddToggle('Noclip', { Text = 'Noclip', Default = false })
local noclipConn = nil
local function noclipLoop()
    if not noclipToggle.Value then return end
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA('BasePart') and p.CanCollide then p.CanCollide = false end
    end
end
noclipToggle:OnChanged(function(v)
    if v then
        if not noclipConn then noclipConn = RunService.Stepped:Connect(noclipLoop) end
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = LocalPlayer.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA('BasePart') then p.CanCollide = true end
            end
        end
    end
end)

local autoSprint = cheatGroup:AddToggle('AutoSprint', { Text = 'AutoSprint', Default = false })
local sprintRemote = ReplicatedStorage:FindFirstChild('SprintRemote')
local sprintConn = nil
local function startSprint()
    if sprintConn then return end
    sprintConn = RunService.Heartbeat:Connect(function()
        if autoSprint.Value and sprintRemote then
            sprintRemote:FireServer(false)
            task.wait(0.05)
        end
    end)
end
local function stopSprint()
    if sprintConn then sprintConn:Disconnect(); sprintConn = nil end
end
autoSprint:OnChanged(function(v) if v then startSprint() else stopSprint() end end)

local autoDial = cheatGroup:AddToggle('AutoDialogue', { Text = 'AutoDialogue', Default = false })
local dialDelay = cheatGroup:AddSlider('DialogueDelay', { Text = 'Delay', Default = 0.1, Min = 0.01, Max = 1, Rounding = 2 })
local dialRemote = ReplicatedStorage:FindFirstChild('DialogueMoveOn')
local dialConn = nil
local function startDial()
    if dialConn then return end
    dialConn = RunService.Heartbeat:Connect(function()
        if autoDial.Value and dialRemote then
            pcall(function() dialRemote:FireServer() end)
            task.wait(dialDelay.Value)
        end
    end)
end
local function stopDial()
    if dialConn then dialConn:Disconnect(); dialConn = nil end
end
autoDial:OnChanged(function(v) if v then startDial() else stopDial() end end)
dialDelay:OnChanged(function() if autoDial.Value then stopDial(); startDial() end end)

cheatGroup:AddButton({ Text = 'Delete DreadPeak', Func = function()
    local dp = workspace:FindFirstChild('DreadPeak')
    if dp then dp:Destroy() end
end })
cheatGroup:AddButton({ Text = 'Freeze DreadPeak (anchor)', Func = function()
    local dp = workspace:FindFirstChild('DreadPeak')
    if dp and dp:FindFirstChild('HumanoidRootPart') then
        dp.HumanoidRootPart.Anchored = true
    end
    local rsDp = ReplicatedStorage:FindFirstChild('DreadPeak')
    if rsDp and rsDp:FindFirstChild('HumanoidRootPart') then
        rsDp.HumanoidRootPart.Anchored = true
    end
    print('[Cheats] DreadPeak anchored')
end })
cheatGroup:AddButton({ Text = 'Teleport to DreadPeak', Func = function()
    local dp = workspace:FindFirstChild('DreadPeak')
    if dp and dp:FindFirstChild('HumanoidRootPart') then
        teleportToCFrame(dp.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
    end
end })

-- ==================== 6. MISC ====================
local miscGroup = Tabs.Misc:AddLeftGroupbox('SayThing & tools')
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

-- ==================== 7. UI SETTINGS ====================
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFire_CloudTheatre_FINAL')
SaveManager:SetFolder('NullFire_CloudTheatre_FINAL')
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
    Library:SetWatermark(('NullFire Cloud FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

-- Cleanup
Library:OnUnload(function()
    stopDial(); stopSprint()
    if noclipConn then noclipConn:Disconnect() end
    if fullbright.Value then fullbright:SetValue(false) end
    if noFog.Value then noFog:SetValue(false) end
end)

print('NullFire Cloud Theatre FINAL loaded')
