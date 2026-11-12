# kora_emotemenu agent guide

`kora_emotemenu` is a Kora emote menu built on `kora_lib`: radial/context/app menus, animations, scenarios, props, shared emotes, walk styles, expressions, and an in-game Emote Maker. Layout: `fxmanifest.lua`, `config.lua`, `shared/emotes.lua` (built-in catalogue) and `shared/created.json` (emotes saved by the maker), `client/main.lua` and `client/emote_creator.lua`, `server/main.lua` and `server/emote_creator.lua`, `ui/` (React/Vite Emote Maker, built into `ui/dist`), `tests/` (offline Lua tests and kora_qa features).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first; it links every page. Layout: `index.md` (hub and documentation map), `installation.md` (manifest, dependencies, load order, NUI rebuild), `how-to-use.md` (emote entry format, `registerEmote`, vehicles/cuffs/persistence), `commands.md` (commands, keybind, permissions), `api/` (`client-exports.md` for exports, `state-and-events.md` for state bags, net events and NUI callbacks), and topic pages (`configuration.md`, `features.md`, `emotes.md`, `emote-maker.md`, `data.md`, `troubleshooting.md`). Update the page that owns the topic.

Feature and behaviour changes must update the matching docs in the same change. When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
