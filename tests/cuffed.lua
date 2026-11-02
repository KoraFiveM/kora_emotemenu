-- Run from this resource: lua tests/cuffed.lua
-- Checks that a cuffed player cannot start an emote (plain, shared or from the menu keybind
-- path) and that a running emote is cancelled by the cancel monitor once they are cuffed.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host()
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { exports = {}, played = 0, serverEvents = {}, threads = {}, events = {} }
    local function deepClone(value)
        if type(value) ~= 'table' then return value end
        local out = {}
        for k, v in pairs(value) do out[k] = deepClone(v) end
        return out
    end
    env.Kora = {
        util = { deepClone = deepClone },
        notify = { send = function() end },
        keybind = { add = function() end },
        controls = { acquire = function() end, release = function() end },
        anim = {
            clear = function() end,
            stop = function() end,
            play = function() h.played = h.played + 1; return {} end,
            playScenario = function() h.played = h.played + 1 end,
        },
        stream = { loadClipSet = function() return true end },
        nui = { registerApp = function() end },
    }
    h.state = { set = function() end }
    env.LocalPlayer = { state = h.state }
    env.PlayerPedId = function() return 1 end
    env.Player = function() return { state = {} } end
    env.PlayerId = function() return 0 end
    env.GetActivePlayers = function() return { 0, 7 } end
    env.GetPlayerPed = function() return 2 end
    env.GetEntityCoords = function() return { x = 0, y = 0, z = 0 } end
    env.GetPlayerServerId = function(id) return id end
    env.DoesEntityExist = function() return true end
    env.IsPedInAnyVehicle = function() return false end
    env.IsPedRagdoll = function() return false end
    env.IsControlJustPressed = function() return false end
    env.ClearPedSecondaryTask = function() end
    env.ClearPedTasksImmediately = function() end
    env.SetPedMovementClipset = function() end
    env.ResetPedMovementClipset = function() end
    env.SetResourceKvp = function() end
    env.GetResourceKvpString = function() return nil end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.IsDuplicityVersion = function() return false end
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function(name, fn) if fn then h.events[name] = fn end end
    env.AddEventHandler = function() end
    env.TriggerServerEvent = function(name) h.serverEvents[#h.serverEvents + 1] = name end
    env.Wait = function() coroutine.yield() end
    env.CreateThread = function(fn)
        local co = coroutine.create(fn)
        h.threads[#h.threads + 1] = co
        assert(coroutine.resume(co))
    end
    env.exports = function(name, fn) h.exports[name] = fn end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile('client/main.lua', 't', env))()
    h.config = env.Config
    h.step = function()
        for _, co in ipairs(h.threads) do
            if coroutine.status(co) ~= 'dead' then assert(coroutine.resume(co)) end
        end
    end
    return h
end

local h = host()
equal(h.config.blockWhenCuffed, true, 'blocking while cuffed is on by default')
equal(h.exports.playEmote('wave'), true, 'a free player emotes')
equal(h.exports.isInEmote(), true, 'emote is running')

-- Being cuffed cancels the running emote on the next frame.
h.state.koraCuffed = true
h.step()
equal(h.exports.isInEmote(), false, 'a running emote is cancelled when the player is cuffed')

local played = h.played
local ok, err = h.exports.playEmote('wave')
equal(ok, false, 'a cuffed player cannot start an emote')
equal(type(err), 'string', 'the refusal says why')
equal(h.exports.playEmote('sit'), false, 'nor a scenario')
equal(h.played, played, 'nothing was played')

local sent = #h.serverEvents
equal(h.exports.playEmote('handshake'), false, 'nor a shared emote')
equal(#h.serverEvents, sent, 'a shared emote request never reaches the server')

-- The keys third-party cuff scripts set keep working, and the option can be turned off.
h.state.koraCuffed = nil
equal(h.exports.playEmote('wave'), true, 'uncuffed players emote again')
h.state.isCuffed = true
h.step()
equal(h.exports.isInEmote(), false, 'legacy isCuffed key still blocks')
h.state.isCuffed = nil
h.state.handcuffed = true
equal(h.exports.playEmote('wave'), false, 'legacy handcuffed key still blocks')
h.config.blockWhenCuffed = false
equal(h.exports.playEmote('wave'), true, 'Config.blockWhenCuffed = false lets cuffed players emote')

print(('kora_emotemenu cuffed checks passed: %d assertions'):format(checks))
