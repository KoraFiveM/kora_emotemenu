local pendingBySource = {}
local pendingByTarget = {}
local activePartner = {}
local requestCooldown = Kora.timers.cooldown(Config.syncCooldown)
local nextInviteId = 0

Kora.commands.add('emoteMaker', 'Open the emote creator', nil, false, function(source)
    if not IsPlayerAceAllowed(source, 'commands') then
        return Kora.notify.send(source, { title = 'Emotes', message = 'You do not have permission to use this command.', type = 'error' })
    end
    TriggerClientEvent('qbemotemenu:client:openEmoteCreator', source)
end)

local function validSync(source, target, emoteName)
    target = tonumber(target)
    if not Kora.util.isInteger(target) or target <= 0 or target == source then return false, 'Choose another nearby player.' end
    local emote = QBEEmotes[emoteName]
    if not emote or not emote.sync or not QBEEmotes[emote.sync.partner] then return false, 'That shared emote is unavailable.' end
    local _, reason = Kora.world.resolveNearbyPlayer(source, target, { maxDistance = Config.syncDistance })
    if reason == 'routing_bucket_mismatch' then return false, 'That player is in another instance.' end
    if reason == 'too_far' then return false, 'That player is too far away.' end
    if type(reason) ~= 'number' then return false, 'That player is no longer available.' end
    return true, emote
end

RegisterNetEvent('qbemotemenu:server:sync', function(target, emoteName)
    local source = source
    if type(emoteName) ~= 'string' then return end
    if not requestCooldown.use(source) then return end
    local current = GetGameTimer()
    local ok, emoteOrReason = validSync(source, target, emoteName:lower())
    if not ok then
        return Kora.notify.send(source, { title = 'Emotes', message = emoteOrReason, type = 'error' })
    end
    target = tonumber(target)
    if pendingBySource[source] or pendingByTarget[source]
        or pendingBySource[target] or pendingByTarget[target]
        or activePartner[source] or activePartner[target] then
        return Kora.notify.send(source, { title = 'Emotes', message = 'One of you is already handling a shared emote.', type = 'error' })
    end

    nextInviteId = nextInviteId + 1
    local invite = {
        id = nextInviteId,
        source = source,
        target = target,
        emote = emoteName:lower(),
        partnerEmote = emoteOrReason.sync.partner,
        expiresAt = current + Config.syncInviteTTL,
    }
    pendingBySource[source] = invite
    pendingByTarget[target] = invite
    TriggerClientEvent('qbemotemenu:client:syncInvite', target, invite.id, GetPlayerName(source) or ('Player %d'):format(source), emoteOrReason.label)

    SetTimeout(Config.syncInviteTTL, function()
        if pendingBySource[source] ~= invite then return end
        pendingBySource[source] = nil
        pendingByTarget[target] = nil
        Kora.notify.send(source, { title = 'Emotes', message = 'The shared emote request expired.', type = 'error' })
    end)
end)

RegisterNetEvent('qbemotemenu:server:respondSync', function(inviteId, accepted)
    local target = source
    local invite = pendingByTarget[target]
    if not invite or invite.id ~= tonumber(inviteId) then return end
    pendingByTarget[target] = nil
    pendingBySource[invite.source] = nil

    if accepted ~= true or invite.expiresAt < GetGameTimer() then
        return Kora.notify.send(invite.source, { title = 'Emotes', message = 'The shared emote request was declined.', type = 'error' })
    end

    local ok, emoteOrReason = validSync(invite.source, target, invite.emote)
    if not ok or emoteOrReason.sync.partner ~= invite.partnerEmote then
        return Kora.notify.send(invite.source, { title = 'Emotes', message = ok and 'The shared emote changed.' or emoteOrReason, type = 'error' })
    end

    activePartner[invite.source] = target
    activePartner[target] = invite.source
    TriggerClientEvent('qbemotemenu:client:playSynced', invite.source, invite.emote, target)
    TriggerClientEvent('qbemotemenu:client:playSynced', target, invite.partnerEmote, invite.source)
end)

RegisterNetEvent('qbemotemenu:server:cancelSync', function()
    local source = source
    local partner = activePartner[source]
    if not partner then return end
    activePartner[source] = nil
    if activePartner[partner] == source then
        activePartner[partner] = nil
        TriggerClientEvent('qbemotemenu:client:cancelSynced', partner, source)
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
        TriggerClientEvent('qbemotemenu:client:cancelSynced', partner, source)
    end
end)

