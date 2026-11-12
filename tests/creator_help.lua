-- Run from this resource: lua tests/creator_help.lua
-- The Emote Maker freecam help is registered as a text entry, so it is not cut at 99 characters.
local checks = 0
local function ok(value, message)
    checks = checks + 1
    assert(value, message)
end

local vecMeta = {}
local function vec3(x, y, z) return setmetatable({ x = x, y = y, z = z }, vecMeta) end
vecMeta.__add = function(a, b) return vec3(a.x + b.x, a.y + b.y, a.z + b.z) end
vecMeta.__sub = function(a, b) return vec3(a.x - b.x, a.y - b.y, a.z - b.z) end
vecMeta.__mul = function(a, b)
    if type(a) == 'number' then a, b = b, a end
    return vec3(a.x * b, a.y * b, a.z * b)
end

local entries, helpLabels, substrings, bag, nuiCallbacks = {}, {}, 0, {}, {}
local exitHint = '~INPUT_FRONTEND_ACCEPT~ Back to menu (Enter / Backspace / Esc)'

local env = setmetatable({
    Config = { emoteMaker = { exitControls = { 191 }, hint = { exit = exitHint }, blockUi = true } },
    Kora = { notify = { send = function() end }, anim = { clear = function() end, play = function() return {} end }, stream = { loadModel = function() end } },
    LocalPlayer = { state = { set = function(_, key, value) bag[#bag + 1] = { key = key, value = value } end } },
    exports = { kora_theme = { getPlayerTheme = function() return '#95FF00' end, getPrimaryColor = function() return '#95FF00' end } },
    vec3 = vec3,
    AddEventHandler = function() end,
    RegisterNetEvent = function() end,
    RegisterNUICallback = function(name, handler) nuiCallbacks[name] = handler end,
    TriggerServerEvent = function() end,
    SendNUIMessage = function() end,
    SetNuiFocus = function() end,
    PlayerPedId = function() return 1 end,
    DoesEntityExist = function() return true end,
    GetEntityHeading = function() return 90.0 end,
    GetEntityCoords = function() return vec3(1.0, 2.0, 3.0) end,
    CreateCam = function() return 7 end,
    SetCamCoord = function() end,
    SetCamRot = function() end,
    SetCamActive = function() end,
    RenderScriptCams = function() end,
    DestroyCam = function() end,
    CreateThread = function(fn) fn() end,
    Wait = function() end,
    GetFrameTime = function() return 0.016 end,
    DisableAllControlActions = function() end,
    DisableControlAction = function() end,
    GetDisabledControlNormal = function() return 0.0 end,
    IsDisabledControlPressed = function() return false end,
    IsDisabledControlJustPressed = function(_, control) return control == 191 end,
    AddTextEntry = function(name, text) entries[name] = text end,
    BeginTextCommandDisplayHelp = function(label) helpLabels[#helpLabels + 1] = label end,
    AddTextComponentSubstringPlayerName = function() substrings = substrings + 1 end,
    EndTextCommandDisplayHelp = function() end,
}, { __index = _G })

local chunk = assert(loadfile('client/emote_creator.lua', 't', env))
chunk()

nuiCallbacks['creator:action']({ action = 'freecam' }, function() end)

local label = helpLabels[1]
ok(label and label ~= 'STRING', 'help is drawn from a registered text entry, not a STRING substring')
ok(substrings == 0, 'no 99-character substring is used for the help')
local text = entries[label]
ok(type(text) == 'string' and #text > 99, 'the registered help is longer than a substring could hold')
ok(text:sub(1, #exitHint) == exitHint, 'the exit key leads the help')
for _, token in ipairs({ '~INPUT_MOVE_RIGHT_ONLY~ Move', '~INPUT_LOOK_LR~ Look', '~INPUT_COVER~ Up', '~INPUT_PICKUP~ Down', '~INPUT_SPRINT~ Fast', '~INPUT_DUCK~ Slow' }) do
    ok(text:find(token, 1, true), 'help keeps ' .. token)
end
ok(bag[1] and bag[1].key == 'koraUiBlocked' and bag[1].value == true, 'freecam sets the UI-block bag')
ok(bag[2] and bag[2].value == nil, 'leaving freecam with Enter clears the UI-block bag')

print(('creator_help: %d checks passed'):format(checks))
