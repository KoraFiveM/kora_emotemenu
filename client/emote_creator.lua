local MAX_PROPS = 2
local DEFAULT_STEP = 0.1
local CREATOR_CATEGORIES = { 'general', 'dance', 'props' }

local function uiStrings()
    local keys = {
        'eyebrow', 'editing', 'title', 'new_emote', 'edit_saved', 'close', 'preview_playing', 'preview_ready',
        'freecam', 'freecam_back', 'freecam_controls', 'stop_preview', 'play_preview', 'animation_eyebrow', 'animation_details', 'emote_name',
        'emote_name_example', 'display_label', 'display_label_example', 'characters', 'animation_dictionary',
        'animation_clip', 'category', 'animation_flag', 'attachments_eyebrow', 'props', 'add_prop', 'no_props',
        'add_object', 'prop', 'model_name_hint', 'remove', 'object_model', 'object_model_hint', 'ped_bone_id',
        'bone_example', 'adjustment_amount', 'adjustment_hint', 'offset', 'position_relative', 'rotation',
        'angle_axes', 'preview_changes', 'apply_model', 'close_preview_hint', 'save_changes', 'save_emote',
        'saved_emotes', 'edit_emote', 'search_saved', 'delete', 'loading_saved', 'no_saved', 'no_search_match',
        'remove_saved', 'delete_confirm', 'delete_description', 'delete_emote', 'cancel', 'decrease', 'increase',
        'category_general', 'category_dance', 'category_props',
    }
    local result = {}
    for _, key in ipairs(keys) do result[key] = Kora.lang('maker.' .. key) end
    return result
end

local function categoryLabels()
    return {
        general = Kora.lang('maker.category_general'),
        dance = Kora.lang('maker.category_dance'),
        props = Kora.lang('maker.category_props'),
    }
end

local function newEditor()
    return { name = '', label = '', category = 'general', dict = '', clip = '', flag = 49, step = DEFAULT_STEP, props = {} }
end

local editor = newEditor()
local availableEmotes = {}
local preview = { playing = false, props = {}, models = {} }
local freecam = { active = false, cam = nil, pos = vec3(0.0, 0.0, 0.0), yaw = 0.0, pitch = 0.0 }

local makerCfg = Config.emoteMaker or {}
-- Bag read by UIs that should not open while the emote maker camera is up (documented in config.lua).
local UI_BLOCK_KEY = 'koraUiBlocked'
local FRONTEND_PAUSE, FRONTEND_PAUSE_ALT = 199, 200

local function exitControls()
    local list = makerCfg.exitControls
    if type(list) ~= 'table' or #list == 0 then list = { 191 } end
    return list
end

local function setUiBlocked(blocked)
    if makerCfg.blockUi == false then return end
    LocalPlayer.state:set(UI_BLOCK_KEY, blocked and true or nil, false)
end

local function notify(message, kind)
    Kora.notify.send({ title = Kora.lang('title.emote_maker'), message = message, type = kind or 'info' })
end

local function num(value, fallback)
    return tonumber(value) or fallback
end

local function int(value, fallback)
    return math.floor(num(value, fallback))
end

local function destroyCam()
    if not freecam.cam then return end
    RenderScriptCams(false, true, 300, true, true)
    DestroyCam(freecam.cam, false)
    freecam.cam = nil
end

local function openMenu()
    local ok, playerPrimary = pcall(function()
        return exports.kora_theme:getPlayerTheme()
    end)
    local colorOk, defaultPrimary = pcall(function()
        return exports.kora_theme:getPrimaryColor()
    end)
    local primary = ok and playerPrimary or nil
    if type(primary) ~= 'string' or primary == '' then primary = colorOk and defaultPrimary or '#95FF00' end

    local maxLabel = tonumber(makerCfg.maxLabelLength)
    SendNUIMessage({
        action = 'open', editor = editor, categories = CREATOR_CATEGORIES, categoryLabels = categoryLabels(), strings = uiStrings(), primary = primary,
        maxLabelLength = maxLabel and maxLabel > 0 and math.floor(maxLabel) or nil,
    })
    SetNuiFocus(true, true)
end

AddEventHandler('kora_theme:playerThemeChanged', function()
    local ok, primary = pcall(function()
        return exports.kora_theme:getPlayerTheme() or exports.kora_theme:getPrimaryColor()
    end)
    if ok and type(primary) == 'string' then SendNUIMessage({ action = 'theme', primary = primary }) end
end)

local function stopFreecam(reopen, release)
    freecam.active = false
    setUiBlocked(false)
    if release then destroyCam() end
    if reopen then openMenu() end
end

-- A 'STRING' substring is capped at 99 characters, which cut the help off after "W A S D Move".
-- A registered text entry has no such cap, so the full help is registered once per freecam start.
local HELP_ENTRY = 'KORA_EMOTE_MAKER_FREECAM'

