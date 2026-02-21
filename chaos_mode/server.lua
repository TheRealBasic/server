local chaosEnabled = Config.Enabled

local trollActions = {
    'launch_up',
    'spin_out',
    'ragdoll_drop',
    'ignite',
    'strip_weapon',
    'drain_armor',
    'blur_vision',
    'freeze_feet',
    'drunk_walk',
    'fake_explosion',
    'seat_shuffle',
    'stall_engine',
    'burst_tires',
    'teleport_back',
    'reverse_controls'
}

local function validateConfig()
    local hasErrors = false

    local function configError(field, message)
        hasErrors = true
        print(('[chaos_mode] Invalid Config.%s: %s'):format(field, message))
    end

    if type(Config.MinIntervalMs) ~= 'number' or Config.MinIntervalMs <= 0 then
        configError('MinIntervalMs', 'must be a number greater than 0')
    end

    if type(Config.MaxIntervalMs) ~= 'number' or Config.MaxIntervalMs <= 0 then
        configError('MaxIntervalMs', 'must be a number greater than 0')
    end

    if type(Config.MinIntervalMs) == 'number' and type(Config.MaxIntervalMs) == 'number'
        and Config.MinIntervalMs > Config.MaxIntervalMs then
        configError('MinIntervalMs/MaxIntervalMs', 'MinIntervalMs must be less than or equal to MaxIntervalMs')
    end

    if type(Config.EventPool) ~= 'table' or #Config.EventPool == 0 then
        configError('EventPool', 'must be a non-empty array')
    end

    if type(Config.ComboEnabled) ~= 'boolean' then
        configError('ComboEnabled', 'must be a boolean')
    end

    if type(Config.ComboChance) ~= 'number' or Config.ComboChance < 0 or Config.ComboChance > 100 then
        configError('ComboChance', 'must be a number between 0 and 100')
    end

    if type(Config.WeatherTypes) ~= 'table' or #Config.WeatherTypes == 0 then
        configError('WeatherTypes', 'must be a non-empty array')
    end

    if type(Config.RandomObjectCount) ~= 'table' then
        configError('RandomObjectCount', 'must be a table with min and max numbers')
    else
        if type(Config.RandomObjectCount.min) ~= 'number' then
            configError('RandomObjectCount.min', 'must be a number')
        end

        if type(Config.RandomObjectCount.max) ~= 'number' then
            configError('RandomObjectCount.max', 'must be a number')
        end

        if type(Config.RandomObjectCount.min) == 'number' and type(Config.RandomObjectCount.max) == 'number'
            and Config.RandomObjectCount.min > Config.RandomObjectCount.max then
            configError('RandomObjectCount', 'min must be less than or equal to max')
        end
    end

    if type(Config.RandomObjectModels) ~= 'table' or #Config.RandomObjectModels == 0 then
        configError('RandomObjectModels', 'must be a non-empty array')
    end

    return not hasErrors
end

local function randomBetween(min, max)
    return math.random(min, max)
end

