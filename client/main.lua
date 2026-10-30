local emotes = {}
local active = { name = nil, props = {}, controls = nil, syncPartner = nil }
local menuOpen = false
local lastEmote = nil
local activeWalkClip = nil
local cancelMonitorRunning = false
local MENU_APP_ID = 'qbemotemenu:menu'
local appSelection

local function notify(message, kind)
    QB.notify.send({ title = 'Emotes', message = message, type = kind or 'info' })
end

for name, emote in pairs(QBEEmotes) do emotes[name] = QB.util.deepClone(emote) end

local function setState(key, value)
    LocalPlayer.state:set(('qbemotemenu:%s'):format(key), value, true)
end

local function canUse()
    local state = LocalPlayer.state
    return not state.isDead and not state.dead and not state.isCuffed and not state.handcuffed
end

local function clearProps(props)
    for _, prop in ipairs(props or active.props) do
        if DoesEntityExist(prop) then
            DetachEntity(prop, true, false)
            DeleteEntity(prop)
        end
    end
end

-- Config.propOverrides[emoteName].prop / .proptwo is merged over the shared prop data.
local function getPropConfig(name, slot)
    local config = emotes[name][slot]
    local override = Config.propOverrides and Config.propOverrides[name] and Config.propOverrides[name][slot]
    if not config or not override then return config end
    local merged = {}
    for key, value in pairs(config) do merged[key] = value end
    for key, value in pairs(override) do merged[key] = value end
    return merged
end

-- QB.anim.attachProp only accepts bone names, but emotes saved by the emote maker
-- store numeric bone ids (GetPedBoneIndex), so both forms are resolved here.
local function attachProp(ped, config)
    local bone = config.bone
    local boneIndex = type(bone) == 'number' and GetPedBoneIndex(ped, bone) or GetEntityBoneIndexByName(ped, bone)
    if boneIndex == -1 then return false, ('Bone %s does not exist on the ped.'):format(tostring(bone)) end

    local offset, rotation, options = config.offset or {}, config.rotation or {}, config.options or {}
    local prop
    local loaded, err = QB.stream.loadModel(config.model, function(hash)
        local created = CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, false, false, false)
        if created == 0 or not DoesEntityExist(created) then return end
        AttachEntityToEntity(created, ped, boneIndex,
            offset.x or 0.0, offset.y or 0.0, offset.z or 0.0,
            rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0,
            true, options.softPin ~= false, options.collision == true, true,
            options.vertexIndex or 1, options.fixedRot ~= false)
        prop = created
    end)
    if not loaded then return false, err end
    if not prop then return false, 'The emote prop could not be created.' end
    return prop
end

local function cancelEmote(silent, skipSyncNotice)
    local wasActive = active.name ~= nil
    local previous = active
    if previous.controls then QB.controls.release(previous.controls) end
    clearProps(previous.props)
    active = { name = nil, props = {}, controls = nil, syncPartner = nil }
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then QB.anim.clear(ped, true) end
    setState('active', false)
    if previous.syncPartner and not skipSyncNotice then
        TriggerServerEvent('qbemotemenu:server:cancelSync')
    end
    if wasActive and not silent then notify('Emote cancelled.') end
    return wasActive
end

local function startCancelMonitor()
    if cancelMonitorRunning then return end
    cancelMonitorRunning = true
    CreateThread(function()
        while active.name do
            if not canUse() or IsControlJustPressed(0, Config.cancelControl) or IsPedRagdoll(PlayerPedId()) then
                cancelEmote(true)
            end
            Wait(0)
        end
        cancelMonitorRunning = false
    end)
end

