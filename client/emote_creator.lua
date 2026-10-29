local APP_ID = 'qbemotemenu:emote_creator'
local MAX_PROPS = 2
local STEP = 0.1
local CREATOR_CATEGORIES = { 'general', 'dance', 'props' }

local ACTION = {
    animation = 'emote_creator:animation',
    play = 'emote_creator:play',
    stop = 'emote_creator:stop',
    freecam = 'emote_creator:freecam',
    add = 'emote_creator:add',
    apply = 'emote_creator:apply',
    remove = 'emote_creator:remove',
    save = 'emote_creator:save',
}

local function newEditor()
    return { name = '', label = '', category = 'general', dict = '', clip = '', flag = 49, props = {} }
end

local editor = newEditor()
local preview = { playing = false, props = {} }
local freecam = { active = false, cam = nil, pos = vec3(0.0, 0.0, 0.0), yaw = 0.0, pitch = 0.0 }

local buildNavigation

local function notify(message, kind)
    QB.notify.send({ title = 'Emote Maker', message = message, type = kind or 'info' })
end

local function num(value, fallback)
    return tonumber(value) or fallback
end

local function int(value, fallback)
    return math.floor(num(value, fallback))
end

local function refresh()
    QB.nui.updateApp(APP_ID, { navigation = buildNavigation() })
end

------------------------------------------------------------------------
-- Freecam
------------------------------------------------------------------------

local function destroyCam()
    if not freecam.cam then return end
    RenderScriptCams(false, true, 300, true, true)
    DestroyCam(freecam.cam, false)
    freecam.cam = nil
end

local function openMenu()
    CreateThread(function()
        refresh()
        local result = QB.nui.openApp(APP_ID)
        local reason = type(result) == 'table' and result.reason or nil
        if reason ~= 'action' and reason ~= 'superseded' then destroyCam() end
    end)
end

local function stopFreecam(reopen, release)
    freecam.active = false
    if release then destroyCam() end
    if reopen then openMenu() end
end

local function showFreecamHelp()
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(
        '~INPUT_MOVE_UP_ONLY~~INPUT_MOVE_LEFT_ONLY~~INPUT_MOVE_DOWN_ONLY~~INPUT_MOVE_RIGHT_ONLY~ Move  ' ..
        '~INPUT_LOOK_LR~ Look  ~INPUT_COVER~ Up  ~INPUT_PICKUP~ Down  ' ..
        '~INPUT_SPRINT~ Fast  ~INPUT_DUCK~ Slow  ~INPUT_FRONTEND_ACCEPT~ Back to menu'
    )
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function freecamLoop()
    local up = vec3(0.0, 0.0, 1.0)

    while freecam.active do
        if not DoesEntityExist(PlayerPedId()) or not freecam.cam then
            stopFreecam(true, true)
            break
        end

        DisableAllControlActions(0)

        freecam.yaw = freecam.yaw - GetDisabledControlNormal(0, 1) * 8.0
        freecam.pitch = math.max(-89.0, math.min(89.0, freecam.pitch - GetDisabledControlNormal(0, 2) * 8.0))

        local yaw, pitch = math.rad(freecam.yaw), math.rad(freecam.pitch)
        local forward = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
        local right = vec3(math.cos(yaw), math.sin(yaw), 0.0)

        local speed = 3.0
        if IsDisabledControlPressed(0, 21) then speed = speed * 4.0 end  -- Shift
        if IsDisabledControlPressed(0, 36) then speed = speed * 0.25 end -- Ctrl

        local move = vec3(0.0, 0.0, 0.0)
        if IsDisabledControlPressed(0, 32) then move = move + forward end -- W
        if IsDisabledControlPressed(0, 33) then move = move - forward end -- S
        if IsDisabledControlPressed(0, 35) then move = move + right end   -- D
        if IsDisabledControlPressed(0, 34) then move = move - right end   -- A
        if IsDisabledControlPressed(0, 44) then move = move + up end      -- Q
        if IsDisabledControlPressed(0, 38) then move = move - up end      -- E

        freecam.pos = freecam.pos + move * (speed * GetFrameTime())
        SetCamCoord(freecam.cam, freecam.pos.x, freecam.pos.y, freecam.pos.z)
        SetCamRot(freecam.cam, freecam.pitch, 0.0, freecam.yaw, 2)
        showFreecamHelp()

        if IsDisabledControlJustPressed(0, 191) then -- Enter: hold this view, reopen menu
            stopFreecam(true, false)
            break
        end

        Wait(0)
    end
