local pendingBySource = {}
local pendingByTarget = {}
local activePartner = {}
local requestCooldown = Kora.timers.cooldown(Config.syncCooldown)
local nextInviteId = 0

Kora.commands.add('emoteMaker', Kora.lang('command.open_emote_creator'), nil, false, function(source)
    if not IsPlayerAceAllowed(source, 'command') then
        return Kora.notify.send(source, { title = Kora.lang('title.emotes'), message = Kora.lang('error.command_permission'), type = 'error' })
    end
    TriggerClientEvent('kora_emotemenu:client:openEmoteCreator', source)
end)

local function validSync(source, target, emoteName)
    target = tonumber(target)
    if not Kora.util.isInteger(target) or target <= 0 or target == source then return false, Kora.lang('error.choose_another_player') end
    local emote = KoraEEmotes[emoteName]
    if not emote or not emote.sync or not KoraEEmotes[emote.sync.partner] then return false, Kora.lang('error.shared_emote_unavailable') end
    local _, reason = Kora.world.resolveNearbyPlayer(source, target, { maxDistance = Config.syncDistance })
    if reason == 'routing_bucket_mismatch' then return false, Kora.lang('error.player_other_instance') end
    if reason == 'too_far' then return false, Kora.lang('error.player_too_far') end
    if type(reason) ~= 'number' then return false, Kora.lang('error.player_unavailable') end
    return true, emote
end

RegisterNetEvent('kora_emotemenu:server:sync', function(target, emoteName)
    local source = source
    if type(emoteName) ~= 'string' then return end
    if not requestCooldown.use(source) then return end
    emoteName = emoteName:lower()
    local current = GetGameTimer()
    local ok, emoteOrReason = validSync(source, target, emoteName)
    if not ok then
        return Kora.notify.send(source, { title = Kora.lang('title.emotes'), message = emoteOrReason, type = 'error' })
    end
    target = tonumber(target)
    if pendingBySource[source] or pendingByTarget[source]
        or pendingBySource[target] or pendingByTarget[target]
        or activePartner[source] or activePartner[target] then
        return Kora.notify.send(source, { title = Kora.lang('title.emotes'), message = Kora.lang('error.sync_already_pending'), type = 'error' })
    end

    nextInviteId = nextInviteId + 1
    local invite = {
        id = nextInviteId,
        source = source,
        target = target,
        emote = emoteName,
        partnerEmote = emoteOrReason.sync.partner,
        expiresAt = current + Config.syncInviteTTL,
    }
    pendingBySource[source] = invite
    pendingByTarget[target] = invite
    TriggerClientEvent('kora_emotemenu:client:syncInvite', target, invite.id, GetPlayerName(source) or Kora.lang('ui.player_number', source), emoteOrReason.label)

    SetTimeout(Config.syncInviteTTL, function()
        if pendingBySource[source] ~= invite then return end
        pendingBySource[source] = nil
        pendingByTarget[target] = nil
        Kora.notify.send(source, { title = Kora.lang('title.emotes'), message = Kora.lang('error.sync_request_expired'), type = 'error' })
    end)
end)

RegisterNetEvent('kora_emotemenu:server:respondSync', function(inviteId, accepted)
    local target = source
    local invite = pendingByTarget[target]
    if not invite or invite.id ~= tonumber(inviteId) then return end
    pendingByTarget[target] = nil
    pendingBySource[invite.source] = nil

    if accepted ~= true or invite.expiresAt < GetGameTimer() then
        return Kora.notify.send(invite.source, { title = Kora.lang('title.emotes'), message = Kora.lang('error.sync_request_declined'), type = 'error' })
    end

    local ok, emoteOrReason = validSync(invite.source, target, invite.emote)
    if not ok or emoteOrReason.sync.partner ~= invite.partnerEmote then
        return Kora.notify.send(invite.source, { title = Kora.lang('title.emotes'), message = ok and Kora.lang('error.sync_emote_changed') or emoteOrReason, type = 'error' })
    end

    activePartner[invite.source] = target
    activePartner[target] = invite.source
    TriggerClientEvent('kora_emotemenu:client:playSynced', invite.source, invite.emote, target)
    TriggerClientEvent('kora_emotemenu:client:playSynced', target, invite.partnerEmote, invite.source)
end)

RegisterNetEvent('kora_emotemenu:server:cancelSync', function()
    local source = source
    local partner = activePartner[source]
    if not partner then return end
    activePartner[source] = nil
    if activePartner[partner] == source then
        activePartner[partner] = nil
        TriggerClientEvent('kora_emotemenu:client:cancelSynced', partner, source)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    requestCooldown.reset(source)
    local invite = pendingBySource[source] or pendingByTarget[source]
    if invite then
        pendingBySource[invite.source] = nil
        pendingByTarget[invite.target] = nil
    end
    local partner = activePartner[source]
    activePartner[source] = nil
    if partner and activePartner[partner] == source then
        activePartner[partner] = nil
        TriggerClientEvent('kora_emotemenu:client:cancelSynced', partner, source)
    end
end)
