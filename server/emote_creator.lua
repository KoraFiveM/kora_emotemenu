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
    Kora.notify.send(source, { title = 'Emote Maker', message = message, type = kind or 'error' })
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
    if type(payload) ~= 'table' then return nil, 'Invalid emote data.' end

    local name = text(payload.name, NAME_PATTERN, 32)
    if not name then return nil, 'Names may only use letters, digits, _ and -.' end
    name = name:lower()

    local label = text(payload.label, nil, 40)
    if not label then return nil, 'Enter a label (40 characters max).' end

    if not CREATOR_CATEGORIES[payload.category] or not Config.categories[payload.category] then
        return nil, 'Choose a valid category.'
    end

    local dict, clip = text(payload.dict, ASSET_PATTERN, 128), text(payload.clip, ASSET_PATTERN, 128)
    if not (dict and clip) then return nil, 'Enter a valid animation dictionary and clip.' end

    local flag = integer(payload.flag, 0, 65535)
    if not flag then return nil, 'The flag must be a whole number.' end

    local props = type(payload.props) == 'table' and payload.props or {}
    if #props > MAX_PROPS then return nil, ('At most %d props are supported.'):format(MAX_PROPS) end

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
        if not valid then return nil, ('Prop %d is invalid.'):format(index) end
        emote[PROP_SLOTS[index]] = valid
    end

    return name, emote
end

local function persist()
    local encoded = json.encode(QBECreatedEmotes, { indent = true, sort_keys = true })
    return SaveResourceFile(RESOURCE, CREATED_FILE, encoded, -1)
end

RegisterNetEvent('qbemotemenu:server:saveEmote', function(payload)
    local source = source

    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, 'You do not have permission to create emotes.')
    end
    if not saveCooldown.use(source) then return end

    local name, emote = buildEmote(payload)
    if not name then return notify(source, emote) end

    local editingName = type(payload) == 'table' and payload.editingName or nil
    if editingName ~= nil then
        editingName = text(editingName, NAME_PATTERN, 32)
        if not editingName then
            return notify(source, 'That saved emote could not be found. Refresh the editor and try again.')
        end
        editingName = editingName:lower()
        if not QBECreatedEmotes[editingName] then
            return notify(source, 'That saved emote could not be found. Refresh the editor and try again.')
        end
    end

    if QBEEmotes[name] and name ~= editingName then
        return notify(source, ('An emote named "%s" already exists.'):format(name))
    end

    local previous = editingName and QBECreatedEmotes[editingName] or nil
    if editingName then QBECreatedEmotes[editingName] = nil end
    QBECreatedEmotes[name] = emote
    if not persist() then
        QBECreatedEmotes[name] = nil
        if editingName then QBECreatedEmotes[editingName] = previous end
        return notify(source, 'The emote could not be written to disk.')
    end

    if editingName and editingName ~= name then QBEEmotes[editingName] = nil end
    QBEEmotes[name] = emote
    if editingName and editingName ~= name then
        TriggerClientEvent('qbemotemenu:client:removeEmotes', -1, { editingName })
    end
    TriggerClientEvent('qbemotemenu:client:addEmotes', -1, { [name] = emote })
    TriggerClientEvent('qbemotemenu:client:emoteSaved', source)
    notify(source, ('%s "%s".'):format(editingName and 'Updated' or 'Saved', name), 'success')
end)

RegisterNetEvent('qbemotemenu:server:requestEmotesForEdit', function()
    local source = source
    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, 'You do not have permission to edit emotes.')
    end
    TriggerClientEvent('qbemotemenu:client:creatorEmotes', source, QBECreatedEmotes)
end)

RegisterNetEvent('qbemotemenu:server:deleteCreatedEmote', function(rawName)
    local source = source
    if not IsPlayerAceAllowed(source, 'command') then
        return notify(source, 'You do not have permission to delete emotes.')
    end
    if not deleteCooldown.use(source) then return end

    local name = text(rawName, NAME_PATTERN, 32)
    if not name then return notify(source, 'Choose a valid saved emote.') end
    name = name:lower()

    local previous = QBECreatedEmotes[name]
    if not previous then return notify(source, 'That saved emote no longer exists.') end

    QBECreatedEmotes[name] = nil
    if not persist() then
        QBECreatedEmotes[name] = previous
        return notify(source, 'The emote could not be removed from disk.')
    end

    QBEEmotes[name] = nil
    TriggerClientEvent('qbemotemenu:client:removeEmotes', -1, { name })
    TriggerClientEvent('qbemotemenu:client:emoteDeleted', source, name)
    TriggerClientEvent('qbemotemenu:client:creatorEmotes', source, QBECreatedEmotes)
    notify(source, ('Deleted "%s".'):format(name), 'success')
end)

-- Clients don't read created.json themselves; they ask for the current set
-- when they load, which also covers emotes created since the server started.
RegisterNetEvent('qbemotemenu:server:requestCreated', function()
    TriggerClientEvent('qbemotemenu:client:addEmotes', source, QBECreatedEmotes)
end)

AddEventHandler('playerDropped', function()
    saveCooldown.reset(source)
    deleteCooldown.reset(source)
end)
