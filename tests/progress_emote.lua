-- Run from this resource: lua tests/progress_emote.lua
-- Checks kora_emotemenu:client:playProgressEmote: it starts the emote with no cancel hint and
-- no cancel monitor, refuses invalid and shared emotes, and leaves normal playback unchanged.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host()
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { exports = {}, handlers = {}, threads = {}, shown = {}, hidden = {}, warnings = {}, state = {}, serverEvents = {} }
    local function deepClone(value)
        if type(value) ~= 'table' then return value end
        local out = {}
        for k, v in pairs(value) do out[k] = deepClone(v) end
        return out
    end
    env.Kora = {
        lang = function(key) return key end,
        logging = { warn = function(key) h.warnings[#h.warnings + 1] = key end },
        util = { deepClone = deepClone },
        notify = { send = function() end },
        keybind = { add = function() end },
        controls = { acquire = function() return {} end, release = function() end },
        anim = { clear = function() end, stop = function() end, play = function() return {} end, playScenario = function() end },
        stream = { loadClipSet = function() return true end },
        textui = {
            show = function(text) h.shown[#h.shown + 1] = text return #h.shown end,
            hide = function(id) h.hidden[#h.hidden + 1] = id end,
        },
        nui = { registerApp = function() end, openRadialMenu = function() return { cancelled = true } end },
    }
    env.LocalPlayer = { state = { set = function(_, key, value) h.state[key] = value end } }
    env.PlayerPedId = function() return 1 end
    env.DoesEntityExist = function() return true end
    env.IsPedInAnyVehicle = function() return false end
    env.IsPedRagdoll = function() return false end
    env.IsControlJustPressed = function() return h.cancelPressed == true end
    env.Wait = function() coroutine.yield() end
    env.SetPedMovementClipset = function() end
    env.ResetPedMovementClipset = function() end
    env.SetResourceKvp = function() end
    env.IsPedMale = function() return true end
    env.RemoveClipSet = function() end
    env.HasAnimDictLoaded = function() return true end
    env.SetFacialIdleAnimOverride = function() end
    env.ClearFacialIdleAnimOverride = function() end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.IsDuplicityVersion = function() return false end
    env.GetControlInstructionalButton = function() return 't_X' end
    env.exports = setmetatable({ kora_theme = {
        getPlayerTheme = function() return nil end,
        getPrimaryColor = function() return '#95FF00' end,
    } }, { __call = function(_, name, fn) h.exports[name] = fn end })
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function() end
    env.AddEventHandler = function(name, fn) h.handlers[name] = fn end
    env.TriggerServerEvent = function(name) h.serverEvents[#h.serverEvents + 1] = name end
    env.CreateThread = function(fn) h.threads[#h.threads + 1] = coroutine.create(fn) end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile('client/main.lua', 't', env))()
    h.threads = {} -- drop the start-up threads (expression loop, persistence)
    h.serverEvents = {} -- drop the start-up requestCreated
    h.config = env.Config
    h.play = function(name) return h.handlers['kora_emotemenu:client:playProgressEmote'](name) end
    -- Resume every live thread once, like one game frame.
    h.step = function()
        local live = 0
        for _, thread in ipairs(h.threads) do
            if coroutine.status(thread) == 'suspended' then
                assert(coroutine.resume(thread))
                if coroutine.status(thread) == 'suspended' then live = live + 1 end
            end
        end
        return live
    end
    return h
end

-- The event is a local handler, and it starts the emote with no hint and no monitor.
local h = host()
equal(type(h.handlers['kora_emotemenu:client:playProgressEmote']), 'function', 'local handler registered')
h.play('wave')
equal(h.state['kora_emotemenu:active'], 'wave', 'progress emote is active')
equal(h.exports.isInEmote(), true, 'isInEmote reports the progress emote')
equal(#h.shown, 0, 'no cancel hint for a progress emote')
equal(#h.threads, 0, 'no cancel monitor for a progress emote')
h.play('Sit')
equal(h.state['kora_emotemenu:active'], 'sit', 'names are lower-cased like /e')
equal(#h.shown, 0, 'no cancel hint for a progress scenario either')

-- The caller stops it through the existing export.
equal(h.exports.cancelEmote(true), true, 'cancelEmote stops the progress emote')
equal(h.state['kora_emotemenu:active'], false, 'state cleared after cancel')

-- Invalid, unknown and shared emotes are refused without starting anything.
h = host()
h.play(nil)
h.play('')
h.play('definitely_not_an_emote')
h.play('handshake')
equal(h.state['kora_emotemenu:active'], nil, 'nothing started for refused emotes')
equal(#h.serverEvents, 0, 'a shared emote sends no sync invite')
equal(#h.warnings, 4, 'every refusal is logged')

-- A cancel monitor left over from a menu emote stops watching once a progress emote replaces it.
h = host()
equal(h.exports.playEmote('wave'), true, 'menu emote plays')
equal(#h.shown, 1, 'menu emote shows the cancel hint')
equal(#h.threads, 1, 'menu emote starts the cancel monitor')
equal(h.step(), 1, 'monitor keeps running for the menu emote')
h.play('dance2')
equal(h.hidden[#h.hidden], 1, 'the menu hint is hidden when the progress emote replaces it')
h.cancelPressed = true
equal(h.step(), 0, 'monitor exits instead of watching the progress emote')
equal(h.state['kora_emotemenu:active'], 'dance2', 'the cancel key does not stop a progress emote')

-- Normal playback after a progress emote is unchanged.
h.cancelPressed = false
h.exports.cancelEmote(true)
equal(h.exports.playEmote('wave'), true, 'menu emote plays again')
equal(#h.shown, 2, 'menu emote shows its hint again')
equal(#h.threads, 2, 'menu emote starts a fresh monitor')
h.cancelPressed = true
h.step()
equal(h.state['kora_emotemenu:active'], false, 'the cancel key still stops a menu emote')

print(('kora_emotemenu progress emote checks passed: %d assertions'):format(checks))
