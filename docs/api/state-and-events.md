---
title: "State bags and events"
sidebar_position: 3
---


# State bags and events

The local player's replicated state bag publishes four keys other resources can read without calling an export, plus the net events used internally for synced emotes and the emote creator.

Namespace: `LocalPlayer.state / net events` · Source: `client/main.lua`

## State bag keys (LocalPlayer.state, replicated)

| Key | Type | Description |
| --- | --- | --- |
| `kora_emotemenu:active` | string \| false | The currently playing emote name, or `false` when none is active. |
| `kora_emotemenu:last` | string \| nil | The most recently played emote name. |
| `kora_emotemenu:walk` | string | The currently selected walk-style key (e.g. `'default'`, `'drunk'`). |
| `kora_emotemenu:expression` | string \| nil | The key of the currently applied expression (for example `'angry'`), or `nil` when no facial override is active (`default`, or an entry without `anim`). |

## Synced emotes (internal net events)

`kora_emotemenu:server:sync` (client→server) requests a shared emote with the nearest player within `Config.syncDistance`; the server validates distance/routing bucket and rate-limits requests with `Kora.timers.cooldown(Config.syncCooldown)`. `kora_emotemenu:client:syncInvite` asks the target to accept/decline via `Kora.nui.openAlert`; the response goes back through `kora_emotemenu:server:respondSync`. On acceptance the server fires `kora_emotemenu:client:playSynced` on both clients; `kora_emotemenu:server:cancelSync` / `kora_emotemenu:client:cancelSynced` tear it down (also on disconnect, via `playerDropped`). Invites expire after `Config.syncInviteTTL` ms.

## Emote creator sync (internal net events)

Emotes saved or deleted through `/emoteMaker` are broadcast to every client with `kora_emotemenu:client:addEmotes` / `kora_emotemenu:client:removeEmotes` (both check `source == 65535`, i.e. that they came from the server, before applying). A newly connecting client asks for the current custom set with `kora_emotemenu:server:requestCreated` as soon as its own `client/main.lua` loads.

## Limits and related APIs

These keys are read-only conveniences; use the client exports to change the underlying state.

## Additional state keys

The resource also writes `koraUiBlocked` (not replicated) while the Emote Maker freecam is active and `Config.emoteMaker.blockUi` is on, and reads `isDead`, `dead`, `koraCuffed`, `isCuffed` and `handcuffed` from the local state.

## Event reference

These events are internal to the resource. The resource defines no local (non-net) events of its own and no server callbacks. Do not trigger them from other resources.

### Server events (client to server)

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_emotemenu:server:sync` | `targetServerId`, `emoteName` | Starts a shared emote invite. Applies the per-player cooldown, validates the target and emote, and refuses if either player already has an invite or active shared emote. Expires after `Config.syncInviteTTL`. |
| `kora_emotemenu:server:respondSync` | `inviteId`, `accepted` | From the invited player. Must match the pending invite id. On `true` and not expired, re-validates and triggers `playSynced` on both players; otherwise notifies the initiator of the decline. |
| `kora_emotemenu:server:cancelSync` | none | Ends the active shared emote and sends `cancelSynced` to the partner. |
| `kora_emotemenu:server:requestCreated` | none | Sent by every client on load; the server answers with `addEmotes` containing all created emotes. |
| `kora_emotemenu:server:saveEmote` | `payload` table | Emote Maker save (ACE `command`, 2 s cooldown). See [Emote Maker](../emote-maker.md). |
| `kora_emotemenu:server:requestEmotesForEdit` | none | Emote Maker: ACE `command`; answers with `creatorEmotes`. |
| `kora_emotemenu:server:deleteCreatedEmote` | `name` | Emote Maker delete (ACE `command`, 1 s cooldown). |

### Client events (server to client)

All handlers of the creator events and the catalogue events ignore the event unless it comes from the server (source 65535).

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_emotemenu:client:syncInvite` | `inviteId`, `playerName`, `emoteLabel` | Shows an Accept/Decline alert. Auto-declines when the player cannot use emotes. |
| `kora_emotemenu:client:playSynced` | `emoteName`, `partnerServerId` | Plays the assigned emote; on failure notifies and sends `cancelSync`. |
| `kora_emotemenu:client:cancelSynced` | `partnerServerId` | Cancels the local emote if it is the shared emote with that partner. |
| `kora_emotemenu:client:addEmotes` | table of name to definition | Merges emotes into the client catalogue (created emotes). |
| `kora_emotemenu:client:removeEmotes` | list of names | Removes emotes from the client catalogue. |
| `kora_emotemenu:client:openEmoteCreator` | none | Opens the editor, or returns from the freecam. |
| `kora_emotemenu:client:creatorEmotes` | table of created emotes | Fills the editor's saved-emote list. |
| `kora_emotemenu:client:emoteSaved` | none | Resets and closes the editor after a successful save. |
| `kora_emotemenu:client:emoteDeleted` | `name` | Clears the editor if it was editing that emote. |

### Other events handled

- `kora_theme:playerThemeChanged` (client) updates the Emote Maker highlight colour.
- `playerDropped` (server) clears cooldowns, pending invites and active shared-emote pairs.
- `onClientResourceStop`, `onResourceStop` clean up emotes, props, cameras and facial overrides.

### NUI callbacks

The Emote Maker page posts `creator:change`, `creator:action` (actions `play`, `stop`, `new`, `add`, `remove`, `apply`, `freecam`, `load-list`, `delete`, `load`, `save`) and `creator:close` to the client.
