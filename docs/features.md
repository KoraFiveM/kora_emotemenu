---
title: Features
sidebar_position: 3
---

# Features

## Menu

`F3` (keybind `Config.keybind`), `/emotes` and the `toggleMenu` export open the menu. It has one entry per category that contains at least one visible emote, plus **Walk style**, **Expression** and **Cancel emote** (disabled while no emote plays). Three styles are available through `Config.menuStyle`:

- `radial` - circular wheel (default).
- `context` - list menu where each submenu is its own page with a Back row.
- `app` - a compact `kora_lib` app window with a list per category. If the app cannot be registered or updated, a console warning is printed and the radial style is used instead.

The style is read each time the menu opens. Walk style and expression lists mark the active choice with a check icon in the theme colour and the description "Currently active".

The menu cannot be opened (and emotes cannot start) while the player is dead (`isDead` or `dead` state) or cuffed.

## Emotes

Two types exist: `anim` (animation dictionary and clip) and `scenario`. Animation emotes can attach up to two props (`prop`, `proptwo`), block movement, or play for a fixed `duration`. See [Emote catalogue](./emotes.md).

- Starting an emote cancels the previous one.
- A cancel monitor stops the emote when the player presses `Config.cancelControl` (default 73, X), ragdolls, dies or is cuffed.
- Props are local, non-networked objects that are deleted when the emote ends.
- Emotes with `blockMovement = true` disable the controls in `Config.blockedControls` and firing while they play. The built-in **Hands up** emote also has `handsUp = true`; with `Config.handsUpAllowMovement` enabled it only disables the controls in `Config.blockedControls` that are not movement controls (the code treats controls 21, 22 and 30 to 35 as movement, so with the default list only 23 vehicle entry, 24 attack and 25 aim stay blocked, plus firing).
- A cancel hint (`Config.cancelHint`) is shown through the `kora_lib` text UI for scenarios, prop emotes and looping emotes without a `duration`.

## Vehicles

Emotes can be played while seated. The player is never removed from the seat: cancelling uses `StopAnimTask` and `ClearPedSecondaryTask` instead of `ClearPedTasksImmediately`. Scenarios and emotes with `standing = true` are always refused, and `Config.vehicle` controls the rest. With `upperBodyOnly`, animation flags are forced to 48 (or 49 when the emote loops) and walk styles cannot be changed.

## Cuffed players

Unless `Config.blockWhenCuffed = false`, a player is treated as unable to emote when any of the state bag keys `koraCuffed`, `isCuffed` or `handcuffed` is truthy on `LocalPlayer.state`.

## Shared emotes

An emote with a `sync = { partner = 'name' }` field is a two-player emote (the built-in Handshake and Hug). Playing it:

1. The client finds the nearest player within `Config.syncDistance` and sends `kora_emotemenu:server:sync`.
2. The server checks the target (not yourself, same routing bucket, within `Config.syncDistance` of the sender), the cooldown (`Config.syncCooldown`) and that neither player already has an invite or active shared emote.
3. The target gets an Accept/Decline alert that expires after `Config.syncInviteTTL` ms.
4. On accept the server re-validates and tells both players to play their emote (the initiator plays the main emote, the target plays the hidden partner emote).
5. Cancelling either side, or a player leaving, cancels the other side.

## Walk styles and expressions

`/walk name`, `/expression name` or the menu entries set a movement clipset (`Config.walks`) or a facial mood (`Config.expressions`). Both are published on the player's state bag, restored after respawn by a one second loop, and other players' expressions are mirrored onto their peds when in scope. With `Config.persistAppearance` the choices are saved in client KVP and re-applied about one second after the resource starts. Optional notifications (`Config.expressionNotify`) tell you when a nearby player wears an expression, for example "Alex appears to be angry".

## Emote Maker

Staff can create, edit and delete emotes in-game. See [Emote Maker](./emote-maker.md).
