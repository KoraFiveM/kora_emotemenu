---
title: "Commands"
sidebar_position: 4
---


# Commands

Client commands are registered with `RegisterCommand` (no restriction flag, so any player can run them — the menu itself gates usage through `canUse()`, not the command). `/emoteMaker` is a server-registered command gated on the `command` ACE.

## Built-in commands

### `/emotes`

Opens the emote menu (same as pressing the keybind).

| Field | Details |
| --- | --- |
| Context | In-game · client command (`Config.command`, default `emotes`) |
| Arguments | No arguments. |
| Access | Any player; blocked while dead, cuffed (unless `Config.blockWhenCuffed = false`), or already in the menu. |

**Example**

```text
/emotes
```

**Result**

Opens the configured menu style (radial, context list, or app shell).

### `/e [name]`

With no argument, opens the menu. With an emote name, plays that emote directly.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | name? — a registered emote key, case-insensitive. |
| Access | Same as /emotes. |

**Example**

```text
/e
/e wave
```

**Result**

Plays the named emote, or shows an error notification if it is not registered or cannot be used right now.

### `/cancel`

Cancels the currently playing emote (including a synced one — the partner is also told to stop).

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | No arguments. |
| Access | Any player. |

**Example**

```text
/cancel
```

**Result**

Notification "Emote cancelled." if something was playing, otherwise nothing.

### `/walk [name]`

Sets the player's walk style (movement clipset).

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | name? — a key from `Config.walks` (`default`, `brave`, `casual`, `confident`, `drunk`, `hurry`, `sad`); defaults to `default`. |
| Access | Any player; refused inside a vehicle when `Config.vehicle.upperBodyOnly` is true. |

**Example**

```text
/walk drunk
/walk
```

**Result**

Notification with the new walk style label, or an error if the name is not configured.

### `/expression [name]`

Sets (or clears) the player's facial idle animation override.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | name? — a key from `Config.expressions` (`default`, `angry`, `happy`, `smug`, `stressed`); defaults to `default`. |
| Access | Any player. |

**Example**

```text
/expression angry
/expression
```

**Result**

Notification with the new expression label, or an error if the name is not configured.

### `/emoteMaker`

Opens the React emote creator UI (freecam preview + save/delete of custom emotes).

| Field | Details |
| --- | --- |
| Context | In-game · server command (`Kora.commands.add`) |
| Arguments | No arguments. |
| Access | Requires the `command` ACE (`IsPlayerAceAllowed(source, 'command')`); otherwise an error notification is sent and the UI never opens. |

**Example**

```text
/emoteMaker
```

**Result**

Opens the emote creator NUI on the calling client. Running it again while the freecam preview is active returns to the editor instead of reopening it.

## Keybind

`Config.keybind` registers a `kora_lib` keybind (default `F3`) that opens the menu. Players can rebind it in the FiveM settings. The cancel key is `Config.cancelControl` (default X) and is read directly as a control, not as a rebindable keybind.

## Notes

- There is no chat suggestion registered for the player commands.
- `/emoteMaker` is registered with `Kora.commands.add` and no `kora_lib` permission; the ACE check happens in the handler. FiveM command names are not case sensitive, so `/emotemaker` is expected to work too (unverified in-game).

## Permissions

The Emote Maker is gated by the ACE `command`: the `/emoteMaker` handler and the net events `saveEmote`, `requestEmotesForEdit` and `deleteCreatedEmote` all check `IsPlayerAceAllowed(source, 'command')` on the server. Anyone with that ACE can create and delete emotes for the whole server. Grant it only to staff, for example:

```cfg
add_ace group.admin command allow
```

No other permissions are used.
