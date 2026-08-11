--[[
    NullFire Hub Loader V2 | A Broken Dream
    Identical to Loader.lua but under a fresh filename to dodge executor URL-caching.
    Checks game.PlaceId and loads the matching chapter script from scripts/.
    Chapters: Lobby, Ch0 Reality, Cloud Theatre, Dream Elementary, Grassy Beach, The Twist,
              Ch2 Introduction, Homescape
]]

local SOURCES = {
    "https://raw.githubusercontent.com/Unwalker1337/NullFire-Hub/refs/heads/main/scripts/",
    "https://cdn.jsdelivr.net/gh/Unwalker1337/NullFire-Hub@main/scripts/",
    "https://raw.githubusercontent.com/Unwalker1337/NullFire-Hub/main/scripts/",
    "https://github.com/Unwalker1337/NullFire-Hub/raw/refs/heads/main/scripts/",
}

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

local function fetch(path)
    local errors = {}
    for i, base in ipairs(SOURCES) do
        local url = base .. path
        local ok, src = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(src) == "string" and #src >= 100 then
            print("[NullFire] Fetched from source " .. i)
            return src
        end
        errors[i] = url .. " -> " .. tostring(ok and ("short/empty (" .. tostring(type(src) == "string" and #src or type(src)) .. ")") or src)
    end
    return nil, errors
end

local src, errors = fetch(file)
if not src then
    for i, e in ipairs(errors) do
        warn("[NullFire] source " .. i .. ": " .. e)
    end
    return
end

local fn, loadErr = loadstring(src)
if not fn then
    return warn("[NullFire] loadstring failed for " .. file .. ": " .. tostring(loadErr))
end

print("[NullFire] Loading " .. file .. " for PlaceId " .. pid)
local runOk, runErr = pcall(fn)
if not runOk then
    warn("[NullFire] Script error in " .. file .. ": " .. tostring(runErr))
end