local function registerFreecamHelp()
    local hint = makerCfg.hint or {}
    AddTextEntry(HELP_ENTRY,
        (hint.exit or Kora.lang('maker.freecam_back')) .. '~n~' ..
        Kora.lang('maker.freecam_controls')
    )
end

local function showFreecamHelp()
    BeginTextCommandDisplayHelp(HELP_ENTRY)
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
        DisableControlAction(0, FRONTEND_PAUSE, true)
        DisableControlAction(0, FRONTEND_PAUSE_ALT, true)

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

        for _, control in ipairs(exitControls()) do
            if IsDisabledControlJustPressed(0, control) then -- hold this view, reopen menu
                stopFreecam(true, false)
                return
            end
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
    setUiBlocked(true)
    registerFreecamHelp()
    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)
    CreateThread(freecamLoop)
end

local function makeProp()
    return {
        modelName = '',
        bone = 0,
        offset = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    }
end

local function deleteEntity(entity)
    if not DoesEntityExist(entity) then return end
    DetachEntity(entity, true, true)
    DeleteEntity(entity)
end

local function detachProp(index)
    local entity = preview.props[index]
    if entity then deleteEntity(entity) end
    preview.props[index] = nil
    preview.models[index] = nil
end

local function clearProps()
    for index in pairs(preview.props) do detachProp(index) end
end

local function stopPreview()
    clearProps()
    local ped = PlayerPedId()
    if preview.playing and DoesEntityExist(ped) then Kora.anim.clear(ped, true) end
    preview.playing = false
end

local function attachProp(index)
    local config = editor.props[index]
    if not config or config.modelName == '' then
        detachProp(index)
        return true
    end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return false end

    local current = preview.props[index]
    if current and DoesEntityExist(current) and preview.models[index] == config.modelName then
        local o, r = config.offset, config.rotation
        AttachEntityToEntity(current, ped, GetPedBoneIndex(ped, config.bone), o.x, o.y, o.z, r.x, r.y, r.z, true, true, false, true, 1, true)
        return true
    end

    local model = joaat(config.modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        notify(Kora.lang('error.invalid_prop_model', config.modelName), 'error')
        return false
    end

    detachProp(index)
    Kora.stream.loadModel(model)

    local coords = GetEntityCoords(ped)
    -- Creator previews are local-only, like the props used by normal emotes.
    -- Keeping them non-networked makes cleanup deterministic when the app closes.
    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(entity) then
        notify(Kora.lang('error.preview_prop_create_failed', index), 'error')
        return false
    end

    local o, r = config.offset, config.rotation
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, config.bone), o.x, o.y, o.z, r.x, r.y, r.z, true, true, false, true, 1, true)

    preview.props[index] = entity
    preview.models[index] = config.modelName
    return true
end

local function playPreview()
    if editor.dict == '' or editor.clip == '' then
        notify(Kora.lang('error.enter_animation_first'), 'error')
        return false
    end

    stopPreview()

    local handle, err = Kora.anim.play(PlayerPedId(), editor.dict, editor.clip, { flag = editor.flag })
    if not handle then
        notify(err or Kora.lang('error.animation_play_failed'), 'error')
        return false
    end

    preview.playing = true

    for index = 1, #editor.props do
        if not attachProp(index) then
            stopPreview()
            return false
        end
    end

    notify(Kora.lang('success.preview_playing'))
    return true
end

local function reattachAll()
    clearProps()
    for index = 1, #editor.props do attachProp(index) end
end

