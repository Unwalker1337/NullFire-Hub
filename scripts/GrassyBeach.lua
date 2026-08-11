-- NullFire Endless Grass | FINAL
-- RE findings: memory collection is client-fired (GotMemory(memoryPart) per MemoryRecollector* part),
-- DepositInteract is no-arg spam, exit flow = Cutscene attr + teleport to EndingTPPlace + ReachedEnd,
-- DreadPeak finale model is spawned CLIENT-side at GameState>=2 (killable before/after),
-- PlayerCopies clones are client-created and never respawn if deleted, device attr is client-set.

local placeId = game.PlaceId
if placeId ~= 129251655434632 then
    warn("NullFire Hub: this script works only in Grassy Beach. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Endless Grass FINAL',
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

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ========== Device check bypass ==========
LocalPlayer:SetAttribute("device", "pc")
print("[Device] Forced PC mode")

-- ========== Tabs ==========
local Tabs = {
    Progress = Window:AddTab('Progress'),
    Memories = Window:AddTab('Memories'),
    Player = Window:AddTab('Player'),
    Visual = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ========== 1. PROGRESS ==========
local progGroup = Tabs.Progress:AddLeftGroupbox('Stage Control')

progGroup:AddButton({ Text = 'Auto-collect memories (instant)', Func = function()
    local remote = ReplicatedStorage:FindFirstChild('GotMemory')
    if not remote then warn('GotMemory not found'); return end
    local recollectors = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("MemoryRecollector") then
            table.insert(recollectors, obj)
        end
    end
    if #recollectors > 0 then
        for _, rec in ipairs(recollectors) do
            remote:FireServer(rec)
            task.wait(0.1)
        end
        print('[Progress] GotMemory fired for', #recollectors, 'recollectors')
    else
        for i = 1, 10 do
            remote:FireServer(Instance.new('Part'))
            task.wait(0.05)
        end
        print('[Progress] Sent 10 GotMemory signals (dummy)')
    end
    workspace:SetAttribute('MemoryLeft', 0)
end })

progGroup:AddButton({ Text = 'Finish collection (DepositInteract)', Func = function()
    fire('DepositInteract')
    workspace:SetAttribute('MemoryLeft', 0)
end })

progGroup:AddButton({ Text = 'Activate exit (TrueExit + ReachedEnd)', Func = function()
    local exit = workspace:FindFirstChild('TrueExit')
    if exit then safeTeleport(exit.CFrame * CFrame.new(0, 2, 0)) end
    task.wait(0.3)
    workspace:SetAttribute('Cutscene', true)
    fire('ReachedEnd')
    print('[Progress] ReachedEnd fired')
end })

progGroup:AddButton({ Text = 'Skip straight to ending (GameState>=2)', Func = function()
    workspace:SetAttribute('GameState', 2)
    workspace:SetAttribute('MemoryLeft', 0)
    local exit = workspace:FindFirstChild('TrueExit')
    if exit then exit.Transparency = 1 end
end })

progGroup:AddButton({ Text = 'Teleport to TrueExit', Func = function()
    local exit = workspace:FindFirstChild('TrueExit')
    if exit then safeTeleport(exit.CFrame * CFrame.new(0, 2, 0)) end
end })

progGroup:AddToggle('DisableCutscene', { Text = 'Disable cutscene', Default = false }):OnChanged(function(v)
    if v then
        workspace:SetAttribute('Cutscene', nil)
        workspace:SetAttribute('ScriptedFOV', nil)
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if root then root.Anchored = false end
        end
    end
end)

local gsSlider = progGroup:AddSlider('GameState', { Text = 'GameState', Default = 0, Min = 0, Max = 3, Rounding = 0 })
gsSlider:OnChanged(function(v) workspace:SetAttribute('GameState', v) end)

-- ========== 2. MEMORIES ==========
local memGroup = Tabs.Memories:AddLeftGroupbox('Memory ESP & auto')
local memESP = memGroup:AddToggle('MemoryESP', { Text = 'Highlight recollectors', Default = false })
local memHighlightConns = {}
local function refreshMemoryESP()
    for _, conn in ipairs(memHighlightConns) do conn:Disconnect() end
    memHighlightConns = {}
    if not memESP.Value then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:match("MemoryRecollector") then
                local h = obj:FindFirstChild('NF_MemESP')
                if h then h:Destroy() end
            end
        end
        return
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:match("MemoryRecollector") then
            if not obj:FindFirstChild('NF_MemESP') then
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

memGroup:AddButton({ Text = 'Set MemoryLeft = 0', Func = function()
    workspace:SetAttribute('MemoryLeft', 0)
end })

-- ========== 3. PLAYER ==========
local playerGroup = Tabs.Player:AddLeftGroupbox('Speed & noclip')
local speedSlider = playerGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Default = 16, Min = 0, Max = 250, Rounding = 1 })
local noclipToggle = playerGroup:AddToggle('Noclip', { Text = 'Noclip', Default = false })
local noclipConn = nil
local speedLoopConn = nil

local function setWalkSpeed()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild('Humanoid') then
        c.Humanoid.WalkSpeed = speedSlider.Value
    end
end
local function startSpeedLoop()
    if speedLoopConn then return end
    speedLoopConn = RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character then setWalkSpeed() end
    end)
end
local function stopSpeedLoop()
    if speedLoopConn then speedLoopConn:Disconnect(); speedLoopConn = nil end
