local function validSync(source, target, emoteName)
    if type(target) ~= 'number' or target <= 0 or target == source then return false, 'Choose another nearby player.' end
    local emote = QBEEmotes[emoteName]
    if not emote or not emote.sync or not QBEEmotes[emote.sync.partner] then return false, 'That shared emote is unavailable.' end
    local sourcePed, targetPed = GetPlayerPed(source), GetPlayerPed(target)
    if sourcePed == 0 or targetPed == 0 then return false, 'That player is no longer available.' end
    if #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > Config.syncDistance then return false, 'That player is too far away.' end
    return true, emote
end

RegisterNetEvent('qbemotemenu:server:sync', function(target, emoteName)
    local source = source
    if type(emoteName) ~= 'string' then return end
    local ok, emoteOrReason = validSync(source, target, emoteName:lower())
    if not ok then
        return QB.notify.send(source, { title = 'Emotes', message = emoteOrReason, type = 'error' })
    end
    TriggerClientEvent('qbemotemenu:client:playSynced', source, emoteName:lower())
    TriggerClientEvent('qbemotemenu:client:playSynced', target, emoteOrReason.sync.partner)
end)
