-- This starter catalogue intentionally contains only Rockstar assets. Addon
-- animation dictionaries and props can be registered at runtime with the
-- registerEmote export; no third-party emote data is bundled here.
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
        prop = { model = 'p_amb_clipboard_01', bone = 'IK_R_Hand', offset = { x = 0.16, y = 0.08, z = 0.10 }, rotation = { x = -130.0, y = -50.0, z = 0.0 } },
    },
    coffee = {
        label = 'Coffee', category = 'props', type = 'anim',
        dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c', flag = 49,
        prop = { model = 'p_amb_coffeecup_01', bone = 'IK_R_Hand', offset = { x = 0.10, y = -0.02, z = 0.03 }, rotation = { x = -100.0, y = 0.0, z = 0.0 } },
    },
    guitar = {
        label = 'Air guitar', category = 'dance', type = 'anim',
        dict = 'anim@mp_player_intcelebrationmale@air_guitar', clip = 'air_guitar', flag = 49,
    },
    dance = {
        label = 'Dance', category = 'dance', type = 'anim',
        dict = 'mini@strip_club@idles@dj@idle_01', clip = 'idle_01', flag = 49,
    },
    dance2 = {
        label = 'Dance 2', category = 'dance', type = 'anim',
        dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', clip = 'high_center', flag = 49,
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
