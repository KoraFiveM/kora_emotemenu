---
title: Configuration
sidebar_position: 4
---

# Configuration

All settings are in `config.lua` and are shared by client and server. `config.lua` also registers some options with `kora_lib` (`Kora.config`), which exposes them in its config UI. Options marked live can change at runtime through that UI; the others need a resource restart unless noted.

## General

| Option | Default | Description |
| --- | --- | --- |
| `Config.command` | `'emotes'` | Name of the command that opens the menu. |
| `Config.keybind` | `name = 'kora_emotemenu_open'`, `label = 'Open emote menu'`, `defaultKey = 'F3'` | Key mapping registered through `Kora.keybind`. |
| `Config.menuStyle` | `'radial'` | `radial`, `context` or `app`. Read each time the menu opens. Registered with `kora_lib`. |
| `Config.cancelControl` | `73` | Control id that cancels a running emote (X). |
| `Config.persistAppearance` | `true` | Save the chosen walk style and expression in client KVP and restore them on start. |
| `Config.blockedControls` | `{ 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35 }` | Controls disabled while an emote with `blockMovement = true` plays. Firing is also disabled. |
| `Config.blockWhenCuffed` | `true` | Cuffed players cannot start emotes and a running emote is cancelled. |
| `Config.handsUpAllowMovement` | `true` | Emotes with `handsUp = true` do not disable the movement controls (21, 22, 30 to 35) from `Config.blockedControls`. Live. |

## Cancel hint

`Config.cancelHint`:

| Key | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Show the hint while a scenario, prop emote or looping emote without `duration` plays. Live. |
| `text` | `'Cancel emote'` | Hint text. |
| `position` | `'right-center'` | `left-center`, `right-center`, `top-center` or `bottom-center`. |

## Shared emotes

| Option | Default | Description |
| --- | --- | --- |
| `Config.syncDistance` | `3.0` | Maximum distance in metres to the partner (checked on client and server). |
| `Config.syncInviteTTL` | `10000` | Invite lifetime in ms. |
| `Config.syncCooldown` | `3000` | Per-player cooldown in ms between invite requests (server). |

## Vehicles

`Config.vehicle`:

| Key | Default | Description |
| --- | --- | --- |
| `allowEmotes` | `true` | `false` refuses every emote in a vehicle. Live. |
| `upperBodyOnly` | `true` | Upper-body flags (48/49) in vehicles, and no walk style changes. Live. |
| `blockedInVehicle` | `{}` | List of emote names refused in vehicles. |

## Categories, walks, expressions

- `Config.categories` - map of category key to `label` and `icon` (a Lucide icon name). Defaults: `general`, `dance`, `props`, `scenarios`, `shared`. A visible emote must use one of these keys.
- `Config.walks` - map of key to `label` and `clipset` (a movement clipset; `nil` resets). Defaults: `default`, `brave`, `casual`, `confident`, `drunk`, `hurry`, `sad`.
- `Config.expressions` - map of key to `label`, optional `anim` (a clip from `facials@gen_male@base` or `facials@gen_female@base`) and optional `notice` word. An entry without `anim` clears the override. Defaults: `default`, `angry`, `happy`, `smug`, `stressed`.

The menu only lists a Walk style or Expression group when it has entries.

## Expression notifications

`Config.expressionNotify` (all live):

| Key | Default | Description |
| --- | --- | --- |
| `enabled` | `false` | Notify when a nearby player has an expression with an `anim`. |
| `distance` | `3.0` | Metres (`kora_lib` limits 0.5 to 20). |
| `cooldown` | `120` | Seconds before the same player and expression are announced again (minimum 5). |

## Prop overrides

`Config.propOverrides` merges fields over an emote's prop each time it plays. Keys are emote names, then `prop` or `proptwo`; only the fields you set are replaced.

```lua
Config.propOverrides.clipboard = {
    prop = { bone = 57005, offset = { x = 0.0, y = 0.0, z = 0.0 } },
}
```

Note that the overrides merge shallowly: setting `offset` replaces the whole offset table.

## Emote Maker

`Config.emoteMaker`:

| Key | Default | Description |
| --- | --- | --- |
| `exitControls` | `{ 191, 177, 200 }` | Controls that leave the freecam and return to the editor (Enter, Backspace, Escape). Running the command again also returns. |
| `hint.exit` | `'~INPUT_FRONTEND_ACCEPT~ Back to menu (Enter / Backspace / Esc)'` | First line of the freecam help text. |
| `blockUi` | `true` | Set `LocalPlayer.state.koraUiBlocked` while the freecam is active so other UIs stay closed. |
| `maxLabelLength` | `24` | Longest label the editor keeps in the client (extra characters are cut); `0` disables the client limit. The server still caps labels at 40 characters. |
