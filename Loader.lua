--[[
    NullFire Hub Loader | A Broken Dream
    Checks game.PlaceId and loads the matching chapter script.
    Chapters: Lobby, Ch0 Reality, Cloud Theatre, Dream Elementary, Grassy Beach, The Twist,
              Ch2 Introduction, Homescape
]]

local BASE = "https://raw.githubusercontent.com/Unwalker1337/NullFire-Hub/main/scripts/"

local CHAPTERS = {
    [96775630583143]  = "Lobby.lua",           -- A Broken Dream (lobby)
    [108798177610650] = "Chapter0.lua",        -- Reality (Chapter 0)
    [74323372320017]  = "CloudTheatre.lua",    -- Cloud Theater
    [77782724453274]  = "DreamElementary.lua", -- Dream Elementary
    [129251655434632] = "GrassyBeach.lua",     -- Grassy Beach
    [110334679443599] = "Twist.lua",           -- The Twist
    [109245555679847] = "Chapter2Intro.lua",   -- Chapter 2 Introduction
    [73136969954228]  = "Homescape.lua",       -- Homescape
}

local pid = game.PlaceId
local file = CHAPTERS[pid]

if not file then
    return warn("[NullFire] No script for this PlaceId: " .. pid .. " (A Broken Dream chapters only)")
end

local ok, result = pcall(function()
    local src = game:HttpGet(BASE .. file)
    if not src or #src < 100 then error("empty source") end
    return loadstring(src)
end)

if not ok or type(result) ~= "function" then
    return warn("[NullFire] Failed to load " .. file .. ": " .. tostring(ok and result or "fetch failed"))
end

print("[NullFire] Loading " .. file .. " for PlaceId " .. pid)
result()
