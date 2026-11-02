# kora_emotemenu

`kora_emotemenu` is a from-scratch, kora_lib-native emote resource. It uses kora_lib's
radial NUI, keybinds, animation/prop ownership, streaming, notifications,
controls and state bags rather than shipping a separate menu framework.

## Install

Add `ensure kora_emotemenu` after `ensure kora_lib` in `server.cfg`. The default
open key is `F3`; players can rebind it in FiveM settings. Use `/emotes` (or
`/e <name>`) to open/play an emote and `/cancel` to stop one.

## Configure and extend

The built-in catalogue contains only small Rockstar-native examples and lives
in `shared/emotes.lua`. Add your own assets there or register them from another
client resource:

```lua
exports.kora_emotemenu:registerEmote('my_emote', {
    label = 'My emote', category = 'general', type = 'anim',
    dict = 'my_anim_dict', clip = 'my_clip', flag = 49,
})
```

Supported types are `anim` and `scenario`. Animation entries may include
`blockMovement`, `duration`, and a `prop` accepted by `Kora.anim.attachProp`.
The `sync` field uses a second, hidden catalogue entry as the partner emote.
Sync distance is checked on the server before either player is instructed to
play.

## Emotes in vehicles

The menu never removes a player from their seat. Inside a vehicle it does not
call `ClearPedTasksImmediately`; cancelling uses `StopAnimTask` and
`ClearPedSecondaryTask`. Configure it with `Config.vehicle`:

- `allowEmotes` (default `true`): `false` refuses every emote in a vehicle.
- `upperBodyOnly` (default `true`): animations play as upper-body tasks (flag
  48/49) and walk styles cannot be changed while seated.
- `blockedInVehicle` (default `{}`): emote names refused in a vehicle.

Scenarios and emotes with `standing = true` (such as shared emotes) are always
refused in a vehicle with a short notification.

## Cuffed players

A cuffed player cannot start an emote (from the menu, `/e`, a shared-emote invite
or the `playEmote` export), and an emote that is running is cancelled the moment
they are cuffed. The check reads `LocalPlayer.state.koraCuffed`, which kora_police
sets from the server, plus the `isCuffed` and `handcuffed` keys used by other
cuff scripts. `Config.blockWhenCuffed = false` lets cuffed players emote.

## Client exports

- `toggleMenu()`
- `playEmote(name)`
- `cancelEmote()`
- `isInEmote()`
- `getLastEmote()`
- `registerEmote(name, definition)`
- `setWalk(name)` / `resetWalk()`
- `setExpression(name)` / `resetExpression()`

The local player's replicated state bag publishes `qbemotemenu:active`,
`qbemotemenu:last`, `qbemotemenu:walk`, and `qbemotemenu:expression` for
integrations that need to observe the selected state.
