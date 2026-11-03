Config = {}

Config.command = 'emotes'
Config.keybind = {
    name = 'qbemotemenu_open',
    label = 'Open emote menu',
    defaultKey = 'F3',
}

-- 'radial' (default), 'context' (list menu) or 'app' (app shell window).
-- Read every time the menu opens, so changing it needs no restart.
Config.menuStyle = 'radial'

-- Per-emote prop tweaks, merged over shared/emotes.lua each time the emote plays.
-- Example: Config.propOverrides.clipboard = { prop = { bone = 57005, offset = { x = 0.0, y = 0.0, z = 0.0 } } }
-- Bones are ped bone ids (see QBEBoneNames in shared/emotes.lua for names). Use the key `proptwo` for a second prop. Only the fields you set are replaced.
Config.propOverrides = {}

Config.syncDistance = 3.0
Config.syncInviteTTL = 10000
Config.syncCooldown = 3000
Config.persistAppearance = true
Config.cancelControl = 73 -- X

-- On-screen reminder of how to stop an emote. Shown (through kora_lib's text UI) when a looping
-- emote, a scenario or a prop emote starts, with the key taken from Config.cancelControl, and
-- hidden as soon as the emote ends. enabled = false turns it off.
Config.cancelHint = {
    enabled = true,
    text = 'Cancel emote',
    position = 'right-center', -- left-center, right-center, top-center or bottom-center
}

-- Emotes marked `handsUp = true` (General > Hands up) normally block movement. With this on
-- the player can walk while their hands are up; sprinting, jumping, entering vehicles, aiming and
-- firing stay blocked so it cannot be used to shoot with the hands raised. false restores the
-- old behaviour where every control in Config.blockedControls is disabled.
Config.handsUpAllowMovement = true

-- Cuffed players cannot start an emote, and a running one is cancelled the moment they
-- are cuffed. Reads LocalPlayer.state.koraCuffed (set by kora_police) plus the isCuffed
-- and handcuffed keys. false lets cuffed players emote.
Config.blockWhenCuffed = true

-- These controls are disabled while an emote explicitly opts into blocking
-- movement. Combat is deliberately never disabled globally: the animation
-- itself is cancelled if the player needs to defend themselves.
Config.blockedControls = { 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35 }

-- Emotes while seated in a vehicle. The menu never removes the player from the seat: it does not
-- use ClearPedTasksImmediately in a vehicle, and cancelling uses StopAnimTask / ClearPedSecondaryTask.
--   allowEmotes       false refuses every emote while in a vehicle.
--   upperBodyOnly     true plays animations as upper-body/secondary tasks (flag 48/49) and refuses walk styles.
--   blockedInVehicle  list of emote names refused in a vehicle. Scenarios and emotes with `standing = true`
--                     (shared/emotes.lua) are always refused in a vehicle.
Config.vehicle = {
    allowEmotes = true,
    upperBodyOnly = true,
    blockedInVehicle = {},
}

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

-- anim is a facial mood clip from facials@gen_male@base / facials@gen_female@base, applied with
-- SetFacialIdleAnimOverride. An entry without anim clears the override. Optional `notice` replaces the
-- word used by expressionNotify ("<name> appears to be <notice>"); it defaults to the lowercase label.
Config.expressions = {
    default = { label = 'Default' },
    angry = { label = 'Angry', anim = 'mood_angry_1' },
    happy = { label = 'Happy', anim = 'mood_happy_1' },
    smug = { label = 'Smug', anim = 'mood_smug_1' },
    stressed = { label = 'Stressed', anim = 'mood_stressed_1' },
}

-- Optional RP nicety: tells you when someone nearby is wearing an expression. Off by default.
-- Read every time the check runs, so changing it needs no restart.
Config.expressionNotify = {
    enabled = false,
    distance = 3.0,
    cooldown = 120, -- seconds before the same player+expression is announced again
}

-- Registers this resource-owned configuration with kora_lib without changing its public Config table.
if Kora and Kora.config and Kora.config.adopt then
    Config.menuStyle = Kora.config.enum(Config.menuStyle, {
        label = 'Menu style',
        description = 'Chooses how the emote menu is shown. Radial is the circular wheel, Context is a plain list that opens each category as its own page, and App Shell is a windowed menu with a tab per category. The change applies the next time the menu is opened.',
        options = {
            { value = 'radial', label = 'Radial' },
            { value = 'context', label = 'Context list' },
            { value = 'app', label = 'App Shell' },
        },
    })
    Config.expressionNotify.enabled = Kora.config.boolean(Config.expressionNotify.enabled, {
        label = 'Expression notifications',
        description = 'When enabled, players who come close to someone with an active facial expression such as angry or happy get a notification like "Alex appears to be angry". Disabled by default because it adds a small periodic check on every client.',
        live = true,
    })
    Config.expressionNotify.distance = Kora.config.number(Config.expressionNotify.distance, {
        label = 'Expression notification distance',
        description = 'Sets how close, in metres, you must be to a player with an active expression before the notification is shown. Only used when expression notifications are enabled.',
        min = 0.5,
        max = 20,
        live = true,
    })
    Config.expressionNotify.cooldown = Kora.config.number(Config.expressionNotify.cooldown, {
        label = 'Expression notification cooldown',
        description = 'Sets how many seconds must pass before the same player and expression are announced to you again. Only used when expression notifications are enabled.',
        min = 5,
        live = true,
    })
    Config.vehicle.allowEmotes = Kora.config.boolean(Config.vehicle.allowEmotes, {
        label = 'Emotes in vehicles',
        description = 'When enabled, players seated in a vehicle can play animation emotes. Scenarios and emotes that need standing are always refused. Players are never removed from their seat. When disabled, every emote is refused while in a vehicle.',
        live = true,
    })
    Config.vehicle.upperBodyOnly = Kora.config.boolean(Config.vehicle.upperBodyOnly, {
        label = 'Upper-body emotes in vehicles',
        description = 'When enabled, animations played inside a vehicle only use the upper body so the player stays seated, and walk styles cannot be changed while in a vehicle.',
        live = true,
    })
    Config.cancelHint.enabled = Kora.config.boolean(Config.cancelHint.enabled, {
        label = 'Cancel emote hint',
        description = 'When enabled, a prompt such as "[X] Cancel emote" is shown on screen while a looping, scenario or prop emote is playing, and hidden when it ends. The key shown follows the configured cancel control.',
        live = true,
    })
    Config.handsUpAllowMovement = Kora.config.boolean(Config.handsUpAllowMovement, {
        label = 'Walk with hands up',
        description = 'When enabled, players can walk while the Hands up emote is playing. Sprinting, jumping, entering vehicles, aiming and firing stay blocked. When disabled, hands up blocks all movement controls like other blocking emotes.',
        live = true,
    })
    Config = Kora.config.adopt(Config)
end

-- Emote Maker (/emotemaker) settings.
--   exitControls    control ids that leave the freecam and return to the menu, keeping the current view.
--                   Default Enter (191), Backspace (177) and Escape (200); Escape never opens the pause map
--                   while the freecam is active. Running the emote maker command again also returns.
--   hint.exit       first line of the freecam help text. Use ~INPUT_NAME~ tokens for the key, and match it to
--                   the first control in exitControls (Enter = ~INPUT_FRONTEND_ACCEPT~).
--   blockUi         true sets the LocalPlayer.state.koraUiBlocked bag while the freecam is active. Inventory,
--                   phone and other UIs that check this bag stay closed. false never sets it.
--   maxLabelLength  longest emote label the creator accepts (extra characters are cut). 0 = no limit.
Config.emoteMaker = {
    exitControls = { 191, 177, 200 },
    hint = { exit = '~INPUT_FRONTEND_ACCEPT~ Back to menu (Enter / Backspace / Esc)' },
    blockUi = true,
    maxLabelLength = 24,
}
