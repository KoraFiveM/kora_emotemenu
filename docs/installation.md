---
title: Installation
sidebar_position: 2
---

# Installation

## Dependencies

Declared in `fxmanifest.lua` with `dependency`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | Menus (radial, context, app shell), alerts, keybinds, animation and prop streaming, control blocking, text UI, notifications, commands, timers, config registration. Its `init.lua` is loaded as a shared script. |
| `kora_theme` | Loads its client bridge and supplies the highlight colour for the menu check marks and the Emote Maker. |

Optional integrations that are read only through state and are not required: `kora_police` (sets the `koraCuffed` state bag that blocks emotes while cuffed).

## Steps

1. Place the resource folder in your resources directory.
2. Ensure it after its dependencies in `server.cfg`:

```cfg
ensure kora_lib
ensure kora_theme
ensure kora_emotemenu
```

3. Grant the `command` ACE to the staff group that may use the Emote Maker (see [Commands](./commands.md)).
4. Make sure the resource folder is writable by the server process if you want to use the Emote Maker, because it writes `shared/created.json` (see [Data storage](./data.md)).

The default menu key is `F3`; players can rebind it in the FiveM keybind settings.

## Rebuilding the NUI

`ui/dist` is committed, so no build step is needed to run the resource. To change the Emote Maker UI, edit `ui/src` and run the Vite build in `ui/` (`npm install`, then `npm run build`; check `ui/package.json` for the exact scripts).
