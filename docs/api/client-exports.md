---
title: "Client exports"
sidebar_position: 2
---


# Client exports

The public surface other client resources use to open the menu, play/cancel emotes, register new ones, and change walk style or expression. All of it operates on the calling client only.

Namespace: `exports.kora_emotemenu` · Source: `client/main.lua`

## Functions

Ten exports.

### `exports.kora_emotemenu:toggleMenu()`

Opens the emote menu for the calling client, same as `/emotes` or the keybind. No-ops if the menu is already open or the player cannot currently use emotes.

**Parameters**



**Returns**

- **Nothing.**

**Example**

```lua
exports.kora_emotemenu:toggleMenu()
```

**Representative console output**

```text
Shows a "You cannot use emotes right now." error notification instead of opening when the player is dead or cuffed. If the menu is already open, nothing happens.
```

### `exports.kora_emotemenu:playEmote(name)`

Plays a registered emote by name, going through the same vehicle/cuff/sync checks as the menu. For a `sync`-flagged emote this sends a shared-emote invite to the nearest player within `Config.syncDistance` instead of playing immediately.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `name` | string | An emote key from `shared/emotes.lua` or one registered with `registerEmote`. |

**Returns**

- **ok** — `true` if the emote started (or the invite was sent).
- **reason** — error string when `ok` is false, e.g. `'That emote is not registered.'`, `'You cannot use emotes right now.'`, or a vehicle refusal message.

**Example**

```lua
local ok, reason = exports.kora_emotemenu:playEmote('wave')
if not ok then print(reason) end
```

**Representative console output**

```text
Non-sync emotes play immediately on the calling client; sync emotes require a second player in range and server-side acceptance before anything plays.
```

### `exports.kora_emotemenu:cancelEmote(silent?, skipSyncNotice?)`

Stops the currently playing emote (clearing props, released controls, and the cancel hint). If the emote was synced, the server is told so the partner stops too (unless `skipSyncNotice` is set).

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `silent?` | boolean | When `true`, no "Emote cancelled." notification is shown. |
| `skipSyncNotice?` | boolean | When `true`, the server is not told to cancel the partner's synced emote. |

**Returns**

- **wasActive** — `true` if an emote was actually playing and got cancelled, `false` if nothing was playing.

**Example**

```lua
local wasActive = exports.kora_emotemenu:cancelEmote()
```

**Representative console output**

```text
Shows a "Emote cancelled." notification when something was stopped, unless `silent` is `true`.
```

### `exports.kora_emotemenu:isInEmote()`

Reports whether the calling client currently has an emote active.

**Parameters**



**Returns**

- **boolean.**

**Example**

```lua
if exports.kora_emotemenu:isInEmote() then print('busy') end
```

**Representative console output**

```text
Reflects the same state published in the `kora_emotemenu:active` state-bag key.
```

### `exports.kora_emotemenu:getLastEmote()`

Returns the name of the most recently played emote, even after it has ended.

**Parameters**



**Returns**

- **name** — string, or `nil` if no emote has played this session.

**Example**

```lua
local last = exports.kora_emotemenu:getLastEmote()
```

**Representative console output**

```text
Mirrors the `kora_emotemenu:last` state-bag key.
```

### `exports.kora_emotemenu:registerEmote(name, definition)`

Adds or overwrites one emote definition in the calling client's own local emote table. See How to use for the required fields and validation rules.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `name` | string | Emote key; must match `^[%w_%-]+$`. Lower-cased before storage. |
| `definition` | table | `{ label, category?, type, dict?, clip?, scenario?, hidden?, ... }` — see How to use for the full field reference. |

**Returns**

- **Nothing. Throws via `assert` if the definition is invalid.**

**Example**

```lua
exports.kora_emotemenu:registerEmote('my_emote', {
    label = 'My emote', category = 'general', type = 'anim',
    dict = 'my_anim_dict', clip = 'my_clip', flag = 49,
})
```

**Representative console output**

```text
Local to the calling client only — not synced to other players and not persisted to disk.
```

### `exports.kora_emotemenu:setWalk(name, quiet?)`

Applies a configured walk-style movement clipset.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `name` | string | A key from `Config.walks`. |
| `quiet?` | boolean | When `true`, no "Walk style" notification is shown and the in-vehicle restriction is not enforced. |

**Returns**

- **ok** — `true` on success.
- **reason** — error string, e.g. `'That walk style is not configured.'` or `'Walk styles cannot be changed inside a vehicle.'`.

**Example**

```lua
exports.kora_emotemenu:setWalk('confident')
```

**Representative console output**

```text
Persists the choice via `SetResourceKvp` when `Config.persistAppearance` is true.
```

### `exports.kora_emotemenu:resetWalk()`

Equivalent to `setWalk('default')` — restores the stock movement clipset.

**Parameters**



**Returns**

- **Same return shape as `setWalk`.**

**Example**

```lua
exports.kora_emotemenu:resetWalk()
```

### `exports.kora_emotemenu:setExpression(name, quiet?)`

Applies (or clears, for `default`) a facial idle animation override.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `name` | string | A key from `Config.expressions`. |
| `quiet?` | boolean | When `true`, no "Expression" notification is shown. |

**Returns**

- **ok** — `true` on success.
- **reason** — `'That expression is not configured.'` when the name is unknown.

**Example**

```lua
exports.kora_emotemenu:setExpression('happy')
```

**Representative console output**

```text
Persists the choice via `SetResourceKvp` when `Config.persistAppearance` is true. Nearby players may see a notification if `Config.expressionNotify.enabled` is true.
```

### `exports.kora_emotemenu:resetExpression()`

Equivalent to `setExpression('default')` — clears the facial override.

**Parameters**



**Returns**

- **Same return shape as `setExpression`.**

**Example**

```lua
exports.kora_emotemenu:resetExpression()
```

## Limits and related APIs

Client only. `registerEmote` only affects the calling client's local table — it is not a way to add a server-wide emote.

## Additional details

All exports are client-side; the resource has no server exports.

- `playEmote(name)` looks the emote up by exact key (names are lowercase). For a shared emote it only sends the invite to the closest player within `Config.syncDistance` and returns `true`.
- `toggleMenu()` only opens the menu; it does not close an open menu.
- `registerEmote(name, definition)` asserts: `name` must match letters, digits, `_` and `-`; `definition.label` must be a string; `type` must be `anim` or `scenario`; a visible emote needs a `category` that exists in `Config.categories` (or `hidden = true`); `anim` needs `dict` and `clip`; `scenario` needs `scenario`. The name is stored lowercased and the definition is deep-copied. See [Emote catalogue](../emotes.md) for fields.
- Registration lasts until the resource restarts. It does not touch the server's catalogue, so a registered emote with a `sync` field cannot start a shared emote (the server rejects it as unavailable). Re-register after `kora_emotemenu` restarts.
- `resetWalk()` and `resetExpression()` return the same values as `setWalk('default')` and `setExpression('default')`.
