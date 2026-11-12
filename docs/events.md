---
title: Events
sidebar_position: 7
---

# Events

These events are internal to the resource. The resource defines no local (non-net) events of its own and no server callbacks. Do not trigger them from other resources.

## Server events (client to server)

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_emotemenu:server:sync` | `targetServerId`, `emoteName` | Starts a shared emote invite. Applies the per-player cooldown, validates the target and emote, and refuses if either player already has an invite or active shared emote. Expires after `Config.syncInviteTTL`. |
| `kora_emotemenu:server:respondSync` | `inviteId`, `accepted` | From the invited player. Must match the pending invite id. On `true` and not expired, re-validates and triggers `playSynced` on both players; otherwise notifies the initiator of the decline. |
| `kora_emotemenu:server:cancelSync` | none | Ends the active shared emote and sends `cancelSynced` to the partner. |
| `kora_emotemenu:server:requestCreated` | none | Sent by every client on load; the server answers with `addEmotes` containing all created emotes. |
| `kora_emotemenu:server:saveEmote` | `payload` table | Emote Maker save (ACE `command`, 2 s cooldown). See [Emote Maker](./emote-maker.md). |
| `kora_emotemenu:server:requestEmotesForEdit` | none | Emote Maker: ACE `command`; answers with `creatorEmotes`. |
| `kora_emotemenu:server:deleteCreatedEmote` | `name` | Emote Maker delete (ACE `command`, 1 s cooldown). |

## Client events (server to client)

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

## Other events handled

- `kora_theme:playerThemeChanged` (client) updates the Emote Maker highlight colour.
- `playerDropped` (server) clears cooldowns, pending invites and active shared-emote pairs.
- `onClientResourceStop`, `onResourceStop` clean up emotes, props, cameras and facial overrides.

## NUI callbacks

The Emote Maker page posts `creator:change`, `creator:action` (actions `play`, `stop`, `new`, `add`, `remove`, `apply`, `freecam`, `load-list`, `delete`, `load`, `save`) and `creator:close` to the client.
