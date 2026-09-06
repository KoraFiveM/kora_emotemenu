local pendingBySource = {}
local pendingByTarget = {}
local activePartner = {}
local lastRequestAt = {}
local nextInviteId = 0

local function validSync(source, target, emoteName)
    target = tonumber(target)
    if not target or target % 1 ~= 0 or target <= 0 or target == source then return false, 'Choose another nearby player.' end
    local emote = QBEEmotes[emoteName]
    if not emote or not emote.sync or not QBEEmotes[emote.sync.partner] then return false, 'That shared emote is unavailable.' end
    local sourcePed, targetPed = GetPlayerPed(source), GetPlayerPed(target)
    if sourcePed == 0 or targetPed == 0 then return false, 'That player is no longer available.' end
    if GetPlayerRoutingBucket(source) ~= GetPlayerRoutingBucket(target) then return false, 'That player is in another instance.' end
    if #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > Config.syncDistance then return false, 'That player is too far away.' end
    return true, emote
end

RegisterNetEvent('qbemotemenu:server:sync', function(target, emoteName)
    local source = source
    if type(emoteName) ~= 'string' then return end
    local current = GetGameTimer()
    if lastRequestAt[source] and current - lastRequestAt[source] < Config.syncCooldown then return end
    lastRequestAt[source] = current
    local ok, emoteOrReason = validSync(source, target, emoteName:lower())
    if not ok then
        return QB.notify.send(source, { title = 'Emotes', message = emoteOrReason, type = 'error' })
    end
    target = tonumber(target)
    if pendingBySource[source] or pendingByTarget[target] or activePartner[source] or activePartner[target] then
        return QB.notify.send(source, { title = 'Emotes', message = 'One of you is already handling a shared emote.', type = 'error' })
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
        QB.notify.send(source, { title = 'Emotes', message = 'The shared emote request expired.', type = 'error' })
    end)
end)

RegisterNetEvent('qbemotemenu:server:respondSync', function(inviteId, accepted)
    local target = source
    local invite = pendingByTarget[target]
    if not invite or invite.id ~= tonumber(inviteId) then return end
    pendingByTarget[target] = nil
    pendingBySource[invite.source] = nil

    if accepted ~= true or invite.expiresAt < GetGameTimer() then
        return QB.notify.send(invite.source, { title = 'Emotes', message = 'The shared emote request was declined.', type = 'error' })
    end

    local ok, emoteOrReason = validSync(invite.source, target, invite.emote)
    if not ok or emoteOrReason.sync.partner ~= invite.partnerEmote then
        return QB.notify.send(invite.source, { title = 'Emotes', message = ok and 'The shared emote changed.' or emoteOrReason, type = 'error' })
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
    lastRequestAt[source] = nil
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
