-- Run from this resource: lua tests/menu.lua
-- Loads client/main.lua against stubbed natives and kora_lib to check that
-- Config.menuStyle picks the menu and that every style gets the same items.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host()
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { calls = {}, exports = {}, notices = {}, nextResult = { cancelled = true }, results = {} }
    local function record(kind)
        return function(items, ...)
            h.calls[#h.calls + 1] = { kind = kind, items = items, args = { ... } }
            if #h.results > 0 then return table.remove(h.results, 1) end
            return h.nextResult
        end
    end
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
        nui = {
            openRadialMenu = record('radial'),
            openContextMenu = record('context'),
            registerApp = function(def) h.app = def end,
            updateApp = function(id, update) h.calls[#h.calls + 1] = { kind = 'updateApp', id = id, update = update } end,
            openApp = function(id)
                h.calls[#h.calls + 1] = { kind = 'app', id = id }
                if h.appAction then h.app.onAction(h.appAction) end
                return { closed = true }
            end,
        },
    }
    env.LocalPlayer = { state = { set = function() end } }
    env.PlayerPedId = function() return 1 end
    env.IsPedInAnyVehicle = function() return false end
    env.DoesEntityExist = function() return true end
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
    h.env = env
    return h
end

local function ids(items)
    local out = {}
    for _, item in ipairs(items) do out[#out + 1] = item.id end
    return table.concat(out, ',')
end

-- Default keeps the original radial look.
local h = host()
equal(h.config.menuStyle, 'radial', 'default style')
h.exports.toggleMenu()
equal(h.calls[1].kind, 'radial', 'radial by default')
equal(h.calls[1].args[1].radius, 165, 'radial radius unchanged')
local radialIds = ids(h.calls[1].items)

-- Style is read every time the menu opens.
h.config.menuStyle = 'context'
h.exports.toggleMenu()
equal(h.calls[2].kind, 'context', 'context style')
equal(ids(h.calls[2].items), radialIds, 'context shows the same items as radial')

-- Context: a category opens its own page with a Back row, then returns the choice.
h.config.menuStyle = 'context'
local general
for _, item in ipairs(h.calls[1].items) do if item.id == 'category:general' then general = item end end
h.results = { { selectedId = 'category:general' }, { selectedId = 'menu:back' }, { selectedId = 'category:general' }, { selectedId = 'emote:wave' } }
local before = #h.calls
h.exports.toggleMenu()
equal(#h.calls - before, 4, 'context navigates one page per call')
equal(h.calls[before + 2].items[1].id, 'menu:back', 'sub page starts with Back')
equal(ids(h.calls[before + 2].items), 'menu:back,' .. ids(general.submenu.items), 'sub page lists the category emotes')
equal(ids(h.calls[before + 3].items), radialIds, 'Back returns to the first page')

-- App: items are mapped to views and the chosen action is returned.
h.config.menuStyle = 'app'
h.appAction = 'emote:wave'
before = #h.calls
h.exports.toggleMenu()
equal(h.calls[before + 1].kind, 'updateApp', 'app navigation updated before opening')
equal(h.calls[before + 2].kind, 'app', 'app style opens the app shell')
local navigation = h.calls[before + 1].update.navigation
equal(#navigation, #h.calls[1].items, 'app has one view per top level item')
equal(navigation[1].id, h.calls[1].items[1].id, 'app view order matches')
h.appAction = nil
before = #h.calls
h.exports.toggleMenu()
equal(h.calls[before + 2].kind, 'app', 'closing the app without an action is a cancel')

-- Cancel is enabled while an emote plays and disabled otherwise.
local function cancelItem(items) for _, item in ipairs(items) do if item.id == 'cancel' then return item end end end
h = host()
h.exports.toggleMenu()
equal(cancelItem(h.calls[1].items).disabled, true, 'cancel disabled when idle')
equal(h.exports.playEmote('wave'), true, 'wave plays')
h.calls = {}
h.exports.toggleMenu()
equal(cancelItem(h.calls[1].items).disabled, false, 'cancel enabled while an emote plays')

-- registerEmote must work (it used an undefined copy() helper before).
h.exports.registerEmote('testemote', { label = 'Test', type = 'anim', hidden = true, dict = 'a', clip = 'b' })
equal(h.exports.playEmote('testemote'), true, 'registered emote plays')

print(('kora_emotemenu menu checks passed: %d assertions'):format(checks))
