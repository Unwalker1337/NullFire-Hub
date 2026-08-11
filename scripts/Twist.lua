-- NullFire Hub | The Twist FINAL
-- RE findings: the ENTIRE DreadEntity hunt is client-side. Kill switches:
--   workspace.DreadFollowing = nil            -> mirror-stalk loop dies
--   workspace.DreadChased = true              -> chase cutscene override
--   DreadEntity.Seen = true                   -> teleporting disabled forever
--   DreadEntity SprintSpeed/MinimumWalkSpeed  -> zero = crawl
--   Dread HRP Anchored = true                 -> forces Idle
--   TremoloSoundEffect.Frequency >= 5         -> teleport disabled
--   character InSafety = true                 -> never targeted, no touch-kill
--   all TwistTeleporter.Seen = true           -> no valid teleport targets
--   GameState != 1                            -> dread retreats to StoreCFrame
-- Coins are collected via PickUpCoin(coinPart), deposited via InputCoin.

local placeId = game.PlaceId
if placeId ~= 110334679443599 then
    warn("NullFire Hub: this script works only in The Twist. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub | The Twist FINAL',
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
    if r then
        pcall(function()
            if r:IsA('RemoteEvent') then r:FireServer(...) else r:Fire(...) end
        end)
        return true
    end
    return false
end

local function getDreadEntity()
    local dreamChangers = workspace:FindFirstChild('DreamChangers')
    if not dreamChangers then return nil end
    for _, c in ipairs(dreamChangers:GetChildren()) do
        if c.Name == 'DreadEntity' then return c end
    end
    return nil
end

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ========== ESP ==========
local function addESPToDread(dread)
    if not dread or dread:FindFirstChild('NF_ESP') then return end
    local hl = Instance.new('Highlight')
    hl.Name = 'NF_ESP'
    hl.FillTransparency = 1
    hl.OutlineColor = Color3.new(1, 0.2, 0)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = dread
    local bill = Instance.new('BillboardGui')
    bill.Name = 'NF_ESP_Name'
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.Parent = dread
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = 'DREAD ENTITY'
    label.TextColor3 = Color3.new(1, 0.2, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bill
end

local function removeESPFromDread(dread)
    local hl = dread:FindFirstChild('NF_ESP')
    if hl then hl:Destroy() end
    local bill = dread:FindFirstChild('NF_ESP_Name')
    if bill then bill:Destroy() end
end

-- ========== Tabs ==========
local Tabs = {
    Dread = Window:AddTab('Dread Entity'),
    Coins = Window:AddTab('Coins'),
    Progress = Window:AddTab('Progress'),
    Player = Window:AddTab('Player'),
    Visual = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ========== 1. DREAD ENTITY ==========
local espToggle = Tabs.Dread:AddLeftGroupbox('ESP'):AddToggle('DreadESP', { Text = 'Highlight DreadEntity', Default = false })
local function updateDreadESP()
    local dread = getDreadEntity()
    if dread then
        if espToggle.Value then addESPToDread(dread) else removeESPFromDread(dread) end
    end
end
espToggle:OnChanged(updateDreadESP)

local dreamChangers = workspace:WaitForChild('DreamChangers')
dreamChangers.ChildAdded:Connect(function(child)
    if child.Name == 'DreadEntity' then
        task.wait(0.5)
        updateDreadESP()
    end
end)

local dreadGroup = Tabs.Dread:AddLeftGroupbox('DreadEntity Control')

-- Status labels
local dreadSeenLabel = dreadGroup:AddLabel('Seen: ?')
local dreadFollowingLabel = dreadGroup:AddLabel('Following: ?')
local function updateDreadInfo()
    local dread = getDreadEntity()
    if dread then
        dreadSeenLabel:SetText('Seen: ' .. tostring(dread:GetAttribute('Seen') or false))
    end
    dreadFollowingLabel:SetText('Following: ' .. tostring(workspace:GetAttribute('DreadFollowing') or 'none'))
end
task.spawn(function()
    while true do
        updateDreadInfo()
        task.wait(1)
    end
end)

-- ===== The big kill switches =====
dreadGroup:AddButton({ Text = 'NUCLEAR: disable dread completely', Func = function()
    local dread = getDreadEntity()
    if dread then
        dread:SetAttribute('Seen', true)
        local hrp = dread:FindFirstChild('HumanoidRootPart')
        if hrp then hrp.Anchored = true end
        local ambience = hrp and hrp:FindFirstChild('DreadAmbience')
        if ambience then
            local trem = ambience:FindFirstChildOfClass('TremoloSoundEffect')
            if trem then trem.Frequency = 5 end
        end
        local sprint = dread:FindFirstChild('SprintSpeed')
        local minWalk = dread:FindFirstChild('MinimumWalkSpeed')
        if sprint then sprint.Value = 0 end
        if minWalk then minWalk.Value = 0 end
    end
    workspace:SetAttribute('DreadFollowing', nil)
    workspace:SetAttribute('DreadChased', true)
    for _, t in ipairs(dreamChangers:GetChildren()) do
        if t.Name == 'TwistTeleporter' then t:SetAttribute('Seen', true) end
    end
    local char = LocalPlayer.Character
    if char then char:SetAttribute('InSafety', true) end
    print('[Dread] Dread fully neutralized')
end })

dreadGroup:AddButton({ Text = 'Stop following (DreadFollowing=nil)', Func = function()
    workspace:SetAttribute('DreadFollowing', nil)
    print('[Dread] Mirror-stalk disabled')
end })

dreadGroup:AddButton({ Text = 'DreadChased = true (kill chase loop)', Func = function()
    workspace:SetAttribute('DreadChased', true)
end })

dreadGroup:AddButton({ Text = 'Freeze: Seen + Anchored', Func = function()
    local dread = getDreadEntity()
    if not dread then return end
    dread:SetAttribute('Seen', true)
    local hrp = dread:FindFirstChild('HumanoidRootPart')
    if hrp then hrp.Anchored = true end
    print('[Dread] Frozen (no teleports, forced Idle)')
end })

dreadGroup:AddButton({ Text = 'Crawl mode (speeds = 0)', Func = function()
    local dread = getDreadEntity()
    if not dread then return end
    local sprint = dread:FindFirstChild('SprintSpeed')
    local minWalk = dread:FindFirstChild('MinimumWalkSpeed')
    if sprint then sprint.Value = 0 end
    if minWalk then minWalk.Value = 0 end
    print('[Dread] Speeds zeroed')
end })

dreadGroup:AddButton({ Text = 'Kill teleporters (all Seen)', Func = function()
    for _, t in ipairs(dreamChangers:GetChildren()) do
        if t.Name == 'TwistTeleporter' then t:SetAttribute('Seen', true) end
    end
    print('[Dread] No valid teleport targets')
end })

dreadGroup:AddButton({ Text = 'Force safe zone (InSafeZone)', Func = function()
    fire('InSafeZone', true)
    local char = LocalPlayer.Character
    if char then char:SetAttribute('InSafety', true) end
    print('[Dread] InSafeZone fired')
end })

dreadGroup:AddButton({ Text = 'Retreat dread (GameState=2)', Func = function()
    workspace:SetAttribute('GameState', 2)
    print('[Dread] GameState=2 - dread retreats to StoreCFrame')
end })

dreadGroup:AddButton({ Text = 'Teleport Dread to me', Func = function()
    local dread = getDreadEntity()
    if dread and LocalPlayer.Character then
        local root = dread:FindFirstChild('HumanoidRootPart')
        if root then
            root.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
        end
    end
end })
dreadGroup:AddButton({ Text = 'Teleport me to Dread', Func = function()
    local dread = getDreadEntity()
    if dread and dread:FindFirstChild('HumanoidRootPart') then
        safeTeleport(dread.HumanoidRootPart.CFrame * CFrame.new(0,0,3))
    end
end })

local dreadWalk = dreadGroup:AddSlider('DreadWalkSpeed', { Text = 'Walk speed', Default = 16, Min = 0, Max = 200, Rounding = 1 })
local dreadRun = dreadGroup:AddSlider('DreadRunSpeed', { Text = 'Run speed', Default = 30, Min = 0, Max = 300, Rounding = 1 })
local function applyDreadSpeeds()
    local dread = getDreadEntity()
    if not dread then return end
    local sprint = dread:FindFirstChild('SprintSpeed')
    local minWalk = dread:FindFirstChild('MinimumWalkSpeed')
    if sprint then sprint.Value = dreadRun.Value end
    if minWalk then minWalk.Value = dreadWalk.Value end
end
dreadWalk:OnChanged(applyDreadSpeeds)
dreadRun:OnChanged(applyDreadSpeeds)

dreadGroup:AddToggle('DisableDreadFollowing', { Text = 'Disable Dread following', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('DreadFollowing', nil)
        workspace:SetAttribute('DreadChased', true)
    end
end)

-- ========== 2. COINS ==========
local coinsGroup = Tabs.Coins:AddLeftGroupbox('Coins & CoinBox')

local highlightToggle = coinsGroup:AddToggle('HighlightCoins', { Text = 'Highlight coins', Default = false })
local highlightConnection = nil
local function toggleCoinHighlight()
    local coinsFolder = workspace:FindFirstChild('Coins')
    if not coinsFolder then return end
    if highlightToggle.Value then
        for _, coin in ipairs(coinsFolder:GetChildren()) do
            if coin.Name == 'CoinItem' and coin:IsA('BasePart') and coin.Transparency < 1 and not coin:FindFirstChild('HintHighlight') then
                local hl = ReplicatedStorage:FindFirstChild('HintHighlight')
                if hl then
                    local newHl = hl:Clone()
                    newHl.Parent = coin
                    newHl.Enabled = true
                end
            end
        end
        if not highlightConnection then
            highlightConnection = coinsFolder.ChildAdded:Connect(function(coin)
                if highlightToggle.Value and coin.Name == 'CoinItem' and not coin:FindFirstChild('HintHighlight') then
                    local hl = ReplicatedStorage:FindFirstChild('HintHighlight')
                    if hl then
                        local newHl = hl:Clone()
                        newHl.Parent = coin
                        newHl.Enabled = true
                    end
                end
            end)
        end
    else
        if highlightConnection then
            highlightConnection:Disconnect()
            highlightConnection = nil
        end
        for _, coin in ipairs(coinsFolder:GetChildren()) do
            local hl = coin:FindFirstChild('HintHighlight')
            if hl then hl:Destroy() end
        end
    end
end
highlightToggle:OnChanged(toggleCoinHighlight)

coinsGroup:AddLabel('Coins inventory:')
local coinsInvLabel = coinsGroup:AddLabel('0')
task.spawn(function()
    while true do
        coinsInvLabel:SetText('CoinsInventory: ' .. tostring(workspace:GetAttribute('CoinsInventory') or 0))
        task.wait(1)
    end
end)

local autoCoinToggle = coinsGroup:AddToggle('AutoPickupCoins', { Text = 'Auto-collect coins', Default = false })
local pickUpRemote = ReplicatedStorage:FindFirstChild('PickUpCoin')
task.spawn(function()
    while true do
        task.wait(0.3)
        if autoCoinToggle.Value and pickUpRemote then
            local coinsFolder = workspace:FindFirstChild('Coins')
            if coinsFolder then
                for _, coin in ipairs(coinsFolder:GetChildren()) do
                    if coin.Name == 'CoinItem' and coin.Transparency < 1 then
                        pickUpRemote:FireServer(coin)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

coinsGroup:AddButton({ Text = 'Activate CoinBox', Func = function()
    local coinBox = workspace:FindFirstChild('CoinBox')
    if coinBox then
        local prompt = coinBox:FindFirstChild('Cube') and coinBox.Cube:FindFirstChild('ProximityPrompt')
        if prompt then
            pcall(function() prompt:Fire(LocalPlayer) end)
        end
    end
end })
coinsGroup:AddButton({ Text = 'Deposit coin (InputCoin)', Func = function()
    fire('InputCoin')
end })
coinsGroup:AddButton({ Text = 'Set CoinsLeft = 0', Func = function()
    workspace:SetAttribute('CoinsLeft', 0)
end })
coinsGroup:AddButton({ Text = 'Teleport to nearest coin', Func = function()
    local coinsFolder = workspace:FindFirstChild('Coins')
    if not coinsFolder or not LocalPlayer.Character then return end
    local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return end
    local best, bestDist = nil, math.huge
    for _, coin in ipairs(coinsFolder:GetChildren()) do
        if coin.Name == 'CoinItem' and coin.Transparency < 1 then
            local d = (coin.Position - root.Position).Magnitude
            if d < bestDist then best, bestDist = coin, d end
        end
    end
    if best then safeTeleport(best.CFrame * CFrame.new(0, 1, 0)) end
end })

-- ========== 3. PROGRESS ==========
local progGroup = Tabs.Progress:AddLeftGroupbox('Stage control')

local zones = { 'SafeZone', 'WindowDetectionZone', 'ParkZone', 'LastCutsceneZone' }
local zoneDrop = progGroup:AddDropdown('CurrentZone', { Values = zones, Default = 1, Text = 'Current zone' })
zoneDrop:OnChanged(function(v)
    workspace:SetAttribute('CurrentZone', v)
end)

local gsSlider = progGroup:AddSlider('GameState', { Text = 'GameState (0-3)', Default = 0, Min = 0, Max = 3, Rounding = 0 })
gsSlider:OnChanged(function(v) workspace:SetAttribute('GameState', v) end)

progGroup:AddToggle('DisableCutscenes', { Text = 'Disable cutscenes', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', nil)
        workspace:SetAttribute('CutsceneWobble', nil)
        workspace:SetAttribute('HideAllLimbs', nil)
        workspace:SetAttribute('ScriptedFOV', nil)
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if root then root.Anchored = false end
        end
    end
end)

progGroup:AddButton({ Text = 'Finish chapter', Func = function()
    fire('DoneWithEndScene')
end })
progGroup:AddButton({ Text = 'Zone: WindowDetection (InWindowDetection)', Func = function()
    fire('InWindowDetection', true)
end })
progGroup:AddButton({ Text = 'Zone: LastCutscene (GotToEndZone)', Func = function()
    fire('GotToEndZone')
end })
progGroup:AddButton({ Text = 'Teleport to Zone1Wall', Func = function()
    local wall = workspace:FindFirstChild('Zone1Wall')
    if wall then safeTeleport(wall.CFrame * CFrame.new(0, 2, 3)) end
end })
progGroup:AddButton({ Text = 'Teleport to SafeZone3', Func = function()
    local zones2 = workspace:FindFirstChild('RegionZones')
    local sz = zones2 and zones2:FindFirstChild('SafeZone3')
    if sz then safeTeleport(sz.CFrame * CFrame.new(0, 2, 0)) end
end })

-- ========== 4. PLAYER ==========
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

-- ========== 5. VISUALS ==========
local visGroup = Tabs.Visual:AddLeftGroupbox('Visual effects')
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

visGroup:AddToggle('DisableDreadOST', { Text = 'Disable Dread music', Default = false }):OnChanged(function(v)
    local ost = ReplicatedStorage:FindFirstChild('SubconsciousDreadOST')
    if ost then
        if v then ost.Volume = 0 else ost.Volume = ost:GetAttribute('InitialVolume') or 1 end
    end
end)
visGroup:AddButton({ Text = 'Stop Dread OST completely', Func = function()
    local ost = ReplicatedStorage:FindFirstChild('SubconsciousDreadOST')
    if ost then pcall(function() ost:Stop() end) end
end })
visGroup:AddToggle('DisableHurlNoise', { Text = 'Disable HurlNoise', Default = false }):OnChanged(function(v)
    if v then workspace:SetAttribute('HurlNoise', nil) else workspace:SetAttribute('HurlNoise', true) end
end)

-- ========== 6. MISC ==========
local miscGroup = Tabs.Misc:AddLeftGroupbox('Automation & cheats')

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

-- Teleportation
local teleGroup = Tabs.Misc:AddRightGroupbox('Teleportation')
local savedPos = nil
teleGroup:AddButton({ Text = 'Save position', Func = function()
    if LocalPlayer.Character then
        savedPos = LocalPlayer.Character.HumanoidRootPart.CFrame
        print('Position saved')
    end
end })
teleGroup:AddButton({ Text = 'Return', Func = function()
    if savedPos then safeTeleport(savedPos) end
end })
teleGroup:AddInput('CustomCoord', { Text = 'Coordinates X,Y,Z', Default = '0,5,0', Numeric = false, Finished = true })
teleGroup:AddButton({ Text = 'Teleport', Func = function()
    local x,y,z = Options.CustomCoord.Value:match('([^,]+),([^,]+),([^,]+)')
    if x and y and z then safeTeleport(CFrame.new(tonumber(x), tonumber(y), tonumber(z))) end
end })

miscGroup:AddToggle('DisableSafeZoneMessage', { Text = 'Disable SafeZone messages', Default = false }):OnChanged(function(v)
    local remote = ReplicatedStorage:FindFirstChild('InSafeZone')
    if remote then
        if v then fire('InSafeZone', nil) else fire('InSafeZone', true) end
    end
end)

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
miscGroup:AddButton({ Text = 'Dread spam (join me in paradise)', Func = function()
    say('join me in paradise.', {'RedText'})
end })

-- ========== UI SETTINGS ==========
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFireHub_Twist_FINAL')
SaveManager:SetFolder('NullFireHub_Twist_FINAL')
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
    Library:SetWatermark(('NullFire Twist FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

-- Cleanup
Library:OnUnload(function()
    stopDial()
    if noclipConn then noclipConn:Disconnect() end
    if speedLoopConn then speedLoopConn:Disconnect() end
    if fullbright.Value then fullbright:SetValue(false) end
    if noFog.Value then noFog:SetValue(false) end
    if highlightConnection then highlightConnection:Disconnect() end
end)

print('NullFire Hub | The Twist FINAL loaded')
