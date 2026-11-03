-- Run from this resource: lua tests/hint.lua
-- Checks the cancel hint, walking with hands up, and the active walk/expression marker in the menu.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host()
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { exports = {}, shown = {}, hidden = {}, acquired = {}, menus = {} }
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
        controls = {
            acquire = function(list) h.acquired[#h.acquired + 1] = list return {} end,
            release = function() end,
        },
        anim = { clear = function() end, stop = function() end, play = function() return {} end, playScenario = function() end },
        stream = { loadClipSet = function() return true end },
        textui = {
            show = function(text, opts) h.shown[#h.shown + 1] = { text = text, opts = opts } return #h.shown end,
            hide = function(id) h.hidden[#h.hidden + 1] = id end,
        },
        nui = {
            registerApp = function() end,
            openRadialMenu = function(items) h.menus[#h.menus + 1] = items return { cancelled = true } end,
        },
    }
    env.LocalPlayer = { state = { set = function() end } }
    env.PlayerPedId = function() return 1 end
    env.DoesEntityExist = function() return true end
    env.IsPedInAnyVehicle = function() return false end
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
    env.AddEventHandler = function() end
    env.TriggerServerEvent = function() end
    env.CreateThread = function() end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile('client/main.lua', 't', env))()
    h.config = env.Config
    return h
end

local function entry(items, id)
    for _, item in ipairs(items) do if item.id == id then return item end end
end

-- Defaults.
local h = host()
equal(h.config.cancelHint.enabled, true, 'cancelHint default on')
equal(h.config.handsUpAllowMovement, true, 'handsUpAllowMovement default on')

-- The hint shows the configured key for looping and scenario emotes and is hidden on cancel.
equal(h.exports.playEmote('wave'), true, 'wave plays')
equal(#h.shown, 1, 'hint shown for a looping emote')
equal(h.shown[1].opts.key, 'X', 'hint shows the cancel key without the t_ prefix')
h.exports.cancelEmote()
equal(h.hidden[#h.hidden], 1, 'hint hidden on cancel')
h.exports.playEmote('sit')
equal(#h.shown, 2, 'hint shown for a scenario')
h.exports.playEmote('wave')
equal(#h.hidden, 2, 'starting another emote hides the old hint first')
h.config.cancelHint.enabled = false
h.exports.playEmote('wave')
equal(#h.shown, 3, 'no hint when disabled')

-- Hands up keeps combat blocked but lets the player walk.
h = host()
h.exports.playEmote('surrender')
local blocked = {}
for _, control in ipairs(h.acquired[1]) do blocked[control] = true end
equal(blocked[30], nil, 'walk control not blocked')
equal(blocked[24], true, 'attack still blocked')
equal(blocked[25], true, 'aim still blocked')
h.config.handsUpAllowMovement = false
h.exports.playEmote('surrender')
equal(#h.acquired[2], #h.config.blockedControls, 'option off blocks every configured control')

-- The menu marks the active walk style and expression.
h = host()
h.exports.toggleMenu()
local items = h.menus[1]
equal(entry(entry(items, 'walk').submenu.items, 'walk:default').icon, 'CircleCheck', 'default walk marked initially')
equal(entry(entry(items, 'walk').submenu.items, 'walk:default').iconColor, '#95FF00', 'theme colour used')
h.exports.setWalk('brave')
h.exports.setExpression('angry')
h.exports.toggleMenu()
items = h.menus[2]
equal(entry(entry(items, 'walk').submenu.items, 'walk:brave').icon, 'CircleCheck', 'brave walk marked')
equal(entry(entry(items, 'walk').submenu.items, 'walk:default').icon, 'Circle', 'default walk unmarked')
equal(entry(entry(items, 'expression').submenu.items, 'expression:angry').description, 'Currently active', 'angry marked')
h.exports.resetWalk()
h.exports.resetExpression()
h.exports.toggleMenu()
items = h.menus[3]
equal(entry(entry(items, 'walk').submenu.items, 'walk:default').icon, 'CircleCheck', 'reset walk marks default')
equal(entry(entry(items, 'expression').submenu.items, 'expression:default').icon, 'CircleCheck', 'reset expression marks default')
equal(entry(entry(items, 'expression').submenu.items, 'expression:angry').icon, 'Circle', 'angry unmarked after reset')

print(('kora_emotemenu hint checks passed: %d assertions'):format(checks))