end

local function startFreecam()
    local ped = PlayerPedId()
    if freecam.active or not DoesEntityExist(ped) then return end

    if not freecam.cam then
        local heading = GetEntityHeading(ped)
        local rad = math.rad(heading)
        local coords = GetEntityCoords(ped)

        freecam.pos = vec3(coords.x - math.sin(rad) * 3.0, coords.y + math.cos(rad) * 3.0, coords.z + 0.8)
        freecam.yaw = heading + 180.0
        freecam.pitch = -8.0

        freecam.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(freecam.cam, freecam.pos.x, freecam.pos.y, freecam.pos.z)
        SetCamRot(freecam.cam, freecam.pitch, 0.0, freecam.yaw, 2)
        SetCamActive(freecam.cam, true)
        RenderScriptCams(true, true, 300, true, true)
    end

    freecam.active = true
    CreateThread(freecamLoop)
end

------------------------------------------------------------------------
-- Props and preview
------------------------------------------------------------------------

local function makeProp()
    return {
        modelName = '',
        bone = 0,
        offset = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    }
end

local function vector(value)
    return { x = num(value and value.x, 0.0), y = num(value and value.y, 0.0), z = num(value and value.z, 0.0) }
end

local function deleteEntity(entity)
    if not DoesEntityExist(entity) then return end
    DetachEntity(entity, true, true)
    DeleteEntity(entity)
end

local function detachProp(index)
    local entity = preview.props[index]
    if not entity then return end
    deleteEntity(entity)
    preview.props[index] = nil
end

local function clearProps()
    for index in pairs(preview.props) do detachProp(index) end
end

local function stopPreview()
    clearProps()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then QB.anim.clear(ped, true) end
    preview.playing = false
end

local function attachProp(index)
    if not preview.playing then return true end

    detachProp(index)

    local config = editor.props[index]
    if not config or config.modelName == '' then return true end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return false end

    local model = joaat(config.modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        notify(('Invalid prop model: %s'):format(config.modelName), 'error')
        return false
    end

    QB.stream.loadModel(model)

    local coords = GetEntityCoords(ped)
    local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(entity) then
        notify(('Could not create prop %d.'):format(index), 'error')
        return false
    end

    local o, r = config.offset, config.rotation
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, config.bone), o.x, o.y, o.z, r.x, r.y, r.z, true, true, false, true, 1, true)

    preview.props[index] = entity
    return true
end

local function playPreview()
    if editor.dict == '' or editor.clip == '' then
        notify('Enter an animation dictionary and clip first.', 'error')
        return false
    end

    stopPreview()

    local handle, err = QB.anim.play(PlayerPedId(), editor.dict, editor.clip, { flag = editor.flag })
    if not handle then
        notify(err or 'The animation could not be played.', 'error')
        return false
    end

    preview.playing = true

    for index = 1, #editor.props do
        if not attachProp(index) then
            stopPreview()
            return false
        end
    end

    notify('Preview playing.')
    return true
end

local function reattachAll()
    if not preview.playing then return end
    clearProps()
    for index = 1, #editor.props do attachProp(index) end
end

------------------------------------------------------------------------
-- Saving
------------------------------------------------------------------------

