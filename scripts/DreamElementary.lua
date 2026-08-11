-- NullFire Dream Elementary | FINAL
-- RE findings: the game has its own native "CheatMode" workspace flag (10x clock hands, instant
-- voicelines), clock completion is client-fireable (FinishedClock(clock) when hands match
-- NextClockHour/Minutes), the clock UI/hand math is fully client-side, ShadowFriend spawn/kill
-- is 100% client-side (workspace.Cutscene=true blocks the Touched kill), UntrustedAdult vision
-- report is client-fired (SeesUntrusted), GameState 0-11 drives everything.

local placeId = game.PlaceId
if placeId ~= 77782724453274 then
    warn("NullFire Hub: this script works only in Dream Elementary. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Dream Elementary FINAL',
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

local function setCurrentZone(zone)
    workspace:SetAttribute('CurrentZone', zone)
end

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

local function fire(remoteName, ...)
    local r = ReplicatedStorage:FindFirstChild(remoteName)
    if r then
        pcall(function()
            if r:IsA('RemoteEvent') then r:FireServer(...) else r:Fire(...) end
        end)
        return true
    end
    return false
end

-- ========== ESP ==========
local function applyHighlight(instance, color, text)
    if not instance or instance:FindFirstChild('NF_ESP') then return end
    local hl = Instance.new('Highlight')
    hl.Name = 'NF_ESP'
    hl.FillTransparency = 1
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = instance
    local bill = Instance.new('BillboardGui')
    bill.Name = 'NF_ESP_Name'
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.Parent = instance
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bill
end

local function removeESP(inst)
    local h = inst:FindFirstChild('NF_ESP')
    if h then h:Destroy() end
    local b = inst:FindFirstChild('NF_ESP_Name')
    if b then b:Destroy() end
end

-- ========== Tabs ==========
local Tabs = {
    ESP = Window:AddTab('ESP'),
    Progress = Window:AddTab('Progress'),
    Clock = Window:AddTab('Clock'),
    Entities = Window:AddTab('Entities'),
    Player = Window:AddTab('Player'),
    World = Window:AddTab('World'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ==================== 1. ESP ====================
local espGroup = Tabs.ESP:AddLeftGroupbox('Monster Highlight')
local espUntrusted = espGroup:AddToggle('EspUntrusted', { Text = 'UntrustedAdult', Default = false })
local espDread = espGroup:AddToggle('EspDread', { Text = 'DreadEntity (any)', Default = false })
local espPeripheral = espGroup:AddToggle('EspPeripheral', { Text = 'Peripheral', Default = false })
local espShadow = espGroup:AddToggle('EspShadow', { Text = 'Shadow Friends', Default = false })
local espPainting = espGroup:AddToggle('EspPainting', { Text = 'Painting1 (drawing world)', Default = false })

local function updateESP()
    local dreamChangers = workspace:FindFirstChild('DreamChangers')
    if dreamChangers then
        for _, child in ipairs(dreamChangers:GetChildren()) do
            if child.Name == 'UntrustedAdult' then
                if espUntrusted.Value then applyHighlight(child, Color3.new(1,0,0), 'UNTRUSTED ADULT')
                else removeESP(child) end
            elseif child.Name == 'DreadEntity' then
                if espDread.Value then applyHighlight(child, Color3.new(1,0.2,0), 'DREAD ENTITY')
                else removeESP(child) end
            elseif child.Name == 'Peripheral' then
                if espPeripheral.Value then applyHighlight(child, Color3.new(1,0.5,0), 'PERIPHERAL')
                else removeESP(child) end
            elseif child.Name == 'Painting1' then
                if espPainting.Value then applyHighlight(child, Color3.new(1,0,1), 'PAINTING')
                else removeESP(child) end
            end
        end
    end
    local holder = workspace:FindFirstChild('ShadowFriendHolder')
    if holder then
        for _, child in ipairs(holder:GetChildren()) do
            if espShadow.Value then applyHighlight(child, Color3.new(0.4,0.4,1), 'SHADOW FRIEND')
            else removeESP(child) end
        end
    end
end

local dreamChangers = workspace:WaitForChild('DreamChangers')
dreamChangers.ChildAdded:Connect(function(child)
    if child.Name == 'UntrustedAdult' and espUntrusted.Value then
        applyHighlight(child, Color3.new(1,0,0), 'UNTRUSTED ADULT')
    elseif child.Name == 'DreadEntity' and espDread.Value then
        applyHighlight(child, Color3.new(1,0.2,0), 'DREAD ENTITY')
    elseif child.Name == 'Peripheral' and espPeripheral.Value then
        applyHighlight(child, Color3.new(1,0.5,0), 'PERIPHERAL')
    elseif child.Name == 'Painting1' and espPainting.Value then
        applyHighlight(child, Color3.new(1,0,1), 'PAINTING')
    end
end)
local shadowHolder = workspace:FindFirstChild('ShadowFriendHolder')
if shadowHolder then
    shadowHolder.ChildAdded:Connect(function(child)
        if espShadow.Value then applyHighlight(child, Color3.new(0.4,0.4,1), 'SHADOW FRIEND') end
    end)
end

espUntrusted:OnChanged(updateESP)
espDread:OnChanged(updateESP)
espPeripheral:OnChanged(updateESP)
espShadow:OnChanged(updateESP)
espPainting:OnChanged(updateESP)
updateESP()

-- ==================== 2. PROGRESS ====================
local progGroup = Tabs.Progress:AddLeftGroupbox('Stage Transitions')

progGroup:AddButton({ Text = 'Complete Blue Hour (clock)', Func = function()
    local clock = CollectionService:GetTagged('IsClock')[1]
    if clock then
        clock:SetAttribute('CurrentHour', workspace:GetAttribute('NextClockHour') or 2)
        clock:SetAttribute('CurrentMinutes', workspace:GetAttribute('NextClockMinutes') or 5)
        fire('FinishedClock', clock)
        print('[Progress] FinishedClock fired')
    end
end })

progGroup:AddButton({ Text = 'Enter classroom (ReachedMsC)', Func = function()
    local zone = workspace:FindFirstChild('SmallerRegionZones') and workspace.SmallerRegionZones:FindFirstChild('MsCRoom')
    if zone then
        zone:SetAttribute('Inside', true)
        zone:SetAttribute('ShouldDetect', true)
    end
    fire('ReachedMsC')
    local map = workspace:FindFirstChild('Map')
    local door = map and map:FindFirstChild('ElementaryNormalMap') and map.ElementaryNormalMap:FindFirstChild('ClassroomDoor')
    if door then safeTeleport(door.CFrame + Vector3.new(0,2,0)) end
    print('[Progress] ReachedMsC fired')
end })

progGroup:AddButton({ Text = 'Speed up current dialogue', Func = function()
    for _ = 1, 30 do
        fire('DialogueMoveOn')
        task.wait(0.05)
    end
end })

progGroup:AddButton({ Text = 'Complete Untrusted stage (2:05)', Func = function()
    local h, m = workspace:GetAttribute('NextClockHour') or 2, workspace:GetAttribute('NextClockMinutes') or 5
    for _, clock in ipairs(CollectionService:GetTagged('IsClock')) do
        if not clock:GetAttribute('Completed') then
            clock:SetAttribute('CurrentHour', h)
            clock:SetAttribute('CurrentMinutes', m)
            fire('FinishedClock', clock)
            task.wait(0.1)
        end
    end
    print('[Progress] All clocks set to', h, m)
end })

progGroup:AddButton({ Text = 'Enter drawing world', Func = function()
    fire('ReachedDrawingZone', 'InFrontOfHouseZone')
    setCurrentZone('InFrontOfHouseZone')
    local map = workspace:FindFirstChild('Map')
    local spawn = map and map:FindFirstChild('DrawingWorld') and map.DrawingWorld:FindFirstChild('DrawingWorldSpawn')
    if spawn then
        safeTeleport(spawn.CFrame + Vector3.new(0,2,0))
        print('[Progress] Teleported to drawing world')
    end
end })

progGroup:AddButton({ Text = 'Exit drawing world (via door)', Func = function()
    local map = workspace:FindFirstChild('Map')
    local drawingWorld = map and map:FindFirstChild('DrawingWorld')
    local doorModel = drawingWorld and (drawingWorld:FindFirstChild('DrawingDoorHiddenOne') or drawingWorld:FindFirstChild('ExitDoor'))
    if not doorModel then doorModel = workspace:FindFirstChild('DrawingDoorHiddenOne') end
    if doorModel then
        local mainDoor = doorModel:FindFirstChild('MovingDoor') and doorModel.MovingDoor:FindFirstChild('MainDoor')
        if not mainDoor then mainDoor = doorModel:FindFirstChild('MainDoor') end
        if mainDoor then
            local prompt = mainDoor:FindFirstChild('DoorPrompt')
            if prompt then
                pcall(function() prompt.Triggered:Fire(LocalPlayer) end)
                print('[Progress] Exit door activated')
                return
            end
        end
    end
    warn('Failed to find drawing world exit door')
end })

progGroup:AddToggle('DisableCutscenes', { Text = 'Disable cutscenes', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', nil)
        workspace:SetAttribute('HideAllLimbs', nil)
        workspace:SetAttribute('InClock', nil)
        workspace:SetAttribute('ScriptedFOV', nil)
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if root then root.Anchored = false end
        end
    end
end)

-- GameState slider
local gsSlider = progGroup:AddSlider('GameState', { Text = 'GameState (0-11)', Default = 0, Min = 0, Max = 11, Rounding = 0 })
gsSlider:OnChanged(function(v) workspace:SetAttribute('GameState', v) end)

-- Teleports
local teleGroup = Tabs.Progress:AddRightGroupbox('Teleportation')
local savedPos = nil
teleGroup:AddButton({ Text = 'Save position', Func = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        savedPos = LocalPlayer.Character.HumanoidRootPart.CFrame
        print('Position saved')
    end
end })
teleGroup:AddButton({ Text = 'Return', Func = function()
    if savedPos then safeTeleport(savedPos) end
end })
teleGroup:AddButton({ Text = 'Classroom door', Func = function()
    local map = workspace:FindFirstChild('Map')
    local door = map and map:FindFirstChild('ElementaryNormalMap') and map.ElementaryNormalMap:FindFirstChild('ClassroomDoor')
    if door then safeTeleport(door.CFrame + Vector3.new(0,2,0)) end
end })
teleGroup:AddButton({ Text = 'Drawing world spawn', Func = function()
    local map = workspace:FindFirstChild('Map')
    local spawn = map and map:FindFirstChild('DrawingWorld') and map.DrawingWorld:FindFirstChild('DrawingWorldSpawn')
    if spawn then safeTeleport(spawn.CFrame + Vector3.new(0,2,0)) end
end })
teleGroup:AddButton({ Text = 'Normal map spawn', Func = function()
    local map = workspace:FindFirstChild('Map')
    local spawn = map and map:FindFirstChild('ElementaryNormalMap') and map.ElementaryNormalMap:FindFirstChild('SpawnLocation')
    if spawn then safeTeleport(spawn.CFrame + Vector3.new(0,2,0)) end
end })
teleGroup:AddButton({ Text = 'Ending nightmare spawn', Func = function()
    local map = workspace:FindFirstChild('Map')
    local spawn = map and map:FindFirstChild('EndingNightmare') and map.EndingNightmare:FindFirstChild('EndingNightmareSpawn')
    if spawn then safeTeleport(spawn.CFrame + Vector3.new(0,2,0)) end
end })
teleGroup:AddInput('CustomCoord', { Text = 'Coordinates X,Y,Z', Default = '0,5,0', Numeric = false, Finished = true })
teleGroup:AddButton({ Text = 'Teleport', Func = function()
    local x,y,z = Options.CustomCoord.Value:match('([^,]+),([^,]+),([^,]+)')
    if x and y and z then safeTeleport(CFrame.new(tonumber(x), tonumber(y), tonumber(z))) end
end })

-- ==================== 3. CLOCK ====================
local clockGroup = Tabs.Clock:AddLeftGroupbox('Clock cheat')
clockGroup:AddButton({ Text = 'Enable native CheatMode', Func = function()
    workspace:SetAttribute('CheatMode', true)
    print('[Clock] CheatMode ON - 10x clock speed, instant voicelines')
end })
clockGroup:AddButton({ Text = 'Disable native CheatMode', Func = function()
    workspace:SetAttribute('CheatMode', nil)
end })
clockGroup:AddButton({ Text = 'Auto-finish ALL clocks (instant)', Func = function()
    local h, m = workspace:GetAttribute('NextClockHour') or 2, workspace:GetAttribute('NextClockMinutes') or 5
    for _, clock in ipairs(CollectionService:GetTagged('IsClock')) do
        clock:SetAttribute('CurrentHour', h)
        clock:SetAttribute('CurrentMinutes', m)
        fire('FinishedClock', clock)
        task.wait(0.1)
    end
    print('[Clock] All clocks finished at', h, m)
end })
clockGroup:AddButton({ Text = 'Mark all clocks Completed', Func = function()
    for _, clock in ipairs(CollectionService:GetTagged('IsClock')) do
        clock:SetAttribute('Completed', true)
    end
end })
local clockList = {}
for _, c in ipairs(CollectionService:GetTagged('IsClock')) do
    table.insert(clockList, c.Name)
end
local clockTele = clockGroup:AddDropdown('ClockTeleport', { Values = clockList, Default = 1, Text = 'Teleport to clock' })
clockTele:OnChanged(function(val)
    for _, clock in ipairs(CollectionService:GetTagged('IsClock')) do
        if clock.Name == val and clock:FindFirstChild('ClockCam') then
            safeTeleport(clock.ClockCam.CFrame)
            break
        end
    end
end)
clockGroup:AddLabel('Target time: ' .. (workspace:GetAttribute('NextClockHour') or '?') .. ':' .. (workspace:GetAttribute('NextClockMinutes') or '?'))

-- ==================== 4. ENTITIES ====================
local entGroup = Tabs.Entities:AddLeftGroupbox('Untrusted Adult')
local blurToggle = entGroup:AddToggle('DisableUntrustedBlur', { Text = 'Disable blur', Default = false })
local untrustedBlurHandler = nil
local function setupUntrustedBlurOff()
    if blurToggle.Value then
        local blur = Lighting:FindFirstChild('UntrustedBlur')
        if blur then blur.Enabled = false end
        if not untrustedBlurHandler then
            untrustedBlurHandler = workspace.DreamChangers.ChildAdded:Connect(function(child)
                if child.Name == 'UntrustedAdult' and blurToggle.Value then
                    local blur2 = Lighting:FindFirstChild('UntrustedBlur')
                    if blur2 then blur2.Enabled = false end
                end
            end)
        end
    else
        if untrustedBlurHandler then untrustedBlurHandler:Disconnect(); untrustedBlurHandler = nil end
        local blur = Lighting:FindFirstChild('UntrustedBlur')
        if blur then blur.Enabled = true end
    end
end
blurToggle:OnChanged(setupUntrustedBlurOff)
setupUntrustedBlurOff()

entGroup:AddToggle('SpamSeesUntrustedFalse', { Text = 'Report "not seen" (blur stays off)', Default = false }):OnChanged(function(v)
    if v then
        task.spawn(function()
            while task.wait(0.5) and v do
                fire('SeesUntrusted', false)
            end
        end)
    end
end)
entGroup:AddButton({ Text = 'Delete UntrustedAdult (cosmetic)', Func = function()
    local u = workspace.DreamChangers:FindFirstChild('UntrustedAdult')
    if u then u:Destroy() end
end })

local shadowGroup = Tabs.Entities:AddRightGroupbox('Shadow Friends')
shadowGroup:AddButton({ Text = 'Delete all shadows', Func = function()
    local holder = workspace:FindFirstChild('ShadowFriendHolder')
    if holder then holder:ClearAllChildren() end
end })
local originalShadowEvent = nil
local disableSpawnToggle = shadowGroup:AddToggle('DisableShadowSpawn', { Text = 'Disable shadow spawn', Default = false })
disableSpawnToggle:OnChanged(function(v)
    local shadowEvent = ReplicatedStorage:FindFirstChild('ShadowFriendSpawn')
    if not shadowEvent then return end
    if v then
        if not originalShadowEvent then
            originalShadowEvent = shadowEvent.OnClientEvent
        end
        shadowEvent.OnClientEvent = function() end
    else
        if originalShadowEvent then
            shadowEvent.OnClientEvent = originalShadowEvent
        end
        originalShadowEvent = nil
    end
end)
-- Shadow-proof: Cutscene=true blocks the client-side Touched kill
local shadowProof = shadowGroup:AddToggle('ShadowProof', { Text = 'Shadow-proof (Cutscene lock)', Default = false })
shadowProof:OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', true)
    else
        workspace:SetAttribute('Cutscene', nil)
    end
end)
shadowGroup:AddButton({ Text = 'Disable DrawingJumpscare', Func = function()
    local dj = workspace.DreamChangers:FindFirstChild('DrawingJumpscare')
    if dj then
        dj:SetAttribute('ShouldDetect', nil)
        dj:SetAttribute('AlsoRaycast', nil)
    end
    local rs = ReplicatedStorage:FindFirstChild('DrawingJumpscare')
    if rs then
        rs:SetAttribute('ShouldDetect', nil)
    end
    print('[Entities] DrawingJumpscare disabled')
end })
shadowGroup:AddButton({ Text = 'Painting1 stop (ShouldDetect off)', Func = function()
    local p = workspace.DreamChangers:FindFirstChild('Painting1')
    if p then p:SetAttribute('ShouldDetect', nil) end
end })

-- ==================== 5. PLAYER ====================
local playerGroup = Tabs.Player:AddLeftGroupbox('Speed & noclip')
local speedSlider = playerGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Default = 16, Min = 0, Max = 250, Rounding = 1 })
local jumpSlider = playerGroup:AddSlider('JumpPower', { Text = 'JumpPower', Default = 50, Min = 0, Max = 200, Rounding = 1 })
local noclipToggle = playerGroup:AddToggle('Noclip', { Text = 'Noclip', Default = false })
local noclipConn = nil

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
playerGroup:AddButton({ Text = 'GrowTaller (HeightModification=2)', Func = function()
    workspace:SetAttribute('HeightModification', 2)
    print('[Player] HeightModification=2')
end })
playerGroup:AddButton({ Text = 'Normal height', Func = function()
    workspace:SetAttribute('HeightModification', nil)
end })
playerGroup:AddButton({ Text = 'Force PC mode', Func = function()
    LocalPlayer:SetAttribute('device', 'pc')
end })

-- ==================== 6. WORLD ====================
local worldGroup = Tabs.World:AddLeftGroupbox('Visual Effects')
local noFog = worldGroup:AddToggle('NoFog', { Text = 'Remove fog', Default = false })
local fullbright = worldGroup:AddToggle('Fullbright', { Text = 'Fullbright', Default = false })
local clouds = worldGroup:AddToggle('Clouds', { Text = 'Clouds', Default = false })
local atmosSlider = worldGroup:AddSlider('AtmosDensity', { Text = 'Atmosphere density', Default = 0.3, Min = 0, Max = 1, Rounding = 2 })
local hurlToggle = worldGroup:AddToggle('DisableHurlNoise', { Text = 'Disable HurlNoise', Default = false })

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

clouds:OnChanged(function(v)
    local c = workspace:FindFirstChild('Terrain') and workspace.Terrain:FindFirstChild('Clouds')
    if c then c.Enabled = v end
end)
atmosSlider:OnChanged(function(v)
    local a = Lighting:FindFirstChild('Atmosphere')
    if a then a.Density = v end
end)
hurlToggle:OnChanged(function(v)
    if v then workspace:SetAttribute('HurlNoise', nil) else workspace:SetAttribute('HurlNoise', true) end
end)

-- ==================== 7. MISC ====================
local miscGroup = Tabs.Misc:AddLeftGroupbox('Automation')
local autoDial = miscGroup:AddToggle('AutoDialogue', { Text = 'Auto-skip dialogue', Default = false })
local dialDelay = miscGroup:AddSlider('DialogueDelay', { Text = 'Delay', Default = 0.1, Min = 0.01, Max = 1, Rounding = 2 })
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

-- ==================== 8. UI SETTINGS ====================
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFire_DreamElementary_FINAL')
SaveManager:SetFolder('NullFire_DreamElementary_FINAL')
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
    Library:SetWatermark(('NullFire DE FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

-- Cleanup
Library:OnUnload(function()
    stopDial()
    if noclipConn then noclipConn:Disconnect() end
    if fullbright.Value then fullbright:SetValue(false) end
    if noFog.Value then noFog:SetValue(false) end
    if untrustedBlurHandler then untrustedBlurHandler:Disconnect() end
    if shadowProof.Value then shadowProof:SetValue(false) end
    if originalShadowEvent then
        local ev = ReplicatedStorage:FindFirstChild('ShadowFriendSpawn')
        if ev then ev.OnClientEvent = originalShadowEvent end
    end
end)

print('NullFire Dream Elementary FINAL loaded')
