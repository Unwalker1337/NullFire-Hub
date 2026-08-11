-- NullFire Hub | Homescape FINAL
-- RE findings: Peripheral AI is 100% client-side. Kill switches:
--   character InSafety = true          -> never targeted, no jumpscare (official hide mechanic)
--   workspace Jumpscared = true        -> touch-kill blocked
--   Peripheral ShouldDetect = false    -> forced Hidden (invisible + WalkSpeed 1-2)
--   Peripheral Hidden = true           -> force hide
--   Peripheral HRP Anchored = true     -> forced Idle
--   Peripheral Humanoid.WalkSpeed = 0  -> freeze
-- Memory collection: GotMemory(memoryPart) per MemoryRecollector*. Deposit: DepositInteract.
-- Rails puzzle: RotateRail(rail) per RailStuff child. GameState client-writable (>=5/6 = ending).

local placeId = game.PlaceId
if placeId ~= 73136969954228 then
    warn("NullFire Hub: this script works only in Homescape. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub | Homescape FINAL',
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
    if r then
        pcall(function()
            if r:IsA('RemoteEvent') then r:FireServer(...) else r:Fire(...) end
        end)
        return true
    end
    return false
end

local function getPeripherals()
    local out = {}
    local dreamChangers = workspace:FindFirstChild('DreamChangers')
    if dreamChangers then
        for _, c in ipairs(dreamChangers:GetChildren()) do
            if c.Name == 'Peripheral' then out[#out + 1] = c end
        end
    end
    return out
end

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
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
    Peripheral = Window:AddTab('Peripheral'),
    Progress = Window:AddTab('Progress'),
    Memories = Window:AddTab('Memories'),
    Player = Window:AddTab('Player'),
    Visual = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ==================== 1. PERIPHERAL ====================
local espToggle = Tabs.Peripheral:AddLeftGroupbox('ESP'):AddToggle('PeripheralESP', { Text = 'Highlight Peripherals', Default = false })
local function updateESP()
    for _, p in ipairs(getPeripherals()) do
        if espToggle.Value then applyHighlight(p, Color3.new(0.8, 0.2, 1), 'PERIPHERAL')
        else removeESP(p) end
    end
end
espToggle:OnChanged(updateESP)
local dreamChangers = workspace:WaitForChild('DreamChangers')
dreamChangers.ChildAdded:Connect(function(child)
    if child.Name == 'Peripheral' and espToggle.Value then
        task.wait(0.5)
        applyHighlight(child, Color3.new(0.8, 0.2, 1), 'PERIPHERAL')
    end
end)

local pGroup = Tabs.Peripheral:AddLeftGroupbox('Peripheral Control')

pGroup:AddButton({ Text = 'NUCLEAR: disable all Peripherals', Func = function()
    local char = LocalPlayer.Character
    if char then char:SetAttribute('InSafety', true) end
    workspace:SetAttribute('Jumpscared', true)
    for _, p in ipairs(getPeripherals()) do
        p:SetAttribute('ShouldDetect', false)
        p:SetAttribute('Hidden', true)
        local hrp = p:FindFirstChild('HumanoidRootPart')
        if hrp then hrp.Anchored = true end
        local hum = p:FindFirstChild('Humanoid')
        if hum then hum.WalkSpeed = 0 end
    end
    print('[Peripheral] All Peripherals neutralized')
end })

pGroup:AddButton({ Text = 'InSafety = true (never targeted)', Func = function()
    local char = LocalPlayer.Character
    if char then char:SetAttribute('InSafety', true) end
    print('[Peripheral] InSafety=true - AI ignores you')
end })

pGroup:AddButton({ Text = 'Jumpscared = true (no touch-kill)', Func = function()
    workspace:SetAttribute('Jumpscared', true)
end })

pGroup:AddButton({ Text = 'Freeze all (anchor + ShouldDetect off)', Func = function()
    for _, p in ipairs(getPeripherals()) do
        p:SetAttribute('ShouldDetect', false)
        local hrp = p:FindFirstChild('HumanoidRootPart')
        if hrp then hrp.Anchored = true end
        local hum = p:FindFirstChild('Humanoid')
        if hum then hum.WalkSpeed = 0 end
    end
    print('[Peripheral] Frozen')
end })

pGroup:AddButton({ Text = 'Force hide (Hidden=true)', Func = function()
    for _, p in ipairs(getPeripherals()) do
        p:SetAttribute('Hidden', true)
    end
end })

pGroup:AddButton({ Text = 'Force show', Func = function()
    for _, p in ipairs(getPeripherals()) do
        p:SetAttribute('Hidden', nil)
        p:SetAttribute('ShouldDetect', true)
        local hrp = p:FindFirstChild('HumanoidRootPart')
        if hrp then hrp.Anchored = false end
    end
end })

pGroup:AddButton({ Text = 'Teleport me to Peripheral', Func = function()
    local ps = getPeripherals()
    if #ps > 0 and ps[1]:FindFirstChild('HumanoidRootPart') then
        safeTeleport(ps[1].HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
    end
end })

pGroup:AddButton({ Text = 'Teleport Peripheral to me', Func = function()
    local ps = getPeripherals()
    if #ps > 0 and LocalPlayer.Character then
        local hrp = ps[1]:FindFirstChild('HumanoidRootPart')
        if hrp then
            hrp.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
end })

local walkSlider = pGroup:AddSlider('PeripheralWalkSpeed', { Text = 'Peripheral WalkSpeed', Default = 4, Min = 0, Max = 50, Rounding = 1 })
local walkLoopConn = nil
walkSlider:OnChanged(function()
    if not walkLoopConn then
        walkLoopConn = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(getPeripherals()) do
                local hum = p:FindFirstChild('Humanoid')
                if hum then hum.WalkSpeed = walkSlider.Value end
            end
        end)
    end
end)

-- ==================== 2. PROGRESS ====================
local progGroup = Tabs.Progress:AddLeftGroupbox('Stage Control')

local zones = { 'BeginningZone', 'DangerZone', 'WoodZone', 'OutsideZone1', 'BasementLobbyZone1', 'CTMinigameZone' }
local zoneDrop = progGroup:AddDropdown('CurrentZone', { Values = zones, Default = 1, Text = 'Current zone' })
zoneDrop:OnChanged(function(v) workspace:SetAttribute('CurrentZone', v) end)

local gsSlider = progGroup:AddSlider('GameState', { Text = 'GameState (1-6)', Default = 1, Min = 1, Max = 6, Rounding = 0 })
gsSlider:OnChanged(function(v) workspace:SetAttribute('GameState', v) end)

progGroup:AddButton({ Text = 'GotToBasementLobby', Func = function()
    fire('GotToBasementLobby')
    workspace:SetAttribute('BasementLobbied', true)
end })
progGroup:AddButton({ Text = 'Set MemoryLeft = 0', Func = function()
    workspace:SetAttribute('MemoryLeft', 0)
end })
progGroup:AddButton({ Text = 'Complete exit (TrueExit + ReachedEnd)', Func = function()
    local exit = workspace:FindFirstChild('TrueExit')
    if exit then safeTeleport(exit.CFrame * CFrame.new(0, 2, 0)) end
    task.wait(0.3)
    workspace:SetAttribute('Cutscene', true)
    workspace:SetAttribute('HideAllLimbs', true)
    fire('ReachedEnd')
    print('[Progress] ReachedEnd fired')
end })
progGroup:AddButton({ Text = 'Teleport to TrueExit', Func = function()
    local exit = workspace:FindFirstChild('TrueExit')
    if exit then safeTeleport(exit.CFrame * CFrame.new(0, 2, 0)) end
end })
progGroup:AddButton({ Text = 'Teleport to EndingTPPlace', Func = function()
    local tp = workspace:FindFirstChild('EndingTPPlace')
    if tp then safeTeleport(tp.CFrame * CFrame.new(0, 2, 0)) end
end })
progGroup:AddButton({ Text = 'Teleport to MemoryDepositer', Func = function()
    local dep = workspace:FindFirstChild('MemoryDepositer')
    if dep then safeTeleport(dep.CFrame * CFrame.new(0, 2, 2)) end
end })
progGroup:AddButton({ Text = 'DepositInteract', Func = function()
    fire('DepositInteract')
end })
progGroup:AddToggle('DisableCutscene', { Text = 'Disable cutscene', Default = false }):OnChanged(function(v)
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

-- Rails
local railGroup = Tabs.Progress:AddRightGroupbox('Rail puzzle')
railGroup:AddButton({ Text = 'Rotate ALL rails', Func = function()
    local railStuff = workspace:FindFirstChild('RailStuff')
    if railStuff then
        for _, rail in ipairs(railStuff:GetChildren()) do
            fire('RotateRail', rail)
            task.wait(0.1)
        end
        print('[Progress] RotateRail fired for all rails')
    end
end })
railGroup:AddButton({ Text = 'Teleport to RailStuff', Func = function()
    local railStuff = workspace:FindFirstChild('RailStuff')
    if railStuff then safeTeleport(railStuff.CFrame * CFrame.new(0, 2, 3)) end
end })

-- ==================== 3. MEMORIES ====================
local memGroup = Tabs.Memories:AddLeftGroupbox('Memory ESP & auto')
local memESP = memGroup:AddToggle('MemoryESP', { Text = 'Highlight recollectors', Default = false })
local function refreshMemoryESP()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("MemoryRecollector") then
            local h = obj:FindFirstChild('NF_MemESP')
            if h then h:Destroy() end
            if memESP.Value then
                local hl = Instance.new('Highlight')
                hl.Name = 'NF_MemESP'
                hl.FillTransparency = 0.5
                hl.FillColor = Color3.new(0.2, 1, 0.5)
                hl.OutlineColor = Color3.new(0, 1, 0.3)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = obj
            end
        end
    end
end
memESP:OnChanged(refreshMemoryESP)
workspace.ChildAdded:Connect(function(child)
    if child.Name:match("MemoryRecollector") and memESP.Value then
        task.wait(0.2)
        refreshMemoryESP()
    end
end)

local autoCollect = memGroup:AddToggle('AutoCollect', { Text = 'Auto-collect (loop)', Default = false })
local collectDelay = memGroup:AddSlider('CollectDelay', { Text = 'Delay', Default = 0.15, Min = 0.02, Max = 1, Rounding = 2 })
task.spawn(function()
    while true do
        task.wait(0.3)
        if autoCollect.Value then
            local remote = ReplicatedStorage:FindFirstChild('GotMemory')
            if remote then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name:match("MemoryRecollector") then
                        remote:FireServer(obj)
                        task.wait(collectDelay.Value)
                    end
                end
            end
            workspace:SetAttribute('MemoryLeft', 0)
        end
    end
end)

memGroup:AddButton({ Text = 'Collect all instantly', Func = function()
    local remote = ReplicatedStorage:FindFirstChild('GotMemory')
    if remote then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:match("MemoryRecollector") then
                remote:FireServer(obj)
                task.wait(0.1)
            end
        end
    end
    workspace:SetAttribute('MemoryLeft', 0)
    print('[Memories] GotMemory fired for all recollectors')
end })
memGroup:AddButton({ Text = 'Teleport to nearest memory', Func = function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("MemoryRecollector") and obj:IsA('BasePart') then
            local d = (obj.Position - root.Position).Magnitude
            if d < bestDist then best, bestDist = obj, d end
        end
    end
    if best then safeTeleport(best.CFrame * CFrame.new(0, 2, 0)) end
end })

-- ==================== 4. PLAYER ====================
local playerGroup = Tabs.Player:AddLeftGroupbox('Speed & noclip')
local speedSlider = playerGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Default = 16, Min = 0, Max = 250, Rounding = 1 })
local jumpSlider = playerGroup:AddSlider('JumpPower', { Text = 'JumpPower', Default = 50, Min = 0, Max = 200, Rounding = 1 })
local noclipToggle = playerGroup:AddToggle('Noclip', { Text = 'Noclip', Default = false })
local noclipConn = nil
local speedLoopConn = nil

local function setWalkSpeed()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild('Humanoid') then
        c.Humanoid.WalkSpeed = speedSlider.Value
        c.Humanoid.JumpPower = jumpSlider.Value
    end
end
local function startSpeedLoop()
    if speedLoopConn then return end
    speedLoopConn = RunService.Heartbeat:Connect(setWalkSpeed)
end
speedSlider:OnChanged(setWalkSpeed)
jumpSlider:OnChanged(setWalkSpeed)
startSpeedLoop()
LocalPlayer.CharacterAdded:Connect(function(c) c:WaitForChild('Humanoid'); setWalkSpeed() end)

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
playerGroup:AddButton({ Text = 'Force PC mode', Func = function()
    LocalPlayer:SetAttribute('device', 'pc')
end })

-- ==================== 5. VISUALS ====================
local visGroup = Tabs.Visual:AddLeftGroupbox('Effects & Ambience')
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
visGroup:AddToggle('DisableJumpscareBlur', { Text = 'Disable JumpscareBlur', Default = false }):OnChanged(function(v)
    local b = Lighting:FindFirstChild('JumpscareBlur')
    if b then b.Enabled = not v end
end)
visGroup:AddToggle('DisableDarkCorrection', { Text = 'Disable DarkCorrection', Default = false }):OnChanged(function(v)
    local dc = Lighting:FindFirstChild('DarkCorrection')
    if dc then dc.Enabled = not v end
end)
visGroup:AddSlider('AtmosDensity', { Text = 'Atmosphere density', Default = 0.3, Min = 0, Max = 1, Rounding = 2 }):OnChanged(function(v)
    local a = Lighting:FindFirstChild('Atmosphere')
    if a then a.Density = v end
end)
visGroup:AddSlider('ClockTime', { Text = 'ClockTime', Default = 12, Min = 0, Max = 24, Rounding = 0 }):OnChanged(function(v)
    Lighting.ClockTime = v
end)

local ambGroup = Tabs.Visual:AddRightGroupbox('Ambience volumes')
local ambNames = { 'NormalAirCon', 'DarkAirConditioner', 'MemoriesAreRooms', 'AfterMemoryAmbiance', 'HomescapeOutsideAmbiance', 'DepartingHomescape' }
for _, name in ipairs(ambNames) do
    ambGroup:AddSlider('Amb_' .. name, { Text = name, Default = 1, Min = 0, Max = 3, Rounding = 2 }):OnChanged(function(v)
        local s = ReplicatedStorage:FindFirstChild(name)
        if s then s.Volume = v end
    end)
end
ambGroup:AddButton({ Text = 'Kill all ambience', Func = function()
    for _, name in ipairs(ambNames) do
        local s = ReplicatedStorage:FindFirstChild(name)
        if s then s.Volume = 0; s.Playing = false end
    end
end })

-- ==================== 6. MISC ====================
local miscGroup = Tabs.Misc:AddLeftGroupbox('SayThing & teleports')
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
miscGroup:AddButton({ Text = 'Teleport to MainHall spawn', Func = function()
    local s = workspace:FindFirstChild('SpawnLocations') and workspace.SpawnLocations:FindFirstChild('MainHallSpawnLocation')
    if s then safeTeleport(s.CFrame) end
end })
miscGroup:AddButton({ Text = 'Set CustomSpawnLocation here', Func = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        workspace:SetAttribute('CustomSpawnLocation', LocalPlayer.Character.HumanoidRootPart.CFrame)
        print('[Misc] CustomSpawnLocation set')
    end
end })
miscGroup:AddButton({ Text = 'Dump workspace attributes', Func = function()
    for k, v in pairs(workspace:GetAttributes()) do
        print(k, tostring(v))
    end
end })

-- ==================== UI SETTINGS ====================
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFire_Homescape_FINAL')
SaveManager:SetFolder('NullFire_Homescape_FINAL')
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
    Library:SetWatermark(('NullFire Homescape FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

-- Cleanup
Library:OnUnload(function()
    if noclipConn then noclipConn:Disconnect() end
    if speedLoopConn then speedLoopConn:Disconnect() end
    if walkLoopConn then walkLoopConn:Disconnect() end
    if fullbright.Value then fullbright:SetValue(false) end
    if noFog.Value then noFog:SetValue(false) end
end)

print('NullFire Homescape FINAL loaded')