local function buildPayload()
    local props = {}
    for _, prop in ipairs(editor.props) do
        if prop.modelName ~= '' then
            props[#props + 1] = { model = prop.modelName, bone = prop.bone, offset = prop.offset, rotation = prop.rotation }
        end
    end

    return {
        name = editor.name,
        label = editor.label,
        category = editor.category,
        dict = editor.dict,
        clip = editor.clip,
        flag = editor.flag,
        props = props,
    }
end

local REQUIRED_FIELDS = {
    { 'name', 'a name' },
    { 'label', 'a label' },
    { 'dict', 'an animation dictionary' },
    { 'clip', 'an animation clip' },
}

local function saveEmote()
    for _, required in ipairs(REQUIRED_FIELDS) do
        if editor[required[1]] == '' then
            return { notice = { tone = 'error', message = ('Enter %s first.'):format(required[2]) } }
        end
    end

    TriggerServerEvent('qbemotemenu:server:saveEmote', buildPayload())
end

------------------------------------------------------------------------
-- AppShell
------------------------------------------------------------------------

local function categoryOptions()
    local options = {}
    for _, key in ipairs(CREATOR_CATEGORIES) do
        local category = Config.categories[key]
        if category then options[#options + 1] = { value = key, label = category.label } end
    end
    return options
end

local function propFields(prop)
    local function field(id, label, value, extra)
        local f = { id = id, label = label, type = 'number', step = STEP, value = value }
        for k, v in pairs(extra or {}) do f[k] = v end
        return f
    end

    return {
        { id = 'modelName', label = 'Model', type = 'text', value = prop.modelName },
        field('bone', 'Bone', prop.bone, { step = 1, wholeNumber = true }),
        field('offsetX', 'Offset X', prop.offset.x),
        field('offsetY', 'Offset Y', prop.offset.y),
        field('offsetZ', 'Offset Z', prop.offset.z),
        field('rotationX', 'Rotation X', prop.rotation.x),
        field('rotationY', 'Rotation Y', prop.rotation.y),
        field('rotationZ', 'Rotation Z', prop.rotation.z),
    }
end

local function animationBlock()
    return {
        type = 'list',
        id = 'animation',
        label = 'Animation',
        items = { {
            id = 'animation_editor',
            label = editor.label ~= '' and editor.label or 'Animation Settings',
            description = ('Name: %s | Dict: %s | Clip: %s | Flag: %d'):format(
                editor.name ~= '' and editor.name or 'Unnamed',
                editor.dict ~= '' and editor.dict or 'Not set',
                editor.clip ~= '' and editor.clip or 'Not set',
                editor.flag
            ),
            action = {
                id = ACTION.animation,
                label = 'Apply',
                fields = {
                    { id = 'name', label = 'Name', type = 'text', value = editor.name, required = true },
                    { id = 'label', label = 'Label', type = 'text', value = editor.label, required = true },
                    { id = 'category', label = 'Category', type = 'select', value = editor.category, options = categoryOptions(), required = true },
                    { id = 'dict', label = 'Dict', type = 'text', value = editor.dict, required = true },
                    { id = 'clip', label = 'Clip', type = 'text', value = editor.clip, required = true },
                    { id = 'flag', label = 'Flag', type = 'number', value = editor.flag },
                },
            },
        } },
    }
end

local function previewBlock()
    return {
        type = 'list',
        id = 'controls',
        label = 'Preview',
        items = {
            { id = 'play', label = preview.playing and 'Restart Preview' or 'Play Preview', action = { id = ACTION.play, label = 'Play' } },
            { id = 'stop', label = 'Stop Preview', action = { id = ACTION.stop, label = 'Stop' } },
            {
                id = 'freecam',
                label = 'Freecam',
                description = 'Hides this menu so you can fly around your ped. Enter brings the menu back and holds the camera until you close it.',
                action = { id = ACTION.freecam, label = 'Start', closeBeforeAction = true },
            },
        },
    }
end

local function propBlock(index, prop)
    return {
        type = 'list',
        id = 'prop' .. index,
        label = 'Prop ' .. index,
        items = {
            {
                id = 'prop_editor_' .. index,
                label = prop.modelName ~= '' and prop.modelName or 'Configure Prop',
                description = ('Bone: %d | Offset: %.3f, %.3f, %.3f | Rotation: %.1f, %.1f, %.1f'):format(
                    prop.bone,
                    prop.offset.x, prop.offset.y, prop.offset.z,
                    prop.rotation.x, prop.rotation.y, prop.rotation.z
                ),
                action = { id = ACTION.apply .. ':' .. index, label = 'Apply', fields = propFields(prop) },
            },
            { id = 'remove_prop_' .. index, label = 'Remove Prop', action = { id = ACTION.remove .. ':' .. index, label = 'Remove' } },
        },
    }
end

function buildNavigation()
    local blocks = { animationBlock(), previewBlock() }

    for index, prop in ipairs(editor.props) do
        blocks[#blocks + 1] = propBlock(index, prop)
    end

    if #editor.props < MAX_PROPS then
        blocks[#blocks + 1] = {
            type = 'list',
            id = 'add_prop',
            items = { {
                id = 'add_prop_item',
                label = 'Add Prop',
                description = ('%d/%d props configured'):format(#editor.props, MAX_PROPS),
                action = { id = ACTION.add, label = 'Add' },
            } },
        }
    end

    blocks[#blocks + 1] = {
        type = 'list',
        id = 'export',
        label = 'Output',
        items = { {
            id = 'save',
            label = 'Save Emote',
            description = 'Adds this emote to the menu for everyone. Requires admin permission.',
            action = { id = ACTION.save, label = 'Save', confirm = 'Save this emote to the server?' },
        } },
    }

    return { { id = 'maker', label = 'Emote Maker', icon = 'WandSparkles', content = { title = 'Emote Maker', blocks = blocks } } }
end

------------------------------------------------------------------------
-- Actions
------------------------------------------------------------------------

local function readAnimation(context)
    local value = context.value or {}
    editor.name = tostring(value.name or editor.name):lower()
    editor.label = tostring(value.label or editor.label)
    editor.category = tostring(value.category or editor.category)
    editor.dict = tostring(value.dict or editor.dict)
    editor.clip = tostring(value.clip or editor.clip)
    editor.flag = int(value.flag, editor.flag)
end

local function readProp(context, index)
    local prop, value = editor.props[index], context.value or {}
    if not prop then return end

    prop.modelName = tostring(value.modelName or prop.modelName)
    prop.bone = int(value.bone, prop.bone)
    prop.offset = { x = num(value.offsetX, prop.offset.x), y = num(value.offsetY, prop.offset.y), z = num(value.offsetZ, prop.offset.z) }
    prop.rotation = { x = num(value.rotationX, prop.rotation.x), y = num(value.rotationY, prop.rotation.y), z = num(value.rotationZ, prop.rotation.z) }
end

-- Actions that need no argument beyond the action context.
local handlers = {
    [ACTION.animation] = function(context)
        readAnimation(context)
        if preview.playing then playPreview() end
        refresh()
    end,
    [ACTION.play] = function()
        playPreview()
        refresh()
    end,
    [ACTION.stop] = function()
        stopPreview()
        refresh()
    end,
    -- The shell is already closed (closeBeforeAction). Editor state lives in
    -- `editor`/`preview`, so reopening rebuilds the menu with your data.
    [ACTION.freecam] = startFreecam,
    [ACTION.add] = function()
        if #editor.props >= MAX_PROPS then return end
        editor.props[#editor.props + 1] = makeProp()
        refresh()
    end,
    [ACTION.save] = saveEmote,
}

-- Actions that carry a prop index as ':<n>'.
local indexedHandlers = {
    [ACTION.apply] = function(index, context)
        readProp(context, index)
        attachProp(index)
        refresh()
    end,
    [ACTION.remove] = function(index)
        if not editor.props[index] then return end
        table.remove(editor.props, index)
        reattachAll() -- indexes shifted, so rebuild whatever is still attached
        refresh()
    end,
}

QB.nui.registerApp({
    id = APP_ID,
    title = 'Emote Maker',
    description = 'Create and preview emotes with up to two props.',
    icon = 'WandSparkles',
    layout = 'compact',
    width = 620,
    height = 760,
    placement = 'right',
    footer = 'Press Escape to close',
    navigation = buildNavigation(),

    onAction = function(actionId, context)
        local handler = handlers[actionId]
        if handler then return handler(context) end

        local base, index = actionId:match('^(.+):(%d+)$')
        handler = indexedHandlers[base]
        if handler then return handler(tonumber(index), context) end
    end,
})

RegisterNetEvent('qbemotemenu:client:openEmoteCreator', function()
    if source ~= 65535 or freecam.active then return end
    openMenu()
end)

RegisterNetEvent('qbemotemenu:client:emoteSaved', function()
    if source ~= 65535 then return end
    stopPreview()
    editor = newEditor()
    refresh()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    freecam.active = false
    destroyCam()
    stopPreview()
end)
