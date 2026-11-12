-- Run from this resource: lua tests/vehicle.lua
-- Checks that emotes in a vehicle never call ClearPedTasksImmediately (which ejects the player).
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host(inVehicle)
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { log = {}, exports = {}, notices = {}, inVehicle = inVehicle }
    local function log(entry) h.log[#h.log + 1] = entry end
    local function deepClone(value)
        if type(value) ~= 'table' then return value end
        local out = {}
        for k, v in pairs(value) do out[k] = deepClone(v) end
        return out
    end
    env.Kora = {
        util = { deepClone = deepClone },
        notify = { send = function(payload) h.notices[#h.notices + 1] = payload end },
        keybind = { add = function() end },
        controls = { acquire = function() end, release = function() end },
        anim = {
            clear = function(_, immediate) log(immediate and 'clearImmediate' or 'clear') end,
            stop = function() log('stop') end,
            play = function(_, _, _, opts) h.flag = opts.flag; log('play') return {} end,
            playScenario = function() log('scenario') end,
        },
        stream = { loadClipSet = function() return true end },
        nui = { registerApp = function() end },
    }
    env.LocalPlayer = { state = { set = function() end } }
    env.PlayerPedId = function() return 1 end
    env.DoesEntityExist = function() return true end
    env.IsPedInAnyVehicle = function() return h.inVehicle end
    env.ClearPedSecondaryTask = function() log('clearSecondary') end
    env.SetPedMovementClipset = function() log('walk') end
    env.ResetPedMovementClipset = function() end
    env.SetResourceKvp = function() end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.IsDuplicityVersion = function() return false end
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function() end
    env.AddEventHandler = function() end
    env.TriggerServerEvent = function() end
    env.CreateThread = function() end
    env.exports = function(name, fn) h.exports[name] = fn end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile('client/main.lua', 't', env))()
    h.config = env.Config
    return h
end

local function count(h, entry)
    local n = 0
    for _, e in ipairs(h.log) do if e == entry then n = n + 1 end end
    return n
end

-- Defaults are safe.
local h = host(true)
equal(h.config.vehicle.allowEmotes, true, 'allowEmotes default')
equal(h.config.vehicle.upperBodyOnly, true, 'upperBodyOnly default')
equal(#h.config.vehicle.blockedInVehicle, 0, 'blockedInVehicle default empty')

-- Playing and cancelling seated never clears immediately.
equal(h.exports.playEmote('wave'), true, 'wave plays seated')
equal(h.flag, 49, 'looping upper body flag')
equal(h.exports.playEmote('guitar'), true, 'dance plays seated')
equal(h.flag, 49, 'full body loop is reduced to upper body')
h.exports.cancelEmote()
equal(count(h, 'clearImmediate'), 0, 'no ClearPedTasksImmediately in a vehicle')
equal(count(h, 'clear'), 0, 'no ClearPedTasks in a vehicle')
equal(count(h, 'clearSecondary') > 0, true, 'secondary task cleared instead')

-- Scenarios, standing emotes, blocked emotes and walks are refused.
local ok, err = h.exports.playEmote('sit')
equal(ok, false, 'scenario refused seated')
equal(type(err), 'string', 'refusal has a message')
equal(count(h, 'scenario'), 0, 'scenario never started')
equal((h.exports.playEmote('handshake')), false, 'sync emote refused seated')
h.config.vehicle.blockedInVehicle = { 'wave' }
equal((h.exports.playEmote('wave')), false, 'blockedInVehicle refused')
h.config.vehicle.blockedInVehicle = {}
equal((h.exports.setWalk('brave')), false, 'walk style refused seated')
equal(count(h, 'walk'), 0, 'walk clipset not applied')
h.config.vehicle.allowEmotes = false
equal((h.exports.playEmote('wave')), false, 'allowEmotes=false refuses everything')
equal(count(h, 'clearImmediate'), 0, 'refusals never eject')

-- On foot nothing changes.
h = host(false)
equal(h.exports.playEmote('sit'), true, 'scenario plays on foot')
equal(h.exports.playEmote('guitar'), true, 'dance plays on foot')
equal(h.flag, 1, 'flag untouched on foot')
h.exports.cancelEmote()
equal(count(h, 'clearImmediate') > 0, true, 'on foot still clears immediately')

print(('kora_emotemenu vehicle checks passed: %d assertions'):format(checks))
