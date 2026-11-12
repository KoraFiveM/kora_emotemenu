---
title: kora_emotemenu
sidebar_position: 1
---

# kora_emotemenu

`kora_emotemenu` is an emote menu for Kora servers built on `kora_lib`. Players open a radial, list or app-shell menu to play animations, scenarios, prop emotes and two-player shared emotes, and to choose a walk style and a facial expression. Staff with the right permission can create new emotes in-game with the Emote Maker (a React NUI with a freecam and live prop placement).

Current version: see `version` in `fxmanifest.lua`.

## Documentation map

- [Installation](./installation.md) - manifest, load order, dependencies, default keybind, rebuilding the NUI.
- [How to use](./how-to-use.md) - emote entry format, registering emotes from another resource, vehicles, cuffs and appearance persistence.
- [Commands](./commands.md) - every chat command with arguments and access, keybind and permissions.
- [API reference](./api/index.md) - client exports and state bag keys.
  - [Client exports](./api/client-exports.md) - the ten `exports.kora_emotemenu` functions with parameters, returns and examples.
  - [State bags and events](./api/state-and-events.md) - replicated state keys, net events, NUI callbacks.
- [Configuration](./configuration.md) - every `Config` option in `config.lua`.
- [Features](./features.md) - what the menu, emotes, walks, expressions and shared emotes do.
- [Emote catalogue](./emotes.md) - the built-in emotes and the emote definition format.
- [Emote Maker](./emote-maker.md) - the in-game creator for staff.
- [Data storage](./data.md) - where created emotes and player preferences are saved (no database).
- [Troubleshooting](./troubleshooting.md) - common problems.

## Layout

| Path | Purpose |
| --- | --- |
| `fxmanifest.lua` | Manifest, dependencies, NUI page. |
| `config.lua` | All settings (shared script). |
| `shared/emotes.lua` | Built-in emote catalogue and bone names. |
| `shared/created.json` | Emotes saved with the Emote Maker (written by the server). |
| `client/main.lua` | Menu, emote playback, walks, expressions, exports. |
| `client/emote_creator.lua` | Emote Maker client side (freecam, preview, NUI callbacks). |
| `server/main.lua` | Shared emote invites and the `/emoteMaker` command. |
| `server/emote_creator.lua` | Validation and persistence of created emotes. |
| `ui/` | React/Vite source of the Emote Maker; `ui/dist` is the built page shipped to clients. |
| `tests/` | Offline Lua tests and kora_qa Gherkin features. |
