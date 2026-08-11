--[[
    NullFire Hub Loader | A Broken Dream
    Checks game.PlaceId and loads the matching chapter script.
    Chapters: Lobby, Ch0 Reality, Cloud Theatre, Dream Elementary, Grassy Beach, The Twist,
              Ch2 Introduction, Homescape
    Multi-source fetch with real error reporting.
]]

-- Multi-source fetch with real error reporting.
-- refs/heads/main = canonical raw URL (no 302 redirect), some executors fail redirects.

local SOURCES = {
    "https://raw.githubusercontent.com/Unwalker1337/NullFire-Hub/refs/heads/main/",
    "https://cdn.jsdelivr.net/gh/Unwalker1337/NullFire-Hub@main/",
    "https://raw.githubusercontent.com/Unwalker1337/NullFire-Hub/main/",
    "https://github.com/Unwalker1337/NullFire-Hub/raw/refs/heads/main/",
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
    local lastErr = nil
    for i, base in ipairs(SOURCES) do
        local ok, src = pcall(function()
            return game:HttpGet(base .. path)
        end)
        if ok and type(src) == "string" and #src >= 100 then
            print("[NullFire] Fetched from source " .. i .. ": " .. base .. path)
            return src
        else
            lastErr = "source " .. i .. " -> " .. tostring(ok and "short/empty response" or src)
        end
    end
    return nil, lastErr
end

local src, err = fetch(file)
if not src then
    warn("[NullFire] Failed to fetch " .. file .. " from all sources: " .. tostring(err))
    warn("[NullFire] Try manually in executor: game:HttpGet(\"" .. SOURCES[1] .. file .. "\")")
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
