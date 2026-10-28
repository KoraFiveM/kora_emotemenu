# kora_emotemenu

`kora_emotemenu` is a from-scratch, qblib-native emote resource. It uses kora_lib's
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
`blockMovement`, `duration`, and a `prop` accepted by `QB.anim.attachProp`.
The `sync` field uses a second, hidden catalogue entry as the partner emote.
Sync distance is checked on the server before either player is instructed to
play.

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
