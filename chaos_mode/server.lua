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
    'reverse_controls',
    'moonwalk',
    'random_trip',
    'invisible_brief',
    'camera_whiplash',
    'weapon_jam',
    'yeet_sideways',
    'clown_horn',
    'sudden_brake'
}


local funCommandUsage = {}

local function trimWhitespace(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function getFunCommandConfig()
    local cfg = Config.FunCommands
    if type(cfg) ~= 'table' or cfg.Enabled == false then
        return nil
    end

    return {
        cooldownMs = math.max(0, math.floor(tonumber(cfg.CooldownMs) or 0)),
        coinFlip = tostring(cfg.CoinFlip or 'coinflip'),
        roll = tostring(cfg.Roll or 'roll'),
        challenge = tostring(cfg.Challenge or 'challenge')
    }
end

local function canUseFunCommand(source, cooldownMs)
    if source == 0 or cooldownMs <= 0 then
        return true, 0
    end

    local now = GetGameTimer()
    local nextAllowedAt = funCommandUsage[source] or 0
    if now < nextAllowedAt then
        return false, nextAllowedAt - now
    end

    funCommandUsage[source] = now + cooldownMs
    return true, 0
end

local function sendFunMessage(source, message)
    if source == 0 then
        print('[fun] ' .. message)
        return
    end

    TriggerClientEvent('chat:addMessage', source, {
        args = { '^5Fun', message }
    })
end

local function broadcastFunMessage(source, message)
    if source == 0 then
        print('[fun] ' .. message)
        return
    end

    local name = GetPlayerName(source) or ('Player ' .. tostring(source))
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^5Fun', ('%s: %s'):format(name, message) }
    })
end

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

    if Config.EventRecentHistoryWindow ~= nil then
        if type(Config.EventRecentHistoryWindow) ~= 'number' then
            configError('EventRecentHistoryWindow', 'must be a number when set')
        elseif Config.EventRecentHistoryWindow < 0 then
            configError('EventRecentHistoryWindow', 'must be greater than or equal to 0')
        end
    end

    if Config.EventWeights ~= nil and type(Config.EventWeights) ~= 'table' then
        configError('EventWeights', 'must be a table when set')
    elseif type(Config.EventWeights) == 'table' then
        for eventName, eventWeight in pairs(Config.EventWeights) do
            if type(eventName) ~= 'string' then
                configError('EventWeights', 'keys must be event name strings')
                break
            end

            local numericWeight = tonumber(eventWeight)
            if not numericWeight or numericWeight < 0 then
                configError(('EventWeights.%s'):format(eventName), 'must be a number greater than or equal to 0')
            end
        end
    end


    if Config.FunCommands ~= nil and type(Config.FunCommands) ~= 'table' then
        configError('FunCommands', 'must be a table when set')
    elseif type(Config.FunCommands) == 'table' then
        if Config.FunCommands.CooldownMs ~= nil and (type(Config.FunCommands.CooldownMs) ~= 'number' or Config.FunCommands.CooldownMs < 0) then
            configError('FunCommands.CooldownMs', 'must be a number greater than or equal to 0')
        end
    end

    if Config.FunChallengeList ~= nil then
        if type(Config.FunChallengeList) ~= 'table' then
            configError('FunChallengeList', 'must be an array of strings when set')
        else
            for i, challenge in ipairs(Config.FunChallengeList) do
                if type(challenge) ~= 'string' or trimWhitespace(challenge) == '' then
                    configError(('FunChallengeList[%d]'):format(i), 'must be a non-empty string')
                    break
                end
            end
        end
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

local recentEventHistory = {}
local recentHistoryWindow = math.max(0, math.floor(tonumber(Config.EventRecentHistoryWindow) or 0))
local hudCurrentEvent = 'Waiting for next event'
local hudPreviousEvents = {}
local hudSecondsRemaining = math.max(1, math.floor((Config.MinIntervalMs or 30000) / 1000))

local function cloneArray(source)
    local copy = {}
    for i, value in ipairs(source) do
        copy[i] = value
    end
    return copy
end

local function pushHudHistory(entry)
    if type(entry) ~= 'string' or entry == '' or entry == 'Waiting for next event' then
        return
    end

    table.insert(hudPreviousEvents, 1, entry)
    while #hudPreviousEvents > 4 do
        table.remove(hudPreviousEvents)
    end
