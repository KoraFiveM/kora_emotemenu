-- Run from this resource: lua tests/expressions.lua
-- Checks facial expression overrides, state bag sync to other players and the
-- optional proximity notice against stubbed natives.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host(configure)
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { exports = {}, overrides = {}, cleared = {}, notices = {}, threads = {}, bags = {}, states = {}, loadedDicts = {}, now = 0, coords = {} }
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
        anim = { clear = function() end, play = function() return {} end, playScenario = function() end },
        stream = {},
        nui = { registerApp = function() end },
    }
    env.LocalPlayer = { state = { set = function(_, key, value) h.states[key] = value end } }
    env.Player = function(id) h.bags[id] = h.bags[id] or {} return { state = h.bags[id] } end
    h.males = { [1] = true, [20] = true, [30] = true }
    local vec = {}
    vec.__index = vec
    vec.__sub = function(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vec) end
    vec.__len = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
    local function at(x) return setmetatable({ x = x, y = 0, z = 0 }, vec) end
    h.coords = { [1] = at(0), [20] = at(1), [30] = at(50) }
    env.PlayerPedId = function() return 1 end
    env.IsPedInAnyVehicle = function() return false end
    env.PlayerId = function() return 0 end
    env.GetActivePlayers = function() return { 0, 2, 3 } end
    env.GetPlayerPed = function(player) return player == 2 and 20 or player == 3 and 30 or 1 end
    env.GetPlayerServerId = function(player) return player + 100 end
    env.GetEntityCoords = function(ped) local c = h.coords[ped] return c end
    env.DoesEntityExist = function() return true end
    env.IsPedMale = function(ped) return h.males[ped] == true end
    env.HasAnimDictLoaded = function(dict) return h.loadedDicts[dict] == true end
    env.RequestAnimDict = function(dict) h.loadedDicts[dict] = true h.requested = (h.requested or 0) + 1 end
    env.SetFacialIdleAnimOverride = function(ped, name, dict) h.overrides[ped] = { name = name, dict = dict } end
    env.ClearFacialIdleAnimOverride = function(ped) h.overrides[ped] = nil h.cleared[#h.cleared + 1] = ped end
    env.GetGameTimer = function() return h.now end
    env.GetResourceKvpString = function() return nil end
    env.SetResourceKvp = function() end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.IsDuplicityVersion = function() return false end
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function() end
    env.AddEventHandler = function(name, fn) if name == 'onClientResourceStop' then h.onStop = fn end end
    env.TriggerServerEvent = function() end
    env.Wait = function() coroutine.yield() end
    env.CreateThread = function(fn) h.threads[#h.threads + 1] = coroutine.create(fn) end
    env.exports = function(name, fn) h.exports[name] = fn end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    if configure then configure(env, h) end
    assert(loadfile('client/main.lua', 't', env))()
    h.config = env.Config
    local function step()
        for _, thread in ipairs(h.threads) do
            if coroutine.status(thread) == 'suspended' then assert(coroutine.resume(thread)) end
        end
    end
    step() -- threads run up to their first Wait
    function h.tick()
        h.now = h.now + 1000
        step()
    end
    return h
end

-- Every configured expression is a known facial mood clip, or clears the override.
local KNOWN_MOODS = { mood_angry_1 = true, mood_stressed_1 = true, mood_smug_1 = true, mood_happy_1 = true }
local h = host()
local count = 0
for name, expression in pairs(h.config.expressions) do
    count = count + 1
    if expression.anim then equal(KNOWN_MOODS[expression.anim], true, name .. ' uses a known facial mood clip') end
end
equal(count, 5, 'all five expressions are configured')
equal(h.config.expressions.default.anim, nil, 'default has no override clip')
equal(h.config.expressionNotify.enabled, false, 'notifications default off')

-- Local application: dict requested, clip name only, no dict argument.
for _, name in ipairs({ 'angry', 'stressed', 'smug', 'happy' }) do
    h = host()
    equal(h.exports.setExpression(name), true, name .. ' applies')
    equal(h.overrides[1].name, h.config.expressions[name].anim, name .. ' override clip')
    equal(h.overrides[1].dict, 0, name .. ' override passes no dict')
    equal(h.loadedDicts['facials@gen_male@base'], true, name .. ' male dict requested')
    equal(h.states['kora_emotemenu:expression'], name, name .. ' state bag set')
end

-- Female peds use the female dict.
h = host()
h.males[1] = nil
h.exports.setExpression('angry')
equal(h.loadedDicts['facials@gen_female@base'], true, 'female dict requested')

-- Persists: re-applied by the loop after something clears it, cleared by default.
h = host()
h.exports.setExpression('smug')
h.overrides[1] = nil
h.tick()
equal(h.overrides[1].name, 'mood_smug_1', 'expression re-applied while active')
equal(h.exports.resetExpression(), true, 'reset works')
equal(h.overrides[1], nil, 'default clears the override')
equal(h.states['kora_emotemenu:expression'], nil, 'reset clears the state bag')
h.tick()
equal(h.overrides[1], nil, 'cleared expression is not re-applied')

-- Remote players: applied from their state bag, re-applied on a new ped, cleared when removed.
h = host()
h.bags[102] = { ['kora_emotemenu:expression'] = 'happy' }
h.tick()
equal(h.overrides[20].name, 'mood_happy_1', 'remote expression applied')
equal(h.overrides[30], nil, 'players without a state keep their face')
h.bags[102]['kora_emotemenu:expression'] = 'angry'
h.tick()
equal(h.overrides[20].name, 'mood_angry_1', 'remote change applied')
h.bags[102]['kora_emotemenu:expression'] = nil
h.tick()
equal(h.overrides[20], nil, 'remote expression cleared')

-- Notices: off by default, then once per player+expression until the cooldown passes.
h = host()
h.bags[102] = { ['kora_emotemenu:expression'] = 'angry', characterName = 'Alex Doe' }
h.tick()
equal(#h.notices, 0, 'no notice when disabled')
h.config.expressionNotify.enabled = true
h.tick()
equal(#h.notices, 1, 'notice when enabled and close')
equal(h.notices[1].message, 'Alex Doe appears to be angry', 'notice text uses the character name')
h.tick()
equal(#h.notices, 1, 'not repeated within the cooldown')
h.now = h.now + h.config.expressionNotify.cooldown * 1000
h.tick()
equal(#h.notices, 2, 'repeated after the cooldown')
h.bags[102]['kora_emotemenu:expression'] = 'happy'
h.tick()
equal(#h.notices, 3, 'a different expression is announced separately')
h.bags[102].characterName = nil
h.bags[102]['kora_emotemenu:expression'] = 'smug'
h.tick()
equal(h.notices[4].message, 'Someone appears to be smug', 'generic name fallback')
h.bags[103] = { ['kora_emotemenu:expression'] = 'angry' }
h.tick()
equal(#h.notices, 4, 'players beyond the distance are not announced')
h.config.expressionNotify.distance = 100
h.tick()
equal(#h.notices, 5, 'configured distance is read at use time')

-- Stopping the resource clears the local override and state.
h = host()
h.exports.setExpression('angry')
h.onStop('kora_emotemenu')
equal(h.overrides[1], nil, 'stop clears the override')
equal(h.states['kora_emotemenu:expression'], nil, 'stop clears the state bag')

print(('kora_emotemenu expression checks passed: %d assertions'):format(checks))