local function buildPayload()
    local props = {}
    for _, prop in ipairs(editor.props) do
        if prop.modelName ~= '' then
            props[#props + 1] = { model = prop.modelName, bone = prop.bone, offset = prop.offset, rotation = prop.rotation }
        end
    end

    return {
        name = editor.name,
        editingName = editor.editingName,
        label = editor.label,
        category = editor.category,
        dict = editor.dict,
        clip = editor.clip,
        flag = editor.flag,
        props = props,
    }
end

local REQUIRED_FIELDS = {
    { 'name', 'error.enter_name_first' },
    { 'label', 'error.enter_label_first' },
    { 'dict', 'error.enter_dictionary_first' },
    { 'clip', 'error.enter_clip_first' },
}

local function pushState(action)
    SendNUIMessage({ action = action or 'state', editor = editor, categories = CREATOR_CATEGORIES, categoryLabels = categoryLabels(), strings = uiStrings(), playing = preview.playing })
end

local function readUiState(data)
    if type(data) ~= 'table' then return end
    local previousModels = {}
    for i, prop in ipairs(editor.props) do previousModels[i] = prop.modelName end

    for _, key in ipairs({ 'name', 'label', 'category', 'dict', 'clip' }) do
        if data[key] ~= nil then editor[key] = tostring(data[key]) end
    end
    editor.name = editor.name:lower()
    local maxLabel = tonumber(makerCfg.maxLabelLength)
    if maxLabel and maxLabel > 0 then editor.label = editor.label:sub(1, math.floor(maxLabel)) end
    if type(data.editingName) == 'string' then editor.editingName = data.editingName end
    editor.flag = int(data.flag, editor.flag)
    local step = tonumber(data.step)
    if step == 0.01 or step == 0.1 or step == 1.0 or step == 10.0 then editor.step = step end

    if type(data.props) == 'table' then
        editor.props = {}
        for i = 1, math.min(#data.props, MAX_PROPS) do
            local value = data.props[i]
            local prop = makeProp()
            prop.modelName = tostring(value.modelName or '')
            prop.bone = int(value.bone, 0)
            prop.offset = {
                x = num(value.offset and value.offset.x, 0.0),
                y = num(value.offset and value.offset.y, 0.0),
                z = num(value.offset and value.offset.z, 0.0),
            }
            prop.rotation = {
                x = num(value.rotation and value.rotation.x, 0.0),
                y = num(value.rotation and value.rotation.y, 0.0),
                z = num(value.rotation and value.rotation.z, 0.0),
            }
            editor.props[i] = prop
        end
    end

    for i, prop in ipairs(editor.props) do
        if previousModels[i] == prop.modelName then attachProp(i) end
    end
end

RegisterNUICallback('creator:change', function(data, cb)
    readUiState(data)
    cb({ ok = true })
end)

RegisterNUICallback('creator:action', function(data, cb)
    local action = type(data) == 'table' and data.action or nil
    if action == 'play' then
        playPreview()
    elseif action == 'stop' then
        stopPreview()
    elseif action == 'new' then
        stopPreview()
        editor = newEditor()
    elseif action == 'add' and #editor.props < MAX_PROPS then
        editor.props[#editor.props + 1] = makeProp()
    elseif action == 'remove' then
        local index = tonumber(data.index)
        if index and editor.props[index] then
            detachProp(index)
            table.remove(editor.props, index)
            reattachAll()
        end
    elseif action == 'apply' then
        local index = tonumber(data.index)
        if index then attachProp(index) end
    elseif action == 'freecam' then
        startFreecam()
    elseif action == 'load-list' then
        TriggerServerEvent('kora_emotemenu:server:requestEmotesForEdit')
    elseif action == 'delete' and type(data.name) == 'string' then
        TriggerServerEvent('kora_emotemenu:server:deleteCreatedEmote', data.name)
    elseif action == 'load' and type(data.name) == 'string' then
        local emote = availableEmotes[data.name]
        if emote then
            stopPreview()
            local props = {}
            for _, slot in ipairs({ 'prop', 'proptwo' }) do
                local savedProp = emote[slot]
                if type(savedProp) == 'table' then
                    props[#props + 1] = {
                        modelName = savedProp.model,
                        bone = savedProp.bone,
                        offset = savedProp.offset,
                        rotation = savedProp.rotation,
                    }
                end
            end
            editor = {
                name = data.name,
                editingName = data.name,
                label = emote.label,
                category = emote.category,
                dict = emote.dict,
                clip = emote.clip,
                flag = emote.flag,
                step = editor.step,
                props = props,
            }
            SendNUIMessage({ action = 'loaded', editor = editor })
        end
    elseif action == 'save' then
        for _, required in ipairs(REQUIRED_FIELDS) do
            if editor[required[1]] == '' then
                notify(Kora.lang(required[2]), 'error')
                cb({ ok = false })
                return
            end
        end
        TriggerServerEvent('kora_emotemenu:server:saveEmote', buildPayload())
    end
    pushState()
    cb({ ok = true })
end)

RegisterNetEvent('kora_emotemenu:client:creatorEmotes', function(created)
    if source ~= 65535 or type(created) ~= 'table' then return end
    availableEmotes = created
    local list = {}
    for name, emote in pairs(created) do
        list[#list + 1] = { name = name, label = emote.label or name, category = emote.category or 'general' }
    end
    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    SendNUIMessage({ action = 'savedEmotes', emotes = list })
end)

RegisterNetEvent('kora_emotemenu:client:emoteDeleted', function(name)
    if source ~= 65535 or type(name) ~= 'string' then return end
    availableEmotes[name] = nil
    if editor.editingName == name then
        stopPreview()
        editor = newEditor()
        SendNUIMessage({ action = 'resetDeletedEditor', editor = editor })
    end
end)

RegisterNUICallback('creator:close', function(_, cb)
    SetNuiFocus(false, false)
    if not freecam.active then
        stopPreview()
        destroyCam()
    end
    cb({ ok = true })
end)

RegisterNetEvent('kora_emotemenu:client:openEmoteCreator', function()
    if source ~= 65535 then return end
    -- Running the command again while flying the camera is another way back to the menu.
    if freecam.active then
        stopFreecam(true, false)
        return
    end
    openMenu()
end)

RegisterNetEvent('kora_emotemenu:client:emoteSaved', function()
    if source ~= 65535 then return end
    stopPreview()
    editor = newEditor()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    freecam.active = false
    setUiBlocked(false)
    destroyCam()
    stopPreview()
end)
