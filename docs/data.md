---
title: Data storage
sidebar_position: 10
---

# Data storage

The resource does not use a database and defines no SQL tables or items.

| Data | Where | Details |
| --- | --- | --- |
| Emotes created with the Emote Maker | `shared/created.json` in the resource folder | JSON object keyed by emote name, written by the server with `SaveResourceFile` (sorted keys, indented) and read once at server start. The server needs write access to the resource folder. Because the file is inside the resource, back it up or commit it if you want to keep created emotes when redeploying. |
| Walk style and expression | Client KVP keys `walk` and `expression` | Stored only when `Config.persistAppearance` is on; restored about one second after the resource starts if the key still exists in the config. |
| Last played emote, active emote | State bags | See [Exports](./exports.md). Not persisted. |
