---
title: Emote catalogue
sidebar_position: 8
---

# Emote catalogue

The built-in catalogue in `shared/emotes.lua` only uses Rockstar assets. Add your own entries to that table (the global `KoraEEmotes`), save them with the [Emote Maker](./emote-maker.md), or register them at runtime with the `registerEmote` export ([Exports](./api/client-exports.md)).

## Built-in emotes

| Key | Label | Category | Type | Notes |
| --- | --- | --- | --- | --- |
| `wave` | Wave | general | anim | |
| `salute` | Salute | general | anim | |
| `surrender` | Hands up | general | anim | `blockMovement`, `handsUp` |
| `sit` | Sit | scenarios | scenario | `WORLD_HUMAN_PICNIC` |
| `lean` | Lean | scenarios | scenario | `WORLD_HUMAN_LEANING` |
| `clipboard` | Clipboard | props | anim | one prop |
| `coffee` | Coffee | props | anim | one prop |
| `guitar` | Air guitar | dance | anim | flag 1 |
| `dance` | Dance | dance | anim | flag 1 |
| `dance2` | Dance 2 | dance | anim | flag 1 |
| `handshake` | Handshake | shared | anim | `sync` partner `handshake_partner`, `standing` |
| `hug` | Hug | shared | anim | `sync` partner `hug_partner`, `standing` |

`handshake_partner` and `hug_partner` are hidden entries played by the invited player.

## Definition fields

| Field | Applies to | Description |
| --- | --- | --- |
| `label` | all | Menu label. |
| `category` | visible emotes | Key of `Config.categories`. |
| `type` | all | `anim` or `scenario`. |
| `dict`, `clip` | anim | Animation dictionary and clip. |
| `scenario` | scenario | Scenario name. |
| `enterVehicle` | scenario | Passed to the scenario play call of `kora_lib`. |
| `flag` | anim | Animation flag, default 49. Bit 1 means looping. |
| `duration` | anim | Duration passed to `kora_lib`; emotes with a duration get no cancel hint. |
| `blockMovement` | anim | Disable `Config.blockedControls` and firing while active. |
| `handsUp` | anim | With `Config.handsUpAllowMovement`, keep movement controls enabled. |
| `standing` | all | Refuse in vehicles. |
| `sync` | anim | `{ partner = 'key' }`, the hidden partner emote. |
| `hidden` | all | Not shown in menus. |
| `icon` | visible emotes | Lucide icon name, default `Smile`. |
| `prop`, `proptwo` | anim | `model`, `bone` (ped bone id or a name from `KoraEBoneNames`), `offset` and `rotation` (`x`, `y`, `z`), optional `options` (`softPin`, `collision`, `vertexIndex`, `fixedRot`). |

Menu entries are sorted by label. Names are lowercase keys; the menu and `/e` look entries up by that key.

## Bone names

`KoraEBoneNames` maps `SKEL_L_Hand` 18905, `SKEL_R_Hand` 57005, `PH_L_Hand` 60309, `PH_R_Hand` 28422, `IK_L_Hand` 36029 and `IK_R_Hand` 6286. Numeric ids are used directly.

## Created emotes

Emotes saved by the Emote Maker are merged on the server at start; a built-in emote wins on a name clash. Clients receive them from the server when they load.
