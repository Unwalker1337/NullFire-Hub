-- NullFire Hub | Lobby (FINAL) - unlocked everything edition
-- RE findings: unlock check is client-side (LevelCompletedInfo), journals are client-side (StoredThings),
-- host UI is attribute-driven (IsHostOf + Teleporter attrs), PickDream takes arbitrary strings,
-- LobbyDoorTP takes an arbitrary PlaceId. Server scripts not extractable (FE) - fire & pray.

local placeId = game.PlaceId
if placeId ~= 96775630583143 then
    warn("NullFire Hub: this script works only in the Lobby. Current PlaceId: " .. placeId)
    return
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub | Lobby (FINAL)',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local LocalPlayer = game.Players.LocalPlayer
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')
local TSC = game:GetService('TextChatService')

repeat task.wait() until workspace:GetAttribute('ClientLoadedIn') or #workspace:GetChildren() > 5

-- ========== Greeting (SayThing is client-firable, handles both event kinds) ==========
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

local function safeTeleport(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

local function getLevelInfo()
    local mod = ReplicatedStorage:FindFirstChild('LevelInformation')
    if mod then
        local ok, li = pcall(require, mod)
        if ok and type(li) == 'table' then return li end
    end
    return nil
end

-- ========== Chapter unlock bypass (client-side check) ==========
local function unlockAllLevels()
    local li = getLevelInfo()
    local info = LocalPlayer:FindFirstChild('LevelCompletedInfo')
    if not info then
        info = Instance.new('Folder')
        info.Name = 'LevelCompletedInfo'
        info.Parent = LocalPlayer
    end
    local names = {}
    if li then
        for _, lvl in ipairs(li.levelOrder or {}) do names[#names + 1] = lvl end
    else
        names = {'Reality', 'Cloud Theater', 'Dream Elementary', 'Grassy Beach', 'The Twist',
                 'Chapter 2 Introduction', 'Homescape', 'The Past Future', 'Surreal Woodlands',
                 'The In-Between', 'The Event'}
    end
    for _, lvl in ipairs(names) do
        local found = false
        for _, v in ipairs(info:GetChildren()) do
            if v:IsA('StringValue') and v.Value == lvl then found = true; break end
        end
        if not found then
            local v = Instance.new('StringValue')
            v.Name = 'DreamEntry'
            v.Value = lvl
            v.Parent = info
        end
    end
    LocalPlayer:SetAttribute('CompletedCH2Binary', 1)
    LocalPlayer:SetAttribute('SetUpPlayerFully', true)
    print('[NullFire] All levels unlocked (client-side gating bypassed)')
end

-- ========== Journal spoof (reveals all paintings) ==========
local function collectAllJournals()
    local stored = LocalPlayer:FindFirstChild('StoredThings')
    if not stored then
        stored = Instance.new('Folder')
        stored.Name = 'StoredThings'
        stored.Parent = LocalPlayer
    end
    local li = getLevelInfo()
    local names = {'Reality', 'Cloud Theater', 'Dream Elementary', 'Grassy Beach', 'The Twist'}
    if li then
        names = {}
        for _, lvl in ipairs(li.levelOrder or {}) do names[#names + 1] = lvl end
    end
    for _, lvl in ipairs(names) do
        local found = false
        for _, v in ipairs(stored:GetChildren()) do
            if v:IsA('StringValue') and v.Value == lvl then found = true; break end
        end
        if not found then
            local v = Instance.new('StringValue')
            v.Name = 'DreamEntry'
            v.Value = lvl
            v.Parent = stored
        end
    end
    print('[NullFire] All dream journals added to StoredThings (paintings will show art)')
end

-- ========== Fake host ==========
local function becomeFakeHost()
    LocalPlayer:SetAttribute('IsHostOf', '1')
    LocalPlayer:SetAttribute('SetUpPlayerFully', true)
    task.wait(0.5)
    local teleporters = workspace:FindFirstChild('Teleporters')
    local tp = teleporters and teleporters:FindFirstChild('Teleporter1')
    if tp then
        tp:SetAttribute('PickedLevel', 'Reality')
        tp:SetAttribute('Timer', 5)
        tp:SetAttribute('NumPlayersCurrently', #game.Players:GetPlayers())
        tp:SetAttribute('MaxPlayers', #game.Players:GetPlayers())
        tp:SetAttribute('PlaytestBed', true)
        tp:SetAttribute('EventBed', true)
    end
    print('[NullFire] Fake host set (IsHostOf=1, PlaytestBed+EventBed on)')
end

-- ========== Force start ==========
local function forceStart()
    local start = ReplicatedStorage:FindFirstChild('StartEarly')
    if start then start:FireServer() end
    local li = getLevelInfo()
    local pick = ReplicatedStorage:FindFirstChild('PickDream')
    if pick and li and li.levelOrder and li.levelOrder[1] then
        pick:FireServer(li.levelOrder[1])
    end
    print('[NullFire] Force start fired')
end

-- ========== Level pick ==========
local function pickLevel(name)
    local pick = ReplicatedStorage:FindFirstChild('PickDream')
    if pick then
        pick:FireServer(name)
        print('[NullFire] PickDream fired with:', name)
    else
        warn('PickDream not found')
    end
end

-- ========== Music ==========
local music = ReplicatedStorage:FindFirstChild('LobbyMusic')
local tracks = music and music:GetChildren() or {}
local trackNames = {}
for i, t in ipairs(tracks) do
    table.insert(trackNames, (t:GetAttribute('RealName') or t.Name) .. ' (' .. i .. ')')
end
local currentTrack = 1

local function switchToTrack(idx)
    if not music or #tracks == 0 then return end
    if idx < 1 then idx = #tracks end
    if idx > #tracks then idx = 1 end
    currentTrack = idx
    local tr = tracks[currentTrack]
    music:Stop()
    music.SoundId = tr.SoundId
    music.Volume = tr.Volume or 1
    music:Play()
    local screen = LocalPlayer.PlayerGui:FindFirstChild('OSTTVScreen')
    if screen and screen.Frame and screen.Frame.NowPlayingText then
        screen.Frame.NowPlayingText.Text = "Now Playing: " .. (tr:GetAttribute('RealName') or tr.Name)
    end
end

-- ========== NPCs ==========
local function getNPC(name)
    local rigs = workspace:FindFirstChild('RigNPCS')
    return rigs and rigs:FindFirstChild(name)
end

local function npcBubble(npc, text)
    if npc and npc.Head then TSC:DisplayBubble(npc.Head, text) end
end

-- ========== Tabs ==========
local Tabs = {
    Unlock = Window:AddTab('Unlock'),
    Lobby = Window:AddTab('Lobby'),
    Music = Window:AddTab('Music'),
    NPC = Window:AddTab('NPC'),
    Teleport = Window:AddTab('Teleport'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- ========== 1. UNLOCK ==========
local unlockGroup = Tabs.Unlock:AddLeftGroupbox('Progression bypass')
unlockGroup:AddButton({ Text = 'Unlock ALL chapters', Func = unlockAllLevels })
unlockGroup:AddButton({ Text = 'Collect ALL journals', Func = collectAllJournals })
unlockGroup:AddButton({ Text = 'Unlock + Journals (both)', Func = function()
    unlockAllLevels(); collectAllJournals()
end })
unlockGroup:AddButton({ Text = 'Become host (fake)', Func = becomeFakeHost })
unlockGroup:AddButton({ Text = 'Enable OST TV (CH2 binary)', Func = function()
    LocalPlayer:SetAttribute('CompletedCH2Binary', 1)
end })

local pickGroup = Tabs.Unlock:AddRightGroupbox('Pick level')
local levels = {'Reality', 'Cloud Theater', 'Dream Elementary', 'Grassy Beach', 'The Twist',
                'Chapter 2 Introduction', 'Homescape', 'The Past Future', 'Surreal Woodlands',
                'The In-Between', 'The Event'}
for _, lvl in ipairs(levels) do
    pickGroup:AddButton({ Text = lvl, Func = function() pickLevel(lvl) end })
end
pickGroup:AddInput('CustomLevelInput', { Text = 'Custom level name', Default = 'The Event', Numeric = false, Finished = true })
pickGroup:AddButton({ Text = 'Pick custom level', Func = function()
    pickLevel(Options.CustomLevelInput.Value)
end })

-- ========== 2. LOBBY ==========
local lobbyGroup = Tabs.Lobby:AddLeftGroupbox('Lobby Control')
lobbyGroup:AddButton({ Text = 'Force start (StartEarly)', Func = forceStart })
lobbyGroup:AddButton({ Text = 'Reveal hidden teleporter room', Func = function()
    for _, v in ipairs(CollectionService:GetTagged('WallRemoveOnCompletion')) do
        for _, p in ipairs(v:GetDescendants()) do
            if p:IsA('BasePart') then p.Transparency = 1; p.CanCollide = false end
        end
    end
    local wall = workspace:FindFirstChild('WallRemoveOnCompletion')
    if wall then
        for _, p in ipairs(wall:GetDescendants()) do
            if p:IsA('BasePart') then p.Transparency = 1; p.CanCollide = false end
        end
    end
end })
lobbyGroup:AddButton({ Text = 'Teleport via LobbyDoorTP', Func = function()
    local id = tonumber(Options.LobbyDoorPlace.Value)
    local tp = ReplicatedStorage:FindFirstChild('LobbyDoorTP')
    if tp and id then
        tp:FireServer(id)
        print('[NullFire] LobbyDoorTP fired with PlaceId', id)
    end
end })
lobbyGroup:AddInput('LobbyDoorPlace', { Text = 'PlaceId for LobbyDoorTP', Default = '74323372320017', Numeric = true, Finished = true })

-- ========== 3. MUSIC ==========
local musicGroup = Tabs.Music:AddLeftGroupbox('Music Control')
local trackDrop = musicGroup:AddDropdown('MusicTrack', { Values = trackNames, Default = 1, Text = 'Select track' })
musicGroup:AddButton({ Text = 'Switch', Func = function()
    for i, name in ipairs(trackNames) do
        if name == trackDrop.Value then switchToTrack(i); break end
    end
end })
musicGroup:AddButton({ Text = 'Next track', Func = function() switchToTrack(currentTrack + 1) end })
musicGroup:AddButton({ Text = 'Previous track', Func = function() switchToTrack(currentTrack - 1) end })
musicGroup:AddButton({ Text = 'Stop music', Func = function() if music then music:Stop() end end })
musicGroup:AddButton({ Text = 'Unused tracks ONLY (TV mode)', Func = function()
    for i, t in ipairs(tracks) do
        if t:GetAttribute('Unused') then switchToTrack(i) end
    end
end })
local autoLoop = musicGroup:AddToggle('MusicLoop', { Text = 'Auto-switch (5 sec)', Default = false })
local loopConn = nil
autoLoop:OnChanged(function(val)
    if val then
        if loopConn then loopConn:Disconnect() end
        loopConn = RunService.Heartbeat:Connect(function()
            if autoLoop.Value and tick() - (_G.lastSwitch or 0) >= 5 then
                switchToTrack(currentTrack + 1)
                _G.lastSwitch = tick()
            end
        end)
    else
        if loopConn then loopConn:Disconnect(); loopConn = nil end
    end
end)

-- ========== 4. NPC ==========
local npcGroup = Tabs.NPC:AddLeftGroupbox('NPC')
local peterText = npcGroup:AddInput('PeterText', { Text = 'Text for Minecraftpeter', Default = 'Hello!', Numeric = false, Finished = true })
npcGroup:AddButton({ Text = 'Custom text from Minecraftpeter', Func = function()
    npcBubble(getNPC('Minecraftpeter'), peterText.Value)
end })
npcGroup:AddButton({ Text = 'Original dialogues from Minecraftpeter', Func = function()
    local npc = getNPC('Minecraftpeter')
    if not npc then return end
    local phrases = {"hi", "those pictures on the walls show how many dream journals you collected", "you got that?"}
    task.spawn(function()
        for _, ph in ipairs(phrases) do TSC:DisplayBubble(npc.Head, ph); task.wait(2) end
    end)
end })
npcGroup:AddButton({ Text = 'Teleport to Minecraftpeter', Func = function()
    local npc = getNPC('Minecraftpeter')
    if npc and npc.HumanoidRootPart then safeTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0,0,2)) end
end })

local snoogleText = npcGroup:AddInput('SnoogleText', { Text = 'Text for SnoogleBrosPlayz', Default = 'I am a dev!', Numeric = false, Finished = true })
npcGroup:AddButton({ Text = 'Custom text from Snoogle', Func = function()
    npcBubble(getNPC('SnoogleBrosPlayz'), snoogleText.Value)
end })
npcGroup:AddButton({ Text = 'Original dialogues from Snoogle', Func = function()
    local npc = getNPC('SnoogleBrosPlayz')
    if not npc then return end
    local phrases = {"hi im the developer of the game", "this is my normal avatar", "anyways please enjoy the game"}
    task.spawn(function()
        for _, ph in ipairs(phrases) do TSC:DisplayBubble(npc.Head, ph); task.wait(2.5) end
    end)
end })
npcGroup:AddButton({ Text = 'Teleport to Snoogle', Func = function()
    local npc = getNPC('SnoogleBrosPlayz')
    if npc and npc.HumanoidRootPart then safeTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0,0,2)) end
end })

-- ========== 5. TELEPORT ==========
local teleGroup = Tabs.Teleport:AddLeftGroupbox('Teleports')
teleGroup:AddButton({ Text = 'Main hall spawn', Func = function()
    local s = workspace:FindFirstChild('SpawnLocations') and workspace.SpawnLocations:FindFirstChild('MainHallSpawnLocation')
    if s then safeTeleport(s.CFrame) end
end })
teleGroup:AddButton({ Text = 'Minecraftpeter', Func = function()
    local npc = getNPC('Minecraftpeter')
    if npc and npc.HumanoidRootPart then safeTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0,0,2)) end
end })
teleGroup:AddButton({ Text = 'SnoogleBrosPlayz', Func = function()
    local npc = getNPC('SnoogleBrosPlayz')
    if npc and npc.HumanoidRootPart then safeTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0,0,2)) end
end })
teleGroup:AddButton({ Text = 'Teleporter 1', Func = function()
    local t = workspace:FindFirstChild('Teleporters') and workspace.Teleporters:FindFirstChild('Teleporter1')
    if t then safeTeleport(t.CFrame * CFrame.new(0,2,0)) end
end })
teleGroup:AddInput('CustomCoord', { Text = 'Coordinates X,Y,Z', Default = '0,5,0', Numeric = false, Finished = true })
teleGroup:AddButton({ Text = 'Teleport', Func = function()
    local x,y,z = Options.CustomCoord.Value:match('([^,]+),([^,]+),([^,]+)')
    if x and y and z then safeTeleport(CFrame.new(tonumber(x), tonumber(y), tonumber(z))) end
end })

