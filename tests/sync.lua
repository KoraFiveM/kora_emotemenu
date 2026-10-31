-- Run from this resource: lua tests/sync.lua [server/main.lua]
-- kora_lib and native boundaries are inert; these players are nearby and available.
local serverPath = arg[1] or 'server/main.lua'
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, ('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)))
end

local function host()
    local events, sent, notices, timers = {}, {}, {}, {}
    local now = 1000
    local env = {}
    for name, value in pairs(_G) do env[name] = value end
    env.Kora = {
        util = { isInteger = function(n) return type(n) == 'number' and n % 1 == 0 end },
        world = { resolveNearbyPlayer = function() return 100, 0 end },
        timers = { cooldown = function() return { use = function() return true end, reset = function() end } end },
        notify = { send = function(src, payload) notices[#notices + 1] = { target = src, payload = payload } end },
    }
    env.GetGameTimer = function() return now end
    env.IsDuplicityVersion = function() return true end
    env.GetCurrentResourceName = function() return 'kora_emotemenu' end
    env.LoadResourceFile = function() return '{}' end
    env.json = { decode = function() return {} end }
    env.GetPlayerName = function(id) return 'Player ' .. id end
    env.RegisterCommand = function() end
    env.RegisterNetEvent = function(name, fn) events[name] = fn end
    env.AddEventHandler = function(name, fn) events[name] = fn end
    env.TriggerClientEvent = function(name, target, ...)
        sent[#sent + 1] = { name = name, target = target, args = table.pack(...) }
    end
    env.SetTimeout = function(delay, fn) timers[#timers + 1] = { delay = delay, fn = fn } end
    assert(loadfile('config.lua', 't', env))()
    assert(loadfile('shared/emotes.lua', 't', env))()
    assert(loadfile(serverPath, 't', env))()
    local h = { sent = sent, notices = notices, timers = timers, config = env.Config }
    function h.fire(name, src, ...)
        env.source = src
        return assert(events[name], name)(...)
    end
    function h.invite(src, target, emote) return h.fire('qbemotemenu:server:sync', src, target, emote or 'handshake') end
    function h.respond(src, id, accepted) return h.fire('qbemotemenu:server:respondSync', src, id, accepted) end
    function h.count(name)
        local n = 0
        for _, event in ipairs(sent) do if event.name == name then n = n + 1 end end
        return n
    end
    function h.advance(ms) now = now + ms end
    return h
end

local invitation = 'qbemotemenu:client:syncInvite'
local play = 'qbemotemenu:client:playSynced'
local cancel = 'qbemotemenu:client:cancelSynced'

-- A recipient cannot send another invite; the first pair remains cancellable.
for _, cleanup in ipairs({ 'qbemotemenu:server:cancelSync', 'playerDropped' }) do
    local h = host()
    equal(h.invite(1, '2', 'HANDSHAKE'), nil, 'sync event keeps nil return')
    equal(h.sent[1].args[1], 1, 'first invitation ID')
    equal(h.sent[1].args[2], 'Player 1', 'requester name')
    equal(h.sent[1].args[3], 'Handshake', 'catalogue label')
    h.invite(2, 3, 'hug')
    equal(h.count(invitation), 1, 'incoming recipient cannot become another sender')
    equal(h.notices[#h.notices].target, 2, 'overlap notice goes to requester')
    h.respond(3, 2, true)
    h.respond(2, 999, true)
    equal(h.count(play), 0, 'rejected or incorrect IDs cannot start pairing')
    equal(h.respond(2, '1', true), nil, 'response event keeps nil return')
    equal(h.count(play), 2, 'first invitation starts both sides')
    equal(h.sent[2].target, 1, 'sender receives play instruction')
    equal(h.sent[2].args[1], 'handshake', 'sender emote lowercased')
    equal(h.sent[2].args[2], 2, 'sender partner')
    equal(h.sent[3].target, 2, 'recipient receives play instruction')
    equal(h.sent[3].args[1], 'handshake_partner', 'recipient catalogue partner emote')
    equal(h.sent[3].args[2], 1, 'recipient partner')
    h.fire(cleanup, 2)
    equal(h.count(cancel), 1, 'cleanup cancels the reciprocal partner')
    equal(h.sent[#h.sent].target, 1, 'cleanup targets original sender')
    equal(h.sent[#h.sent].args[1], 2, 'cancel carries departing partner source')
    h.invite(3, 2, 'hug')
    equal(h.count(invitation), 2, 'cleanup releases recipient for another invite')
    equal(h.sent[#h.sent].args[1], 2, 'rejected overlap does not consume invitation ID')
end

-- An outgoing sender cannot simultaneously receive another invitation.
do
    local h = host()
    h.invite(1, 2)
    h.invite(3, 1, 'hug')
    equal(h.count(invitation), 1, 'outgoing sender cannot become another recipient')
    h.respond(2, 1, true)
    equal(h.count(play), 2, 'first pair still starts')
    h.fire('qbemotemenu:server:cancelSync', 1)
    equal(h.sent[#h.sent].target, 2, 'first pair still cancels reciprocally')
end

-- Decline, expiry and disconnect release pending state without erasing replacements.
do
    local h = host()
    h.invite(1, 2)
    h.respond(2, 1, false)
    h.invite(1, 3, 'hug')
    h.timers[1].fn()
    h.respond(3, 2, true)
    equal(h.count(play), 2, 'old timeout does not erase replacement after decline')
end
do
    local h = host()
    h.invite(1, 2)
    equal(h.timers[1].delay, h.config.syncInviteTTL, 'configured expiry retained')
    h.advance(h.config.syncInviteTTL + 1)
    h.respond(2, 1, true)
    equal(h.count(play), 0, 'expired invitation cannot start')
    h.invite(2, 3)
    equal(h.count(invitation), 2, 'expired recipient can send another invite')
end
for _, dropped in ipairs({ 1, 2 }) do
    local h = host()
    h.invite(1, 2)
    h.fire('playerDropped', dropped)
    h.invite(2, 3)
    equal(h.count(invitation), 2, 'pending disconnect releases both participants')
end

print(('qbemotemenu sync checks passed: %d assertions'):format(checks))