end
speedSlider:OnChanged(setWalkSpeed)
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

-- ========== 4. VISUALS ==========
local visGroup = Tabs.Visual:AddLeftGroupbox('Effects')
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

visGroup:AddToggle('DisableHallucinations', { Text = 'Disable hallucinations', Default = false }):OnChanged(function(v)
    if v then
        local halluGui = LocalPlayer.PlayerGui:FindFirstChild('MonsterGui')
        if halluGui and halluGui:FindFirstChild('HallucinationFrame') then
            halluGui.HallucinationFrame.Visible = false
        end
        local halluColor = Lighting:FindFirstChild('HallucinationColor')
        if halluColor then halluColor.Enabled = false end
        local halluSound = game.SoundService:FindFirstChild('Music') and game.SoundService.Music:FindFirstChild('HallucinationEffect')
        if halluSound then halluSound.Enabled = false end
        workspace:SetAttribute('HasHallucinations', nil)
    end
end)

visGroup:AddToggle('DisableMotionBlur', { Text = 'Disable motion blur', Default = false }):OnChanged(function(v)
    local blur = Lighting:FindFirstChild('MotionBlur')
    if blur then blur.Enabled = not v end
end)

visGroup:AddToggle('DisableHurlNoise', { Text = 'Disable HurlNoise', Default = false }):OnChanged(function(v)
    if v then workspace:SetAttribute('HurlNoise', nil)
    else workspace:SetAttribute('HurlNoise', true) end
end)

visGroup:AddToggle('DisableScreenshake', { Text = 'Disable camera shake', Default = false }):OnChanged(function(v)
    if v then
        if not _G.screenshakeBlocked then
            local shakeRemote = ReplicatedStorage:FindFirstChild('ScreenshakeRemote')
            local shakeBind = ReplicatedStorage:FindFirstChild('ScreenshakeBindable')
            if shakeRemote then
                _G.oldShakeRemote = shakeRemote.OnClientEvent
                shakeRemote.OnClientEvent = function() end
            end
            if shakeBind then
                _G.oldShakeBind = shakeBind.Event
                shakeBind.Event = function() end
            end
            _G.screenshakeBlocked = true
        end
    else
        if _G.screenshakeBlocked then
            local shakeRemote = ReplicatedStorage:FindFirstChild('ScreenshakeRemote')
            local shakeBind = ReplicatedStorage:FindFirstChild('ScreenshakeBindable')
            if shakeRemote and _G.oldShakeRemote then shakeRemote.OnClientEvent = _G.oldShakeRemote end
            if shakeBind and _G.oldShakeBind then shakeBind.Event = _G.oldShakeBind end
            _G.screenshakeBlocked = false
        end
    end
end)

visGroup:AddToggle('GrassParticles', { Text = 'Disable grass particles', Default = false }):OnChanged(function(v)
    local grass = workspace:FindFirstChild('GrassParent')
    if grass then
        for _, p in ipairs(grass:GetDescendants()) do
            if p:IsA('ParticleEmitter') then p.Enabled = not v end
        end
    end
end)

visGroup:AddSlider('MusicVolume', { Text = 'Background music volume', Default = 1, Min = 0, Max = 1, Rounding = 2 }):OnChanged(function(v)
    local music = workspace:FindFirstChild('BackgroundMusic')
    if music then music.Volume = v end
end)

-- ========== 5. MISC ==========
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

miscGroup:AddButton({ Text = 'Delete DreadPeak', Func = function()
    local dp = workspace:FindFirstChild('DreadPeak')
    if dp then dp:Destroy() end
    local rsDp = ReplicatedStorage:FindFirstChild('DreadPeak')
    if rsDp then rsDp:Destroy() end
    print('[Misc] DreadPeak deleted (workspace + ReplicatedStorage)')
end })
miscGroup:AddButton({ Text = 'Delete player copies', Func = function()
    local copies = workspace:FindFirstChild('PlayerCopies')
    if copies then copies:ClearAllChildren() end
end })
miscGroup:AddButton({ Text = 'Teleport to DreadPeak', Func = function()
    local dp = workspace:FindFirstChild('DreadPeak')
    if dp and dp:FindFirstChild('HumanoidRootPart') then
        safeTeleport(dp.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
    end
end })

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

-- ========== UI Settings ==========
local menuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
menuGroup:AddButton({ Text = 'Unload script', Func = function() Library:Unload() end })
menuGroup:AddLabel('Menu key'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu key' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('NullFire_EndlessGrass_FINAL')
SaveManager:SetFolder('NullFire_EndlessGrass_FINAL')
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
    Library:SetWatermark(('NullFire Grass FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

-- Cleanup
Library:OnUnload(function()
    stopDial()
    stopSpeedLoop()
    if noclipConn then noclipConn:Disconnect() end
    if fullbright.Value then fullbright:SetValue(false) end
    if noFog.Value then noFog:SetValue(false) end
    if _G.screenshakeBlocked then
        local shakeRemote = ReplicatedStorage:FindFirstChild('ScreenshakeRemote')
        local shakeBind = ReplicatedStorage:FindFirstChild('ScreenshakeBindable')
        if shakeRemote and _G.oldShakeRemote then shakeRemote.OnClientEvent = _G.oldShakeRemote end
        if shakeBind and _G.oldShakeBind then shakeBind.Event = _G.oldShakeBind end
    end
end)

print('NullFire Endless Grass FINAL loaded')
