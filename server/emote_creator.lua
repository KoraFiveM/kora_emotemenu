local RESOURCE = GetCurrentResourceName()
local CREATED_FILE = 'shared/created.json'
local saveCooldown = Kora.timers.cooldown(2000)
local deleteCooldown = Kora.timers.cooldown(1000)

local MAX_PROPS = 2
local PROP_SLOTS = { 'prop', 'proptwo' }
local NAME_PATTERN = '^[%w_%-]+$'
local ASSET_PATTERN = '^[%w_@%.%-%^]+$'
local CREATOR_CATEGORIES = { general = true, dance = true, props = true }

local function notify(source, message, kind)
    Kora.notify.send(source, { title = Kora.lang('title.emote_maker'), message = message, type = kind or 'error' })
end

local function text(value, pattern, maxLength)
    if type(value) ~= 'string' or #value == 0 or #value > maxLength then return nil end
    if pattern and not value:match(pattern) then return nil end
    return value
end

local function integer(value, min, max)
    if type(value) ~= 'number' or value ~= math.floor(value) or value < min or value > max then return nil end
    return math.floor(value)
end

local function vector(value)
    if type(value) ~= 'table' then return nil end
    local out = {}
    for _, axis in ipairs({ 'x', 'y', 'z' }) do
        local n = value[axis]
        if type(n) ~= 'number' or n ~= n or math.abs(n) > 1000.0 then return nil end
        out[axis] = math.floor(n * 10000.0 + 0.5) / 10000.0
    end
    return out
end

local function validProp(prop)
    if type(prop) ~= 'table' then return nil end

    local model, bone = text(prop.model, '^[%w_]+$', 64), integer(prop.bone, 0, 99999)
    local offset, rotation = vector(prop.offset), vector(prop.rotation)
    if not (model and bone and offset and rotation) then return nil end

    return { model = model, bone = bone, offset = offset, rotation = rotation }
end

-- Builds a clean emote definition from untrusted client data. Nothing the
-- client sent is stored as-is; it is either rebuilt from checked values or
-- rejected with a reason.
local function buildEmote(payload)
    if type(payload) ~= 'table' then return nil, Kora.lang('error.invalid_emote_data') end

    local name = text(payload.name, NAME_PATTERN, 32)
    if not name then return nil, Kora.lang('error.invalid_emote_name') end
    name = name:lower()

    local label = text(payload.label, nil, 40)
    if not label then return nil, Kora.lang('error.enter_label_max', 40) end

    if not CREATOR_CATEGORIES[payload.category] or not Config.categories[payload.category] then
        return nil, Kora.lang('error.choose_valid_category')
    end

    local dict, clip = text(payload.dict, ASSET_PATTERN, 128), text(payload.clip, ASSET_PATTERN, 128)
    if not (dict and clip) then return nil, Kora.lang('error.enter_valid_animation') end

    local flag = integer(payload.flag, 0, 65535)
    if not flag then return nil, Kora.lang('error.flag_whole_number') end

    local props = type(payload.props) == 'table' and payload.props or {}
    if #props > MAX_PROPS then return nil, Kora.lang('error.max_props', MAX_PROPS) end

    local emote = {
        label = label,
        category = payload.category,
        type = 'anim',
        dict = dict,
        clip = clip,
        flag = flag,
    }

    for index, prop in ipairs(props) do
        local valid = validProp(prop)
        if not valid then return nil, Kora.lang('error.prop_invalid', index) end
        emote[PROP_SLOTS[index]] = valid
    end

    return name, emote
end

local function persist()
    local encoded = json.encode(KoraECreatedEmotes, { indent = true, sort_keys = true })
    return SaveResourceFile(RESOURCE, CREATED_FILE, encoded, -1)
end

RegisterNetEvent('kora_emotemenu:server:saveEmote', function(payload)
    local source = source

    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, Kora.lang('error.create_permission'))
    end
    if not saveCooldown.use(source) then return end

    local name, emote = buildEmote(payload)
    if not name then return notify(source, emote) end

    local editingName = type(payload) == 'table' and payload.editingName or nil
    if editingName ~= nil then
        editingName = text(editingName, NAME_PATTERN, 32)
        editingName = editingName and editingName:lower()
        if not editingName or not KoraECreatedEmotes[editingName] then
            return notify(source, Kora.lang('error.saved_emote_missing'))
        end
    end

    if KoraEEmotes[name] and name ~= editingName then
        return notify(source, Kora.lang('error.emote_name_exists', name))
    end

    local previous = editingName and KoraECreatedEmotes[editingName] or nil
    if editingName then KoraECreatedEmotes[editingName] = nil end
    KoraECreatedEmotes[name] = emote
    if not persist() then
        KoraECreatedEmotes[name] = nil
        if editingName then KoraECreatedEmotes[editingName] = previous end
        return notify(source, Kora.lang('error.emote_write_failed'))
    end

    if editingName and editingName ~= name then KoraEEmotes[editingName] = nil end
    KoraEEmotes[name] = emote
    if editingName and editingName ~= name then
        TriggerClientEvent('kora_emotemenu:client:removeEmotes', -1, { editingName })
    end
    TriggerClientEvent('kora_emotemenu:client:addEmotes', -1, { [name] = emote })
    TriggerClientEvent('kora_emotemenu:client:emoteSaved', source)
    notify(source, editingName and Kora.lang('success.emote_updated', name) or Kora.lang('success.emote_saved', name), 'success')
end)

RegisterNetEvent('kora_emotemenu:server:requestEmotesForEdit', function()
    local source = source
    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, Kora.lang('error.edit_permission'))
    end
    TriggerClientEvent('kora_emotemenu:client:creatorEmotes', source, KoraECreatedEmotes)
end)

RegisterNetEvent('kora_emotemenu:server:deleteCreatedEmote', function(rawName)
    local source = source
    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, Kora.lang('error.delete_permission'))
    end
    if not deleteCooldown.use(source) then return end

    local name = text(rawName, NAME_PATTERN, 32)
    if not name then return notify(source, Kora.lang('error.choose_saved_emote')) end
    name = name:lower()

    local previous = KoraECreatedEmotes[name]
    if not previous then return notify(source, Kora.lang('error.saved_emote_missing')) end

    KoraECreatedEmotes[name] = nil
    if not persist() then
        KoraECreatedEmotes[name] = previous
        return notify(source, Kora.lang('error.emote_delete_failed'))
    end

    KoraEEmotes[name] = nil
    TriggerClientEvent('kora_emotemenu:client:removeEmotes', -1, { name })
    TriggerClientEvent('kora_emotemenu:client:emoteDeleted', source, name)
    TriggerClientEvent('kora_emotemenu:client:creatorEmotes', source, KoraECreatedEmotes)
    notify(source, Kora.lang('success.emote_deleted', name), 'success')
end)

-- Clients don't read created.json themselves; they ask for the current set
-- when they load, which also covers emotes created since the server started.
RegisterNetEvent('kora_emotemenu:server:requestCreated', function()
    TriggerClientEvent('kora_emotemenu:client:addEmotes', source, KoraECreatedEmotes)
end)

AddEventHandler('playerDropped', function()
    saveCooldown.reset(source)
    deleteCooldown.reset(source)
end)