end

local function broadcastHudState(target)
    TriggerClientEvent('chaos_mode:updateHud', target or -1, {
        secondsRemaining = hudSecondsRemaining,
        currentEvent = hudCurrentEvent,
        history = cloneArray(hudPreviousEvents)
    })
end

local function getEventWeight(eventName)
    local configuredWeight = Config.EventWeights and Config.EventWeights[eventName]
    if configuredWeight == nil then
        return 1
    end

    local numericWeight = tonumber(configuredWeight)
    if not numericWeight or numericWeight < 0 then
        return 0
    end

    return numericWeight
end

local function countRecentOccurrences(eventName)
    local occurrences = 0
    for _, recentEventName in ipairs(recentEventHistory) do
        if recentEventName == eventName then
            occurrences = occurrences + 1
        end
    end
    return occurrences
end

local function historyToString()
    if #recentEventHistory == 0 then
        return 'none'
    end

    return table.concat(recentEventHistory, ' -> ')
end

local function recordEventHistory(eventNames)
    if recentHistoryWindow <= 0 then
        return
    end

    for _, eventName in ipairs(eventNames) do
        recentEventHistory[#recentEventHistory + 1] = eventName
        while #recentEventHistory > recentHistoryWindow do
            table.remove(recentEventHistory, 1)
        end
    end
end

local function pickWeightedEvent(candidates, contextLabel)
    local weightedCandidates = {}
    local totalWeight = 0

    for _, eventName in ipairs(candidates) do
        local baseWeight = getEventWeight(eventName)
        local recentOccurrences = countRecentOccurrences(eventName)
        local effectiveWeight = baseWeight

        if recentOccurrences > 0 then
            effectiveWeight = baseWeight / (recentOccurrences + 1)
        end

        if effectiveWeight > 0 then
            weightedCandidates[#weightedCandidates + 1] = {
                name = eventName,
                baseWeight = baseWeight,
                effectiveWeight = effectiveWeight,
                recentOccurrences = recentOccurrences
            }
            totalWeight = totalWeight + effectiveWeight
        end
    end

    if #weightedCandidates == 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local runningWeight = 0
    local chosen = weightedCandidates[#weightedCandidates]

    for _, candidate in ipairs(weightedCandidates) do
        runningWeight = runningWeight + candidate.effectiveWeight
        if roll <= runningWeight then
            chosen = candidate
            break
        end
    end

    print(('[chaos_mode] %s pick="%s" baseWeight=%.2f effectiveWeight=%.2f recentHits=%d history=[%s]'):format(
        contextLabel,
        chosen.name,
        chosen.baseWeight,
        chosen.effectiveWeight,
        chosen.recentOccurrences,
        historyToString()
    ))

    return chosen.name
end

local function chooseEvent(candidates, contextLabel)
    local eventCandidates = candidates or Config.EventPool
    local chosenEvent = pickWeightedEvent(eventCandidates, contextLabel or 'primary')
    if chosenEvent then
        return chosenEvent
    end

    local fallback = randomFrom(eventCandidates)
    print(('[chaos_mode] %s fallback pick="%s" (no positive weights) history=[%s]'):format(
        contextLabel or 'primary',
        fallback,
        historyToString()
    ))
    return fallback
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
    local primaryEvent = chooseEvent(Config.EventPool, 'combo-primary')
    local candidates = {}
    for _, eventName in ipairs(Config.EventPool) do
        if not eventsConflict(primaryEvent, eventName) then
            candidates[#candidates + 1] = eventName
        end
    end

    if #candidates == 0 then
        return { primaryEvent }
    end

    local secondaryEvent = chooseEvent(candidates, 'combo-secondary')
    return { primaryEvent, secondaryEvent }
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
    recordEventHistory(eventNames)
    TriggerClientEvent('chaos_mode:runEvent', -1, eventNames, createEventData())
    local newCurrentEvent = table.concat(eventNames, ' + ')
    pushHudHistory(hudCurrentEvent)
    hudCurrentEvent = newCurrentEvent
    print(('[chaos_mode] Triggered event(s): %s | history=[%s]'):format(table.concat(eventNames, ', '), historyToString()))
    broadcastHudState()
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
            local waitMs = randomBetween(Config.MinIntervalMs, Config.MaxIntervalMs)
            local elapsedMs = 0
            local announcedSeconds = -1

            while chaosEnabled and elapsedMs < waitMs do
                local remainingMs = waitMs - elapsedMs
                local remainingSeconds = math.max(0, math.ceil(remainingMs / 1000))
                if remainingSeconds ~= announcedSeconds then
                    hudSecondsRemaining = remainingSeconds
                    announcedSeconds = remainingSeconds
                    broadcastHudState()
                end

                local stepMs = math.min(1000, remainingMs)
                Wait(stepMs)
                elapsedMs = elapsedMs + stepMs
            end

            if chaosEnabled then
                hudSecondsRemaining = math.max(1, math.ceil(waitMs / 1000))
                if Config.ComboEnabled and randomBetween(1, 100) <= Config.ComboChance then
                    triggerChaosEvent(chooseComboEvent())
                else
                    triggerChaosEvent({ chooseEvent(Config.EventPool, 'single') })
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
        trollActions = trollActions,
        trollActionMeta = Config.TrollActionMeta or {}
    })
end)

