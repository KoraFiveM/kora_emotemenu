---
title: Exports
sidebar_position: 6
---

# Exports

All exports are client-side. The resource has no server exports.

```lua
exports.kora_emotemenu:playEmote('wave')
```

| Export | Returns | Description |
| --- | --- | --- |
| `toggleMenu()` | nothing | Opens the menu (does nothing if it is already open). It does not close an open menu. |
| `playEmote(name)` | `true`, or `false, message` | Plays a registered emote by exact key (names are lowercase). For a shared emote it only sends the invite to the closest player within `Config.syncDistance` and returns `true`. |
| `cancelEmote(silent, skipSyncNotice)` | `boolean` | Stops the current emote and returns whether one was active. Shows an "Emote cancelled." notification unless `silent` is truthy. `skipSyncNotice` skips telling a shared-emote partner. |
| `isInEmote()` | `boolean` | Whether an emote is active. |
| `getLastEmote()` | `string` or `nil` | Name of the last emote played in this session. |
| `registerEmote(name, definition)` | nothing | Adds or replaces an emote on this client. Throws (assert) on invalid input. See below. |
| `setWalk(name, quiet)` | `true`, or `false, message` | Applies a key of `Config.walks`. |
| `resetWalk()` | same as `setWalk('default')` | Resets the walk style. |
| `setExpression(name, quiet)` | `true`, or `false, message` | Applies a key of `Config.expressions`. |
| `resetExpression()` | same as `setExpression('default')` | Clears the expression. |

## registerEmote

```lua
exports.kora_emotemenu:registerEmote('my_emote', {
    label = 'My emote', category = 'general', type = 'anim',
    dict = 'my_anim_dict', clip = 'my_clip', flag = 49,
})
```

Assertions: `name` must match letters, digits, `_` and `-`; `definition.label` must be a string; `type` must be `anim` or `scenario`; a visible emote needs a `category` that exists in `Config.categories` (or `hidden = true`); `anim` needs `dict` and `clip`; `scenario` needs `scenario`. The name is stored lowercased and the definition is deep-copied. See [Emote catalogue](./emotes.md) for fields.

Registration is local to the calling client and lasts until the resource restarts. It does not touch the server's catalogue, so a registered emote with a `sync` field cannot start a shared emote (the server rejects it as unavailable). Re-register after `kora_emotemenu` restarts.

## State bags

The local player's replicated state bag carries:

| Key | Value |
| --- | --- |
| `kora_emotemenu:active` | Name of the running emote, or `false`. |
| `kora_emotemenu:last` | Name of the last emote played. |
| `kora_emotemenu:walk` | Key of the active walk style. |
| `kora_emotemenu:expression` | Key of the active expression, or `nil` for none or when the chosen entry has no `anim`. |

The resource also writes `koraUiBlocked` (not replicated) while the Emote Maker freecam is active and `Config.emoteMaker.blockUi` is on, and reads `isDead`, `dead`, `koraCuffed`, `isCuffed` and `handcuffed` from the local state.
