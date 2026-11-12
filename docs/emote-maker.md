---
title: Emote Maker
sidebar_position: 9
---

# Emote Maker

A staff tool to build emotes in-game and add them to the menu for everyone without restarting.

## Opening

Run `/emoteMaker`. The server checks the ACE `command` and then asks the client to open the editor (a NUI served from `ui/dist`). Without the ACE the player is notified that they lack permission.

## Editing

The editor has fields for name, label, category, animation dictionary, clip and flag, and up to two props (model name, bone id, offset and rotation, adjustable with a step of 0.01, 0.1, 1 or 10).

- **Play / Stop** previews the animation and props on your own ped using local objects.
- **Freecam** hides the editor and gives a free camera (W A S D move, mouse look, Q up, E down, Shift fast, Ctrl slow). Enter, Backspace or Escape (`Config.emoteMaker.exitControls`) or running the command again returns to the editor. While active, `LocalPlayer.state.koraUiBlocked` is set if `Config.emoteMaker.blockUi` is on.
- **Saved emotes** lists emotes created earlier so they can be loaded, edited or deleted.
- Saving requires name, label, dictionary and clip.

## Server validation

The server rebuilds every emote from checked values and never stores raw client data:

- Name: 1 to 32 characters of letters, digits, `_`, `-`; stored lowercase.
- Label: 1 to 40 characters.
- Category: only `general`, `dance` or `props`, and it must exist in `Config.categories`.
- Dictionary and clip: up to 128 characters of letters, digits, `_`, `@`, `.`, `-`, `^`.
- Flag: whole number 0 to 65535.
- At most 2 props; model up to 64 characters of letters, digits and `_`; bone an integer 0 to 99999; offsets and rotations numbers within 1000, rounded to 4 decimals.
- Created emotes are always type `anim`.
- A name that already exists (built-in or created) is rejected unless you are editing that same emote. Renaming removes the old name.
- Cooldowns: 2 s per player for saves, 1 s for deletes.

On success the file `shared/created.json` is rewritten, the emote is added to the server and broadcast to all clients (`addEmotes`, and `removeEmotes` for a rename), and the editor closes. If the file cannot be written, the change is rolled back and the player is told. Built-in emotes cannot be edited or deleted with the tool.