RegisterNetEvent('chaos_mode:requestHudState', function()
    broadcastHudState(source)
end)


local function isVehicleRadioSyncEnabled()
    return Config.VehicleRadioSyncEnabled ~= false
end

RegisterNetEvent('chaos_mode:syncVehicleRadio', function(payload)
    if not isVehicleRadioSyncEnabled() then
        return
    end

    local src = source
    if type(payload) ~= 'table' then
        return
    end

    local vehicleNetId = tonumber(payload.vehicleNetId)
    local stationName = tostring(payload.stationName or '')

    if not vehicleNetId or vehicleNetId <= 0 then
        return
    end

    if stationName == '' then
        return
    end

    TriggerClientEvent('chaos_mode:applyVehicleRadioSync', -1, {
        source = src,
        vehicleNetId = vehicleNetId,
        stationName = stationName
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
        triggerChaosEvent({ chooseEvent(Config.EventPool, 'single') })
    end
end, true)


local funConfig = getFunCommandConfig()

if funConfig then
    RegisterCommand(funConfig.coinFlip, function(source)
        local canUse, remainingMs = canUseFunCommand(source, funConfig.cooldownMs)
        if not canUse then
            sendFunMessage(source, ('Slow down! Try again in %.1fs.'):format(remainingMs / 1000))
            return
        end

        local result = randomBetween(0, 1) == 0 and 'Heads' or 'Tails'
        broadcastFunMessage(source, ('flipped a coin: ^3%s^7!'):format(result))
    end, false)

    RegisterCommand(funConfig.roll, function(source, args)
        local canUse, remainingMs = canUseFunCommand(source, funConfig.cooldownMs)
        if not canUse then
            sendFunMessage(source, ('Slow down! Try again in %.1fs.'):format(remainingMs / 1000))
            return
        end

        local maxRoll = tonumber(args[1]) or 100
        maxRoll = math.floor(maxRoll)
        if maxRoll < 2 then
            sendFunMessage(source, 'Usage: /' .. funConfig.roll .. ' [max>=2]')
            return
        end

        if maxRoll > 1000 then
            maxRoll = 1000
        end

        local rolled = randomBetween(1, maxRoll)
        broadcastFunMessage(source, ('rolled ^2%d^7 (1-%d)!'):format(rolled, maxRoll))
    end, false)

    RegisterCommand(funConfig.challenge, function(source)
        local canUse, remainingMs = canUseFunCommand(source, funConfig.cooldownMs)
        if not canUse then
            sendFunMessage(source, ('Slow down! Try again in %.1fs.'):format(remainingMs / 1000))
            return
        end

        local challenges = Config.FunChallengeList or {}
        if #challenges == 0 then
            sendFunMessage(source, 'No challenges configured right now.')
            return
        end

        local challenge = trimWhitespace(randomFrom(challenges))
        broadcastFunMessage(source, ('new sandbox challenge: ^3%s'):format(challenge))
    end, false)

    AddEventHandler('playerDropped', function()
        funCommandUsage[source] = nil
    end)
end
