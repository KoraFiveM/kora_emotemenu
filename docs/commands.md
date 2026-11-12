---
title: Commands
sidebar_position: 5
---

# Commands

## Player commands (client)

| Command | Description |
| --- | --- |
| `/emotes` | Opens the menu. The command name comes from `Config.command`. |
| `/e` | Opens the menu. |
| `/e name` | Plays the emote `name` (lowercased). Shows an error notification if it is unknown, blocked or not allowed. Shared emotes send an invite to the nearest player. |
| `/cancel` | Cancels the current emote. |
| `/walk name` | Sets a walk style from `Config.walks`; with no argument resets to `default`. |
| `/expression name` | Sets an expression from `Config.expressions`; with no argument resets to `default`. |

The commands are registered with `RegisterCommand` and no ACE restriction. There is no chat suggestion registered for them.

## Keybind

`Config.keybind` registers a `kora_lib` keybind (default `F3`) that opens the menu. Players can rebind it in the FiveM settings. The cancel key is `Config.cancelControl` (default X) and is read directly as a control, not as a rebindable keybind.

## Staff command (server)

| Command | Description |
| --- | --- |
| `/emoteMaker` | Opens the [Emote Maker](./emote-maker.md). Registered with `Kora.commands.add` (no `kora_lib` permission; the ACE check happens in the handler). FiveM command names are not case sensitive, so `/emotemaker` is expected to work too (unverified in-game). |

## Permissions

The Emote Maker is gated by the ACE `command`: the `/emoteMaker` handler and the net events `saveEmote`, `requestEmotesForEdit` and `deleteCreatedEmote` all check `IsPlayerAceAllowed(source, 'command')` on the server. Anyone with that ACE can create and delete emotes for the whole server. Grant it only to staff, for example:

```cfg
add_ace group.admin command allow
```

No other permissions are used.