local function playLocal(name)
    local emote = emotes[name]
    if not emote then return false, 'That emote is not registered.' end
    if not canUse() then return false, 'You cannot use emotes right now.' end

    cancelEmote(true)
    local ped = PlayerPedId()
    local played, err
    if emote.type == 'scenario' then
        QB.anim.playScenario(ped, emote.scenario, emote.enterVehicle)
        played = true
    elseif emote.type == 'anim' then
        local handle
        handle, err = QB.anim.play(ped, emote.dict, emote.clip, { flag = emote.flag or 49, duration = emote.duration })
        played = handle ~= false
    else
        return false, 'The emote has an unknown type.'
    end
    if not played then return false, err or 'The animation could not be loaded.' end

    active.name = name
    if emote.blockMovement then active.controls = QB.controls.acquire(Config.blockedControls, { disablePlayerFiring = true }) end
    for _, slot in ipairs({ 'prop', 'proptwo' }) do
        local config = getPropConfig(name, slot)
        if config then
            local prop, propErr = attachProp(ped, config)
            if not prop then
                cancelEmote(true)
                return false, propErr or 'The emote prop could not be created.'
            end
            active.props[#active.props + 1] = prop
        end
    end
    setState('active', name)
    setState('last', name)
    lastEmote = name
    startCancelMonitor()
    return true
end

local function findClosestPlayer()
    local player, distance
    local localPed, localCoords = PlayerPedId(), GetEntityCoords(PlayerPedId())
    for _, candidate in ipairs(GetActivePlayers()) do
        if candidate ~= PlayerId() then
            local targetPed = GetPlayerPed(candidate)
            if DoesEntityExist(targetPed) then
                local candidateDistance = #(GetEntityCoords(targetPed) - localCoords)
                if candidateDistance <= Config.syncDistance and (not distance or candidateDistance < distance) then
                    player, distance = candidate, candidateDistance
                end
            end
        end
    end
    return player, localPed
end

local function playEmote(name)
    local emote = emotes[name]
    if not emote then return false, 'That emote is not registered.' end
    if not emote.sync then return playLocal(name) end
    local target = findClosestPlayer()
    if not target then return false, ('Move within %.1fm of another player.'):format(Config.syncDistance) end
    TriggerServerEvent('qbemotemenu:server:sync', GetPlayerServerId(target), name)
    return true
end

local function setWalk(name, quiet)
    local walk = Config.walks[name]
    if not walk then return false, 'That walk style is not configured.' end
    local ped = PlayerPedId()
    if walk.clipset then
        local loaded, err = QB.stream.loadClipSet(walk.clipset)
        if not loaded then return false, err or 'The walk style could not be loaded.' end
        if activeWalkClip and activeWalkClip ~= walk.clipset then RemoveClipSet(activeWalkClip) end
        SetPedMovementClipset(ped, walk.clipset, 0.25)
        activeWalkClip = walk.clipset
    else
        ResetPedMovementClipset(ped, 0.25)
        if activeWalkClip then RemoveClipSet(activeWalkClip) end
        activeWalkClip = nil
    end
    setState('walk', name)
    if Config.persistAppearance then SetResourceKvp('walk', name) end
    if not quiet then notify(('Walk style: %s'):format(walk.label)) end
    return true
end

local function setExpression(name, quiet)
    local expression = Config.expressions[name]
    if not expression then return false, 'That expression is not configured.' end
    local ped = PlayerPedId()
    if expression.anim then
        SetFacialIdleAnimOverride(ped, expression.anim, expression.dict)
    else
        ClearFacialIdleAnimOverride(ped)
    end
    setState('expression', name)
    if Config.persistAppearance then SetResourceKvp('expression', name) end
    if not quiet then notify(('Expression: %s'):format(expression.label)) end
    return true
end

local function visibleEmotes(category)
    local items = {}
    for name, emote in pairs(emotes) do
        if emote.category == category and not emote.hidden then
            items[#items + 1] = { id = 'emote:' .. name, label = emote.label or name, icon = emote.icon or 'Smile' }
        end
    end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end

local function optionItems(values, prefix)
    local items = {}
    for name, entry in pairs(values or {}) do items[#items + 1] = { id = prefix .. name, label = entry.label or name, icon = 'Circle' } end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end

local function menuItems()
    local items = {}
    for category, details in pairs(Config.categories) do
        local categoryItems = visibleEmotes(category)
        if #categoryItems > 0 then
            items[#items + 1] = { id = 'category:' .. category, label = details.label or category, icon = details.icon, submenu = { title = details.label or category, items = categoryItems } }
        end
    end
    table.sort(items, function(a, b) return a.label < b.label end)
    -- An option group with nothing in it would open as an empty page, so leave it out.
    local walks, expressions = optionItems(Config.walks, 'walk:'), optionItems(Config.expressions, 'expression:')
    if #walks > 0 then items[#items + 1] = { id = 'walk', label = 'Walk style', icon = 'Footprints', submenu = { title = 'Walk style', items = walks } } end
    if #expressions > 0 then items[#items + 1] = { id = 'expression', label = 'Expression', icon = 'ScanFace', submenu = { title = 'Expression', items = expressions } } end
    items[#items + 1] = { id = 'cancel', label = 'Cancel emote', icon = 'CircleX', disabled = active.name == nil, description = active.name and 'Stop the current emote' or 'No emote is playing' }
    return items
end

-- A context menu is one level, so each submenu is shown as its own page with a Back row.
local function openContextPages(items)
    local page, trail = items, {}
    while true do
        local rows = {}
        if #trail > 0 then rows[1] = { id = 'menu:back', label = 'Back', icon = 'ChevronLeft' } end
        for _, item in ipairs(page) do rows[#rows + 1] = item end
        local result = QB.nui.openContextMenu(rows)
        if not result or result.cancelled then return result end
        if result.selectedId == 'menu:back' then
            page = table.remove(trail)
        else
            local chosen
            for _, item in ipairs(page) do
                if item.id == result.selectedId then chosen = item break end
            end
            if not (chosen and chosen.submenu) then return result end
            trail[#trail + 1] = page
            page = chosen.submenu.items
        end
    end
end

local function appNavigation(items)
    local navigation = {}
    for _, item in ipairs(items) do
        local rows = {}
        if item.submenu then
            for _, entry in ipairs(item.submenu.items) do
                rows[#rows + 1] = { id = entry.id, label = entry.label, icon = entry.icon, action = { id = entry.id, label = 'Select' } }
            end
        else
            rows[1] = { id = item.id, label = item.label, description = item.description, icon = item.icon, action = { id = item.id, label = 'Select', disabled = item.disabled } }
        end
        local title = item.submenu and item.submenu.title or item.label
        local block = { type = 'list', id = item.id .. ':list', searchable = item.submenu ~= nil, items = rows }
        -- kora_lib wants a title on every empty block.
        if #rows == 0 then block = { type = 'empty', id = item.id .. ':empty', title = title, description = 'Nothing to show here yet.' } end
        navigation[#navigation + 1] = {
            id = item.id, label = item.label, icon = item.icon,
            content = { title = title, blocks = { block } },
        }
    end
    return navigation
end

local appRegistered = false
local appWarned = false

-- Registration is validated by kora_lib and can throw, so it never runs unprotected.
local function registerMenuApp()
    if appRegistered then return true end
    local ok, err = pcall(QB.nui.registerApp, {
        id = MENU_APP_ID,
        title = 'Emotes',
        icon = 'Smile',
        layout = 'compact',
        navigation = { { id = 'empty', label = 'Emotes', content = { blocks = { { type = 'empty', title = 'Emotes', description = 'Open the emote menu to choose an emote.' } } } } },
        onAction = function(actionId)
            appSelection = actionId
            return { close = true }
        end,
    })
    if ok then appRegistered = true return true end
    if not appWarned then
        appWarned = true
        print(('^3[kora_emotemenu] The App Shell menu style is unavailable (%s). Falling back to the radial style.^7'):format(tostring(err)))
    end
    return false
end

-- Returns nil when the app could not be used so the caller can fall back.
local function openAppPages(items)
    if not registerMenuApp() then return nil end
    appSelection = nil
    local ok, err = pcall(QB.nui.updateApp, MENU_APP_ID, { navigation = appNavigation(items) })
    if not ok then
        appRegistered = false
        if not appWarned then
            appWarned = true
            print(('^3[kora_emotemenu] The App Shell menu could not be updated (%s). Falling back to the radial style.^7'):format(tostring(err)))
        end
        return nil
    end
    QB.nui.openApp(MENU_APP_ID)
    if not appSelection then return { cancelled = true } end
    return { selectedId = appSelection }
end

registerMenuApp()

-- Same items for every style; Config.menuStyle is read here so it can change live.
local function openStyledMenu(items)
    local style = Config.menuStyle
    if style == 'context' then return openContextPages(items) end
    if style == 'app' then
        local result = openAppPages(items)
        if result then return result end
    end
    return QB.nui.openRadialMenu(items, { radius = 165 })
end

local function openMenu()
    if menuOpen then return end
    if not canUse() then return notify('You cannot use emotes right now.', 'error') end
    menuOpen = true
    local result = openStyledMenu(menuItems())
    menuOpen = false
    if not result or result.cancelled then return end
    local id = result.selectedId
    if id == 'cancel' then return cancelEmote() end
    local action, name = id:match('^(%a+):(.+)$')
    if action == 'emote' then
        local ok, err = playEmote(name)
        if not ok then notify(err, 'error') end
    elseif action == 'walk' then
        local ok, err = setWalk(name)
        if not ok then notify(err, 'error') end
    elseif action == 'expression' then
        local ok, err = setExpression(name)
        if not ok then notify(err, 'error') end
    end
end

QB.keybind.add({ name = Config.keybind.name, description = Config.keybind.label, defaultKey = Config.keybind.defaultKey, onPressed = openMenu })

RegisterCommand(Config.command, openMenu, false)
RegisterCommand('e', function(_, args)
    local name = args[1] and args[1]:lower()
    if not name then return openMenu() end
    local ok, err = playEmote(name)
    if not ok then notify(err, 'error') end
end, false)
RegisterCommand('cancel', function() cancelEmote() end, false)
RegisterCommand('walk', function(_, args)
    local ok, err = setWalk((args[1] or 'default'):lower())
    if not ok then notify(err, 'error') end
end, false)
RegisterCommand('expression', function(_, args)
    local ok, err = setExpression((args[1] or 'default'):lower())
    if not ok then notify(err, 'error') end
end, false)

RegisterNetEvent('qbemotemenu:client:syncInvite', function(inviteId, playerName, emoteLabel)
    CreateThread(function()
        if not canUse() then
            TriggerServerEvent('qbemotemenu:server:respondSync', inviteId, false)
            return
        end
        local result = QB.nui.openAlert({
            title = 'Shared emote request',
            message = ('%s wants to perform %s with you.'):format(playerName, emoteLabel),
            confirmLabel = 'Accept',
            cancelLabel = 'Decline',
        })
        TriggerServerEvent('qbemotemenu:server:respondSync', inviteId, result ~= nil and result.confirmed == true and canUse())
    end)
end)

RegisterNetEvent('qbemotemenu:client:playSynced', function(name, partner)
    local ok, err = playLocal(name)
    if not ok then
        TriggerServerEvent('qbemotemenu:server:cancelSync')
        notify(err, 'error')
        return
    end
    active.syncPartner = partner
end)

RegisterNetEvent('qbemotemenu:client:cancelSynced', function(partner)
    if active.syncPartner == partner then cancelEmote(true, true) end
end)

-- Emotes saved through the emote maker (server/emote_creator.lua).
RegisterNetEvent('qbemotemenu:client:addEmotes', function(created)
    if source ~= 65535 or type(created) ~= 'table' then return end
    for name, emote in pairs(created) do emotes[name] = QB.util.deepClone(emote) end
end)
TriggerServerEvent('qbemotemenu:server:requestCreated')

exports('toggleMenu', openMenu)
exports('playEmote', playEmote)
exports('cancelEmote', cancelEmote)
exports('isInEmote', function() return active.name ~= nil end)
exports('getLastEmote', function() return lastEmote end)
exports('registerEmote', function(name, definition)
    assert(type(name) == 'string' and name:match('^[%w_%-]+$'), 'Emote name must contain only letters, digits, _ or -.')
    assert(type(definition) == 'table' and type(definition.label) == 'string', 'Emote definition requires a label.')
    assert(definition.type == 'anim' or definition.type == 'scenario', 'Emote type must be anim or scenario.')
    assert(definition.hidden == true or Config.categories[definition.category], 'Visible emotes require a configured category.')
    if definition.type == 'anim' then assert(type(definition.dict) == 'string' and type(definition.clip) == 'string', 'Animation emotes require dict and clip.') end
    if definition.type == 'scenario' then assert(type(definition.scenario) == 'string', 'Scenario emotes require scenario.') end
    emotes[name:lower()] = QB.util.deepClone(definition)
end)
exports('setWalk', setWalk)
exports('resetWalk', function() return setWalk('default') end)
exports('setExpression', setExpression)
exports('resetExpression', function() return setExpression('default') end)

CreateThread(function()
    Wait(1000)
    if Config.persistAppearance then
        local walk, expression = GetResourceKvpString('walk'), GetResourceKvpString('expression')
        if walk and Config.walks[walk] then setWalk(walk, true) end
        if expression and Config.expressions[expression] then setExpression(expression, true) end
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cancelEmote(true)
        if activeWalkClip then RemoveClipSet(activeWalkClip) end
    end
end)
