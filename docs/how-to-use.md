---
title: "How to use"
sidebar_position: 3
---


# How to use

The built-in catalogue in `shared/emotes.lua` intentionally contains only Rockstar-native examples (no third-party animation or prop assets are bundled). Add your own entries there, or register them at runtime from another client resource.

## Emote entries (shared/emotes.lua)

Each key of the `KoraEEmotes` table is an emote name; the value is a definition table. Visible emotes need a `category` key that matches one configured in `Config.categories` (`general`, `dance`, `props`, `scenarios`, `shared` by default); a `hidden = true` entry (used for sync partners) does not.

```text title="shared/emotes.lua (excerpt)"
wave = {
    label = 'Wave', category = 'general', type = 'anim',
    dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49,
},
handshake = {
    label = 'Handshake', category = 'shared', type = 'anim',
    dict = 'mp_ped_interaction', clip = 'handshake_guy_a', flag = 0,
    sync = { partner = 'handshake_partner' }, standing = true,
},
handshake_partner = {
    label = 'Handshake (partner)', hidden = true, standing = true, type = 'anim',
    dict = 'mp_ped_interaction', clip = 'handshake_guy_b', flag = 0,
},
```

- `label` — display text in the menu.
- `type` — `'anim'` or `'scenario'`.
- `'anim'` entries: `dict` and `clip` (the animation dictionary/clip), and `flag` (the native `TaskPlayAnim` flag bitmask; `49` = upper-body + looping, `1` = full-body looping, `0` = one-shot full-body).
- `'scenario'` entries: `scenario` (a scenario name such as `WORLD_HUMAN_PICNIC`) and optional `enterVehicle`.
- `blockMovement` — when true, movement/combat controls listed in `Config.blockedControls` are disabled while the emote plays (via `Kora.controls.acquire`).
- `handsUp` — marks an emote (the built-in `surrender`/"Hands up") that, when `Config.handsUpAllowMovement` is true, still allows walking while blocking sprint/jump/vehicle-entry/aim/fire.
- `standing` — the emote is always refused while the player is seated in a vehicle, regardless of `Config.vehicle.allowEmotes`.
- `prop` / `proptwo` — `{ model, bone, offset = {x,y,z}, rotation = {x,y,z}, options? }`, attached with `AttachEntityToEntity` once the model streams in. `bone` accepts a numeric ped bone id or one of the names in `KoraEBoneNames` (`SKEL_L_Hand`, `SKEL_R_Hand`, `PH_L_Hand`, `PH_R_Hand`, `IK_L_Hand`, `IK_R_Hand`).
- `sync = { partner = 'other_emote_name' }` — marks a two-player emote; `partner` must name another catalogue entry (conventionally `hidden = true`) played on the other participant. Sync distance/cooldown/invite expiry are configured server-side (`Config.syncDistance`, `Config.syncCooldown`, `Config.syncInviteTTL`) and checked again on the server before either client is told to play.

## Registering an emote from another resource

Call the `registerEmote` client export from any client script loaded after `kora_emotemenu`. It validates the definition and throws (via `assert`) on a malformed one, so wrap the call if you register from untrusted input.

```lua title="client.lua"
exports.kora_emotemenu:registerEmote('my_emote', {
    label = 'My emote', category = 'general', type = 'anim',
    dict = 'my_anim_dict', clip = 'my_clip', flag = 49,
})
```

- `name` must match `^[%w_%-]+$` (letters, digits, `_`, `-`); it is lower-cased before being stored.
- `definition.label` is required; `definition.type` must be `'anim'` or `'scenario'`.
- A visible emote (`hidden` not `true`) requires `definition.category` to be a key already present in `Config.categories`.
- `'anim'` emotes require `dict` and `clip` strings; `'scenario'` emotes require a `scenario` string.
- This export only affects the calling client's own local emote table — it is not synced to other players and not persisted. For a catalogue entry every player sees, edit `shared/emotes.lua` (loaded as a shared script) instead, or have staff save it through the in-game emote creator (`/emoteMaker`), which both players and the server persist.

## Vehicles, cuffs and appearance persistence

- In a vehicle the menu never removes the player from their seat: it never calls `ClearPedTasksImmediately` while seated, and cancelling uses `Kora.anim.stop` + `ClearPedSecondaryTask` instead. `Config.vehicle.allowEmotes = false` refuses every emote in a vehicle; `upperBodyOnly = true` (default) forces animation flag 48/49 and blocks walk-style changes while seated; `blockedInVehicle` lists specific emote names to refuse. Scenarios and any emote with `standing = true` are always refused in a vehicle.
- A cuffed player (`LocalPlayer.state.koraCuffed`, set by kora_police, or the `isCuffed`/`handcuffed` keys used by other cuff scripts) cannot start an emote, and a running one is cancelled the instant they become cuffed — the client polls this every frame while an emote plays. `Config.blockWhenCuffed = false` disables the check.
- Walk style and facial expression are each stored with `SetResourceKvp` when `Config.persistAppearance` is true (the default), and are re-applied 1 second after the resource starts.
