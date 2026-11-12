---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Emote Menu is a from-scratch, kora_lib-native emote resource: a radial/context/app-shell emote menu, walk styles, facial expressions, synced two-player emotes, and an in-game React emote creator (`/emoteMaker`). It answers to the legacy `kora_emotemenu` export name.

## Install it

1. **Add the folder** — Place `kora_emotemenu` in your resources directory (on the Kora dev server it is `resources/[standalone]/kora_emotemenu`).

2. **Start it after its dependencies** — The manifest declares `dependency 'kora_lib'` then `dependency 'kora_theme'`, each on its own line. FXServer only enforces resource start order from the singular `dependency 'name'` directive called once per dependency — the plural table form `dependencies { 'a', 'b' }` is not a real load-order directive, so this resource is deliberately written with one `dependency` call per line.

   ```lua title="fxmanifest.lua" {15,16}
   fx_version 'cerulean'
   game 'gta5'
   lua54 'yes'
   use_experimental_fxv2_oal 'yes'

   name 'kora_emotemenu'
   author 'qbcore2'
   version '0.2.0'
   description 'A configurable FiveM emote menu with a live React emote creator.'

   ui_page 'ui/dist/index.html'

   -- `dependency` singular, called once per dependency: this codebase's convention.
   -- The plural `dependencies { ... }` form does not enforce FXServer load order.
   dependency 'kora_lib'
   dependency 'kora_theme'

   shared_script '@kora_lib/init.lua'

   shared_scripts {
       'config.lua',
       'shared/emotes.lua'
   }

   client_scripts {
       '@kora_theme/client/bridge.lua',
       'client/main.lua',
       'client/emote_creator.lua',
   }
   server_script {
       'server/**.lua'
   }

   files {
       'ui/dist/index.html',
       'ui/dist/assets/**/*'
   }

   -- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
   qa_feature 'tests/*.feature'
   ```

3. **Confirm server.cfg order** — Make sure `kora_lib` and `kora_theme` are both `ensure`d before `kora_emotemenu` in `server.cfg` as well — the manifest `dependency` lines start them first automatically, but an explicit order in `server.cfg` keeps logs readable.

   ```bash title="server.cfg"
   ensure kora_theme
   ensure kora_lib
   ensure kora_emotemenu
   ```

4. **Default keybind** — The menu opens on `F3` by default (`Config.keybind.defaultKey`), registered through `Kora.keybind.add` so players can rebind it from FiveM's own keybind settings ("Open emote menu"). `/emotes` (or `/e <name>`) and `/cancel` also work without the keybind.

## The React emote creator UI

The emote creator is a bundled React app served from `ui_page 'ui/dist/index.html'` and shipped through `files`. It is opened in-game with `/emoteMaker` (registered server-side via `Kora.commands.add`, gated on the `command` ACE) and lets a staff member preview an animation/prop combination live, then save it to disk.

## Dependencies

Declared in `fxmanifest.lua` with `dependency`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | Menus (radial, context, app shell), alerts, keybinds, animation and prop streaming, control blocking, text UI, notifications, commands, timers, config registration. Its `init.lua` is loaded as a shared script. |
| `kora_theme` | Loads its client bridge and supplies the highlight colour for the menu check marks and the Emote Maker. |

Optional integrations that are read only through state and are not required: `kora_police` (sets the `koraCuffed` state bag that blocks emotes while cuffed).

## Staff access and writable folder

- Grant the `command` ACE to the staff group that may use the Emote Maker (see [Commands](./commands.md)).
- Make sure the resource folder is writable by the server process if you want to use the Emote Maker, because it writes `shared/created.json` (see [Data storage](./data.md)).

## Rebuilding the NUI

`ui/dist` is committed, so no build step is needed to run the resource. To change the Emote Maker UI, edit `ui/src` and run the Vite build in `ui/` (`npm install`, then `npm run build`; check `ui/package.json` for the exact scripts).
