Config = {}

Config.command = 'emotes'
Config.keybind = {
    name = 'qbemotemenu_open',
    label = 'Open emote menu',
    defaultKey = 'F3',
}

Config.syncDistance = 3.0
Config.syncInviteTTL = 10000
Config.syncCooldown = 3000
Config.persistAppearance = true
Config.cancelControl = 73 -- X

-- These controls are disabled while an emote explicitly opts into blocking
-- movement. Combat is deliberately never disabled globally: the animation
-- itself is cancelled if the player needs to defend themselves.
Config.blockedControls = { 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35 }

Config.categories = {
    general = { label = 'General', icon = 'MessageCircle' },
    dance = { label = 'Dances', icon = 'Music2' },
    props = { label = 'Props', icon = 'Package' },
    scenarios = { label = 'Scenarios', icon = 'MapPin' },
    shared = { label = 'Shared', icon = 'Users' },
}

Config.walks = {
    default = { label = 'Default', clipset = nil },
    brave = { label = 'Brave', clipset = 'move_m@brave' },
    casual = { label = 'Casual', clipset = 'move_m@casual@a' },
    confident = { label = 'Confident', clipset = 'move_m@confident' },
    drunk = { label = 'Drunk', clipset = 'move_m@drunk@verydrunk' },
    hurry = { label = 'Hurry', clipset = 'move_m@hurry@a' },
    sad = { label = 'Sad', clipset = 'move_m@depressed@a' },
}

Config.expressions = {
    default = { label = 'Default' },
    angry = { label = 'Angry', anim = 'mood_angry_1', dict = 'facials@gen_male@base' },
    happy = { label = 'Happy', anim = 'mood_happy_1', dict = 'facials@gen_male@base' },
    smug = { label = 'Smug', anim = 'mood_smug_1', dict = 'facials@gen_male@base' },
    stressed = { label = 'Stressed', anim = 'mood_stressed_1', dict = 'facials@gen_male@base' },
}
