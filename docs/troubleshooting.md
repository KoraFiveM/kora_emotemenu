---
title: Troubleshooting
sidebar_position: 11
---

# Troubleshooting

**The menu does not open.** You cannot open it while dead or cuffed (the "You cannot use emotes right now." notification). Check that `kora_lib` and `kora_theme` started before this resource and that the key is not rebound in the FiveM settings.

**`menuStyle = 'app'` shows the radial menu.** The app shell could not be registered or updated; the server console prints a yellow warning with the reason. Check the `kora_lib` version.

**An emote is refused in a vehicle.** Scenarios and `standing` emotes are always refused in vehicles; check `Config.vehicle` (`allowEmotes`, `blockedInVehicle`).

**Hands up lets me sprint and jump.** With `Config.handsUpAllowMovement = true` the code leaves controls 21 (sprint), 22 (jump) and 30 to 35 enabled; only vehicle entry, attack and aim (and firing) stay blocked. Set it to `false` to block all of `Config.blockedControls`.

**A shared emote does nothing.** You must be within `Config.syncDistance` of another player, the other player must accept within `Config.syncInviteTTL`, neither of you may already be in a shared emote, and requests are rate limited by `Config.syncCooldown`. Shared emotes added only through the `registerEmote` export are rejected by the server.

**An emote or prop does not show.** The animation dictionary or clip may be wrong or not streamed; the player gets an error notification. A bone or prop model that does not exist cancels the emote.

**`/emoteMaker` says no permission.** Grant the ACE `command` to the player (see [Commands](./commands.md)).

**"The emote could not be written to disk."** The server cannot write `shared/created.json`; check folder permissions.

**Walk style or expression is not restored.** Requires `Config.persistAppearance = true` and the key still defined in `Config.walks` or `Config.expressions`.

**Expressions of other players do not appear.** They are applied from the other player's state bag while that player is in scope and the expression has an `anim`.