local function randomFrom(list)
    return list[randomBetween(1, #list)]
end

local function chooseEvent()
    return randomFrom(Config.EventPool)
end

local function getEventMeta(eventName)
    local compatibility = Config.EventCompatibility or {}
    return compatibility[eventName] or {}
end

local function eventsConflict(firstEvent, secondEvent)
    if firstEvent == secondEvent then
        return true
    end

    local firstMeta = getEventMeta(firstEvent)
    local secondMeta = getEventMeta(secondEvent)

    if firstMeta.blacklist and firstMeta.blacklist[secondEvent] then
        return true
    end

    if secondMeta.blacklist and secondMeta.blacklist[firstEvent] then
        return true
    end

    return false
end

local function chooseComboEvent()
    local primaryEvent = chooseEvent()
    local candidates = {}
    for _, eventName in ipairs(Config.EventPool) do
        if not eventsConflict(primaryEvent, eventName) then
            candidates[#candidates + 1] = eventName
        end
    end

    if #candidates == 0 then
        return { primaryEvent }
    end

    return { primaryEvent, randomFrom(candidates) }
end

local function createEventData()
    return {
        weather = randomFrom(Config.WeatherTypes),
        hostileDuration = Config.HostileNpcDurationMs,
        objectMin = Config.RandomObjectCount.min,
        objectMax = Config.RandomObjectCount.max,
        spawnRadius = Config.SpawnRadius,
        cleanupMs = Config.ObjectCleanupMs,
        models = Config.RandomObjectModels,
        eventCompatibility = Config.EventCompatibility
    }
end

local function triggerChaosEvent(eventNames)
    TriggerClientEvent('chaos_mode:runEvent', -1, eventNames, createEventData())
    print(('[chaos_mode] Triggered event(s): %s'):format(table.concat(eventNames, ', ')))
end

local function eventExists(eventName)
    for _, poolEventName in ipairs(Config.EventPool) do
        if poolEventName == eventName then
            return true
        end
    end
    return false
end

local function getLobbyPlayers()
    local players = {}
    for _, playerSrc in ipairs(GetPlayers()) do
        players[#players + 1] = {
            id = tonumber(playerSrc),
            name = GetPlayerName(playerSrc) or ('Player %s'):format(playerSrc)
        }
    end
    table.sort(players, function(a, b)
        return a.id < b.id
    end)
    return players
end

if not validateConfig() then
    chaosEnabled = false
    print('[chaos_mode] Chaos mode startup aborted due to invalid configuration.')
    return
end

CreateThread(function()
    math.randomseed(os.time())

    while true do
        if chaosEnabled then
            Wait(randomBetween(Config.MinIntervalMs, Config.MaxIntervalMs))
            if chaosEnabled then
                if Config.ComboEnabled and randomBetween(1, 100) <= Config.ComboChance then
                    triggerChaosEvent(chooseComboEvent())
                else
                    triggerChaosEvent({ chooseEvent() })
                end
            end
        else
            Wait(2000)
        end
    end
end)

RegisterNetEvent('chaos_mode:requestMenuData', function()
    local src = source
    TriggerClientEvent('chaos_mode:menuData', src, {
        events = Config.EventPool,
        players = getLobbyPlayers(),
        trollActions = trollActions
    })
end)

local function trollActionExists(actionName)
    for _, listedAction in ipairs(trollActions) do
        if listedAction == actionName then
            return true
        end
    end

    return false
end

RegisterNetEvent('chaos_mode:triggerSelectedTrollAction', function(payload)
    local src = source

    if type(payload) ~= 'table' then
        return
    end

    local actionName = payload.actionName
    local selectedPlayers = payload.players

    if type(actionName) ~= 'string' or not trollActionExists(actionName) then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Troll', 'Invalid trolling action selected.' }
        })
        return
    end

    if type(selectedPlayers) ~= 'table' or #selectedPlayers == 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Troll', 'Select at least one target player.' }
        })
        return
    end

    local online = {}
    for _, playerSrc in ipairs(GetPlayers()) do
        online[tonumber(playerSrc)] = true
    end

    local triggeredFor = 0
    for _, playerId in ipairs(selectedPlayers) do
        local numericPlayerId = tonumber(playerId)
        if numericPlayerId and online[numericPlayerId] then
            TriggerClientEvent('chaos_mode:runTrollAction', numericPlayerId, actionName)
            triggeredFor = triggeredFor + 1
        end
    end

    if triggeredFor == 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Troll', 'No valid target players online.' }
        })
        return
    end

    print(('[chaos_mode] %s used troll action "%s" on %d player(s)'):format(GetPlayerName(src) or src, actionName, triggeredFor))
end)

RegisterNetEvent('chaos_mode:triggerSelectedEvent', function(payload)
    local src = source

    if type(payload) ~= 'table' then
        return
    end

    local eventName = payload.eventName
    local targetType = payload.targetType
    local selectedPlayers = payload.players

    if type(eventName) ~= 'string' or not eventExists(eventName) then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Chaos', 'Invalid event selected.' }
        })
        return
    end

    if targetType == 'all' then
        TriggerClientEvent('chaos_mode:runEvent', -1, { eventName }, createEventData())
        print(('[chaos_mode] %s triggered event "%s" for all players'):format(GetPlayerName(src) or src, eventName))
        return
    end

    if targetType ~= 'specific' or type(selectedPlayers) ~= 'table' or #selectedPlayers == 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Chaos', 'Select at least one target player.' }
        })
        return
    end

    local online = {}
    for _, playerSrc in ipairs(GetPlayers()) do
        online[tonumber(playerSrc)] = true
    end

    local triggeredFor = 0
    for _, playerId in ipairs(selectedPlayers) do
        local numericPlayerId = tonumber(playerId)
        if numericPlayerId and online[numericPlayerId] then
            TriggerClientEvent('chaos_mode:runEvent', numericPlayerId, { eventName }, createEventData())
            triggeredFor = triggeredFor + 1
        end
    end

    if triggeredFor == 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Chaos', 'No valid target players online.' }
        })
        return
    end

    print(('[chaos_mode] %s triggered event "%s" for %d player(s)'):format(GetPlayerName(src) or src, eventName, triggeredFor))
end)

RegisterCommand(Config.Commands.Toggle, function(source)
    if source ~= 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^1Chaos', 'Only server console can toggle global chaos mode.' }
        })
        return
    end

    chaosEnabled = not chaosEnabled
    print(('[chaos_mode] Chaos mode is now %s'):format(chaosEnabled and 'ENABLED' or 'DISABLED'))
end, true)

RegisterCommand(Config.Commands.TriggerNow, function(source)
    if source ~= 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^1Chaos', 'Only server console can trigger global chaos events.' }
        })
        return
    end

    if Config.ComboEnabled and randomBetween(1, 100) <= Config.ComboChance then
        triggerChaosEvent(chooseComboEvent())
    else
        triggerChaosEvent({ chooseEvent() })
    end
end, true)
