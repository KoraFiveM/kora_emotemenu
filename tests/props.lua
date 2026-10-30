-- Run from this resource: lua tests/props.lua
-- Checks prop data and the attach path (bone names vs numeric bone ids and
-- Config.propOverrides merging) against stubbed natives.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

-- Allowed ped bone ids for GetPedBoneIndex: left/right hand, hand placeholders and hand IK.
-- PH_* strings are not valid GetEntityBoneIndexByName lookups on MP peds, so built-in data uses ids.
local VALID_BONES = { [18905] = true, [57005] = true, [60309] = true, [28422] = true, [36029] = true, [6286] = true }
local KNOWN_MODELS = { p_amb_clipboard_01 = true, p_amb_coffeecup_01 = true }

local function host()
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    local h = { exports = {}, attached = {}, deleted = {}, boneLookups = {} }
    local function deepClone(value)
        if type(value) ~= 'table' then return value end
        local out = {}
        for k, v in pairs(value) do out[k] = deepClone(v) end
        return out
    end
    env.QB = {
        util = { deepClone = deepClone },
        notify = { send = function() end },
        keybind = { add = function() end },
        controls = { acquire = function() end, release = function() end },
        anim = { clear = function() end, play = function() return {} end, playScenario = function() end },
        stream = { loadModel = function(model, cb) cb(model) return model end },
        nui = { registerApp = function() end },
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
    env.exports = function(name, fn) h.exports[name] = fn end
    env.GetEntityBoneIndexByName = function(_, bone) h.boneLookups[#h.boneLookups + 1] = bone return -1 end
    env.GetPedBoneIndex = function(_, bone) h.boneLookups[#h.boneLookups + 1] = bone return 9 end
    env.CreateObjectNoOffset = function() return 50 end
    env.AttachEntityToEntity = function(...) h.attached[#h.attached + 1] = table.pack(...) end
    env.DetachEntity = function() end
    env.DeleteEntity = function(prop) h.deleted[#h.deleted + 1] = prop end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile('client/main.lua', 't', env))()
    h.config, h.emotes = env.Config, env.QBEEmotes
    return h
end

local h = host()
equal(next(h.config.propOverrides), nil, 'propOverrides default empty')

-- Data validation for every built-in prop.
local function isNumbers(t) return type(t) == 'table' and type(t.x) == 'number' and type(t.y) == 'number' and type(t.z) == 'number' end
local propCount = 0
for name, emote in pairs(h.emotes) do
    for _, slot in ipairs({ 'prop', 'proptwo' }) do
        local prop = emote[slot]
        if prop then
            propCount = propCount + 1
            equal(KNOWN_MODELS[prop.model], true, name .. ' prop model')
            equal(type(prop.bone), 'number', name .. ' prop bone must be a numeric ped bone id')
            equal(VALID_BONES[prop.bone], true, name .. ' prop bone must be an allowed hand bone')
            equal(isNumbers(prop.offset), true, name .. ' offset')
            equal(isNumbers(prop.rotation), true, name .. ' rotation')
        end
    end
end
equal(propCount >= 2, true, 'prop emotes are present')

-- Bone ids resolve through GetPedBoneIndex, never a PH_* name lookup.
equal(h.exports.playEmote('clipboard'), true, 'clipboard plays')
equal(h.boneLookups[1], 18905, 'clipboard uses the left hand bone id')
equal(h.attached[1][3], 9, 'attached to the resolved bone index')
equal(h.attached[1][4], 0.16, 'shared offset used by default')

-- Overrides merge over the shared data, field by field, read at play time.
h = host()
h.config.propOverrides.clipboard = { prop = { bone = 'PH_R_Hand', offset = { x = 0.0, y = 0.0, z = 0.0 } } }
h.exports.playEmote('clipboard')
equal(h.boneLookups[1], 28422, 'named override bone maps to its ped bone id')
equal(h.attached[1][4], 0.0, 'override offset')
equal(h.attached[1][7], -130.0, 'rotation not overridden stays shared')
h.exports.cancelEmote()
equal(h.deleted[1], 50, 'prop deleted on cancel')

-- Coffee uses the right hand bone id.
h = host()
equal(h.exports.playEmote('coffee'), true, 'coffee plays')
equal(h.boneLookups[1], 28422, 'coffee uses the right hand bone id')
equal(#h.boneLookups, 1, 'no name based lookup is used')

-- Unknown bone names fail with a message instead of attaching.
h = host()
h.exports.registerEmote('badbone', { label = 'Bad', type = 'anim', hidden = true, dict = 'a', clip = 'b',
    prop = { model = 'p_amb_clipboard_01', bone = 'NOT_A_BONE', offset = { x = 0, y = 0, z = 0 }, rotation = { x = 0, y = 0, z = 0 } } })
local badOk, boneErr = h.exports.playEmote('badbone')
equal(badOk, false, 'unknown bone name does not play')
equal(boneErr, 'Bone NOT_A_BONE does not exist on the ped.', 'unknown bone is reported')

-- Emote-maker emotes store numeric bone ids.
h = host()
h.exports.registerEmote('maker', { label = 'Maker', type = 'anim', hidden = true, dict = 'a', clip = 'b',
    prop = { model = 'p_amb_clipboard_01', bone = 28422, offset = { x = 0, y = 0, z = 0 }, rotation = { x = 0, y = 0, z = 0 } } })
equal(h.exports.playEmote('maker'), true, 'numeric bone emote plays')
equal(h.boneLookups[1], 28422, 'numeric bone resolved with GetPedBoneIndex')
equal(h.attached[1][3], 9, 'numeric bone index used')

print(('kora_emotemenu prop checks passed: %d assertions'):format(checks))