-- ========== 6. MISC ==========
local miscGroup = Tabs.Misc:AddLeftGroupbox('SayThing & effects')
local sayText = miscGroup:AddInput('SayText', { Text = 'Text', Default = 'hello from nullfire', Numeric = false, Finished = true })
local styleDrop = miscGroup:AddDropdown('SayStyle', {
    Values = {'Normal', 'RedText', 'WeirdcoreText', 'Big', 'Static', 'Scared', 'Yellow', 'Green', 'Objective', 'InfoText'},
    Default = 1,
    Text = 'Style'
})
miscGroup:AddButton({ Text = 'Send', Func = function()
    local map = {
        ['Normal'] = {}, ['RedText'] = {'RedText'}, ['WeirdcoreText'] = {'WeirdcoreText'},
        ['Big'] = {'big'}, ['Static'] = {'static'}, ['Scared'] = {'scared'},
        ['Yellow'] = {'YellowText'}, ['Green'] = {'GreenText'},
        ['Objective'] = {'Objective'}, ['InfoText'] = {'InfoText'}
    }
    say(sayText.Value, map[styleDrop.Value] or {})
end })
miscGroup:AddButton({ Text = 'Anti-cheat taunt (YouCheatedBorder)', Func = function()
    say("What do you think you're doing lil bro", {'InfoText'})
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
ThemeManager:SetFolder('NullFireHub_Lobby_FINAL')
SaveManager:SetFolder('NullFireHub_Lobby_FINAL')
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
    Library:SetWatermark(('NullFire Lobby FINAL | FPS: %s | Ping: %sms'):format(math.floor(fps), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

Library:OnUnload(function()
    if loopConn then loopConn:Disconnect() end
end)

print('[NullFire] Lobby FINAL loaded. PlaceId:', placeId)
