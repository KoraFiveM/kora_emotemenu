-- Run from this resource: lua tests/emotes.lua
-- Natives cannot run offline, so every built-in animation is checked against a
-- list of dictionary/clip pairs known to exist in GTA V. A new built-in emote
-- must be added here once its names have been confirmed.
local KNOWN_CLIPS = {
    ['friends@frj@ig_1'] = { wave_a = true },
    ['anim@mp_player_intincarsalutestd@ds@'] = { idle_a = true },
    ['missminuteman_1ig_2'] = { handsup_base = true },
    ['missheistdockssetup1clipboard@base'] = { base = true },
    ['amb@world_human_drinking@coffee@male@idle_a'] = { idle_c = true },
    ['anim@mp_player_intcelebrationmale@air_guitar'] = { air_guitar = true },
    ['mini@strip_club@idles@dj@idle_01'] = { idle_01 = true },
    ['anim@amb@nightclub@mini@dance@dance_solo@male@var_b@'] = { high_center = true },
    ['mp_ped_interaction'] = { handshake_guy_a = true, handshake_guy_b = true, kisses_guy_a = true, kisses_guy_b = true },
}
local KNOWN_SCENARIOS = { WORLD_HUMAN_PICNIC = true, WORLD_HUMAN_LEANING = true }
local LOOPING_DANCE_FLAG = 1

local env = {}
for name, value in pairs(_G) do env[name] = value end
env.IsDuplicityVersion = function() return false end
assert(loadfile('config.lua', 't', env))()
assert(loadfile('shared/emotes.lua', 't', env))()

local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

for name, emote in pairs(env.QBEEmotes) do
    check(type(emote.label) == 'string' and emote.label ~= '', name .. ': label')
    check(emote.hidden or env.Config.categories[emote.category], name .. ': visible emotes need a configured category')
    if emote.type == 'anim' then
        check(KNOWN_CLIPS[emote.dict] and KNOWN_CLIPS[emote.dict][emote.clip], ('%s: unknown dict/clip %s/%s'):format(name, tostring(emote.dict), tostring(emote.clip)))
        check(math.type(emote.flag) == 'integer', name .. ': flag must be an integer')
    elseif emote.type == 'scenario' then
        check(KNOWN_SCENARIOS[emote.scenario], name .. ': unknown scenario ' .. tostring(emote.scenario))
    else
        check(false, name .. ': type must be anim or scenario')
    end
    if emote.sync then
        local partner = env.QBEEmotes[emote.sync.partner]
        check(partner and partner.hidden, name .. ': sync partner must be a hidden emote')
    end
end

-- Dances must loop and animate the whole body (flag 49 is upper body only).
for name, emote in pairs(env.QBEEmotes) do
    if emote.category == 'dance' then check(emote.flag == LOOPING_DANCE_FLAG, name .. ': dances use flag 1') end
end

print(('kora_emotemenu emote data checks passed: %d assertions'):format(checks))
