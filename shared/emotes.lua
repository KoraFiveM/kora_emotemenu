-- Ped bone ids accepted for prop emotes (GetPedBoneIndex). Names are accepted too
-- and resolve through QBEBoneNames, because MP peds do not expose PH_* skeleton names
-- to GetEntityBoneIndexByName.
QBEBoneNames = {
    SKEL_L_Hand = 18905,
    SKEL_R_Hand = 57005,
    PH_L_Hand = 60309,
    PH_R_Hand = 28422,
    IK_L_Hand = 36029,
    IK_R_Hand = 6286,
}

-- This starter catalogue intentionally contains only Rockstar assets. Addon
-- animation dictionaries and props can be registered at runtime with the
-- registerEmote export; no third-party emote data is bundled here.
-- Dances use flag 1 (looping, full body). Flag 49 is upper-body only, so the legs
-- never danced.
QBEEmotes = {
    wave = {
        label = 'Wave', category = 'general', type = 'anim',
        dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49,
    },
    salute = {
        label = 'Salute', category = 'general', type = 'anim',
        dict = 'anim@mp_player_intincarsalutestd@ds@', clip = 'idle_a', flag = 49,
    },
    surrender = {
        label = 'Hands up', category = 'general', type = 'anim',
        dict = 'missminuteman_1ig_2', clip = 'handsup_base', flag = 49, blockMovement = true,
    },
    sit = {
        label = 'Sit', category = 'scenarios', type = 'scenario',
        scenario = 'WORLD_HUMAN_PICNIC',
    },
    lean = {
        label = 'Lean', category = 'scenarios', type = 'scenario',
        scenario = 'WORLD_HUMAN_LEANING',
    },
    clipboard = {
        label = 'Clipboard', category = 'props', type = 'anim',
        dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49,
        -- Bones are ped bone ids for GetPedBoneIndex. This offset/rotation is the well-known
        -- rpemotes value for IK_L_Hand (36029); it floated away from the hand on SKEL_L_Hand
        -- (18905). Same values suit male and female freemode peds. Tune live with Config.propOverrides.
        prop = { model = 'p_amb_clipboard_01', bone = 36029, offset = { x = 0.16, y = 0.08, z = 0.10 }, rotation = { x = -130.0, y = -50.0, z = 0.0 } },
    },
    coffee = {
        label = 'Coffee', category = 'props', type = 'anim',
        dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c', flag = 49,
        prop = { model = 'p_amb_coffeecup_01', bone = 28422, offset = { x = 0.0, y = 0.0, z = 0.0 }, rotation = { x = 0.0, y = 0.0, z = 130.0 } },
    },
    guitar = {
        label = 'Air guitar', category = 'dance', type = 'anim',
        dict = 'anim@mp_player_intcelebrationmale@air_guitar', clip = 'air_guitar', flag = 1,
    },
    dance = {
        label = 'Dance', category = 'dance', type = 'anim',
        dict = 'mini@strip_club@idles@dj@idle_01', clip = 'idle_01', flag = 1,
    },
    dance2 = {
        label = 'Dance 2', category = 'dance', type = 'anim',
        dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', clip = 'high_center', flag = 1,
    },
    handshake = {
        label = 'Handshake', category = 'shared', type = 'anim',
        dict = 'mp_ped_interaction', clip = 'handshake_guy_a', flag = 0,
        sync = { partner = 'handshake_partner' },
    },
    handshake_partner = {
        label = 'Handshake (partner)', hidden = true, type = 'anim',
        dict = 'mp_ped_interaction', clip = 'handshake_guy_b', flag = 0,
    },
    hug = {
        label = 'Hug', category = 'shared', type = 'anim',
        dict = 'mp_ped_interaction', clip = 'kisses_guy_a', flag = 0,
        sync = { partner = 'hug_partner' },
    },
    hug_partner = {
        label = 'Hug (partner)', hidden = true, type = 'anim',
        dict = 'mp_ped_interaction', clip = 'kisses_guy_b', flag = 0,
    },
}

-- Emotes saved in-game through the emote maker (server/emote_creator.lua) live
-- in shared/created.json. They are merged into the catalogue here at load; the
-- built-in emotes win on a name clash. The file is only read on the server -
-- clients receive the same set from the server when they load, so they never
-- depend on a file that changes at runtime.
if IsDuplicityVersion() then
    QBECreatedEmotes = json.decode(LoadResourceFile(GetCurrentResourceName(), 'shared/created.json') or '{}') or {}
    for name, emote in pairs(QBECreatedEmotes) do
        if QBEEmotes[name] == nil then QBEEmotes[name] = emote end
    end
end
