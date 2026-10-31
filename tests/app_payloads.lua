-- Run from this resource: lua tests/app_payloads.lua
-- Runs every payload client/main.lua sends to kora_lib (registerApp, updateApp,
-- context/radial items) through a stub that mirrors kora_lib's validators in
-- modules/nui/client.lua, and checks a registration failure falls back cleanly.
local checks = 0
local function ok(cond, message) checks = checks + 1 assert(cond, message) end
local function str(v) return type(v) == 'string' and v ~= '' end

-- Mirrors assertAppAction / assertListItems / assertAppContent / assertBrowserApp.
local function assertAction(a, loc, ids)
    ok(type(a) == 'table' and str(a.id) and str(a.label), loc .. ' action needs id and label')
    ok(a.disabled == nil or type(a.disabled) == 'boolean', loc .. ' action disabled must be boolean')
    ids[a.id] = true
end
local function assertList(items, loc, ids)
    ok(type(items) == 'table', loc .. ' requires items')
    local seen = {}
    for i, item in ipairs(items) do
        local l = ('%s item %d'):format(loc, i)
        ok(type(item) == 'table' and str(item.id), l .. ' requires an id')
        ok(not seen[item.id], l .. ' duplicated id ' .. item.id)
        ok(str(item.label), l .. ' requires a label')
        ok(item.description == nil or type(item.description) == 'string', l .. ' description')
        ok(item.icon == nil or type(item.icon) == 'string', l .. ' icon')
        if item.action ~= nil then
            if type(item.action) == 'table' then assertAction(item.action, l, ids) else ids[item.action] = true end
        end
        seen[item.id] = true
    end
end
local function assertContent(content, loc, ids)
    if content == nil then return end
    ok(content.title == nil or type(content.title) == 'string', loc .. ' title')
    if content.blocks == nil then return end
    local blockIds = {}
    for i, block in ipairs(content.blocks) do
        local l = ('%s block %d'):format(loc, i)
        ok(type(block) == 'table' and (block.type == 'list' or block.type == 'empty' or block.type == 'text'), l .. ' invalid type')
        if block.id ~= nil then
            ok(str(block.id) and not blockIds[block.id], l .. ' bad or duplicated id')
            blockIds[block.id] = true
        end
        if block.type == 'list' then assertList(block.items, l, ids) end
        if block.type == 'empty' then ok(str(block.title), l .. ' requires a title') end
    end
end
local function assertApp(def)
    ok(str(def.id) and def.id:match('^[%w_:%.%-]+$'), 'app id')
    ok(str(def.title), 'app title')
    ok(type(def.navigation) == 'table' and #def.navigation > 0, 'app needs a view')
    local views, ids = {}, {}
    for i, view in ipairs(def.navigation) do
        ok(type(view) == 'table' and str(view.id) and str(view.label), ('view %d needs id and label'):format(i))
        ok(not views[view.id], 'duplicated view ' .. view.id)
        views[view.id] = true
        assertContent(view.content, ("App view '%s'"):format(view.id), ids)
    end
end
local function assertMenuItems(items, ctx)
    ok(type(items) == 'table', ctx .. ' items')
    for i, item in ipairs(items) do
        ok(str(item.id) and str(item.label), ('%s item %d needs id and label'):format(ctx, i))
        ok(item.disabled == nil or type(item.disabled) == 'boolean', ctx .. ' disabled')
        for _, f in ipairs({ 'description', 'icon' }) do ok(item[f] == nil or type(item[f]) == 'string', ctx .. ' ' .. f) end
        if item.submenu then assertMenuItems(item.submenu.items, ctx .. ' submenu') end
    end
end

local function host(configure)
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { prints = {}, registered = nil, updates = {}, opened = 0, menus = {} }
    env.print = function(...) h.prints[#h.prints + 1] = table.concat({ ... }, ' ') end
    local function clone(v) if type(v) ~= 'table' then return v end local o = {} for k, x in pairs(v) do o[k] = clone(x) end return o end
    env.Kora = {
        util = { deepClone = clone },
        notify = { send = function() end }, keybind = { add = function() end },
        controls = { acquire = function() end, release = function() end },
        anim = { clear = function() end, play = function() return {} end, playScenario = function() end },
        stream = {},
        nui = {
            registerApp = function(def) assertApp(def) h.registered = def end,
            updateApp = function(id, update)
                local candidate = {}
                for k, v in pairs(h.registered) do candidate[k] = v end
                for k, v in pairs(update) do candidate[k] = v end
                assertApp(candidate)
                h.updates[#h.updates + 1] = update
            end,
            openApp = function() h.opened = h.opened + 1 return { closed = true } end,
            openContextMenu = function(items) assertMenuItems(items, 'context') h.menus[#h.menus + 1] = 'context' return { cancelled = true } end,
            openRadialMenu = function(items) assertMenuItems(items, 'radial') h.menus[#h.menus + 1] = 'radial' return { cancelled = true } end,
        },
    }
    env.LocalPlayer = { state = { set = function() end } }
    env.PlayerPedId = function() return 1 end
    env.DoesEntityExist = function() return true end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.IsDuplicityVersion = function() return false end
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function() end
    env.AddEventHandler = function() end
    env.TriggerServerEvent = function() end
    env.CreateThread = function() end
    h.exports = {}
    env.exports = function(name, fn) h.exports[name] = fn end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    if configure then configure(env, h) end
    assert(loadfile('client/main.lua', 't', env))()
    h.config = env.Config
    return h
end

-- The registered "empty" view carries a title, as kora_lib requires.
local h = host()
ok(h.registered, 'app registers at start')
ok(h.registered.navigation[1].content.blocks[1].title == 'Emotes', 'empty block has a title')

-- Every style opens with valid payloads, including updateApp navigation.
for _, style in ipairs({ 'radial', 'context', 'app' }) do
    h.config.menuStyle = style
    h.exports.toggleMenu()
end
ok(#h.updates == 1 and h.opened == 1, 'app style updated and opened the app')
ok(#h.updates[1].navigation > 0, 'app navigation is not empty')

-- Empty option groups and an empty category never produce empty pages.
h = host(function(env) env.Config.walks = {} env.Config.expressions = {} end)
h.config.menuStyle = 'app'
h.exports.toggleMenu()
for _, view in ipairs(h.updates[1].navigation) do
    ok(view.id ~= 'walk' and view.id ~= 'expression', 'empty option groups are omitted')
    for _, block in ipairs(view.content.blocks) do ok(block.type ~= 'list' or #block.items > 0, 'no empty list blocks') end
end

-- A failing registration must not break the menu: warn once and fall back.
h = host(function(env, host)
    env.Kora.nui.registerApp = function() error("App view 'empty' block 1 requires a title.") end
end)
for _, style in ipairs({ 'radial', 'context', 'app' }) do
    h.config.menuStyle = style
    h.exports.toggleMenu()
end
h.config.menuStyle = 'app'
h.exports.toggleMenu()
ok(h.menus[#h.menus] == 'radial' and h.menus[3] == 'radial', 'app style falls back to radial')
ok(#h.prints == 1, 'exactly one warning is logged, got ' .. #h.prints)

print(('kora_emotemenu app payload checks passed: %d assertions'):format(checks))
