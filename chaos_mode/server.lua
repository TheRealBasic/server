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
    'sudden_brake',
    'banana_spin',
    'noodle_legs',
    'sneeze_nudge',
    'confetti_pop',
    'radio_scramble',
    'map_shuffle',
    'brake_tap',
    'tiny_bounce',
    'butterhands',
    'compass_flip',
    'gravity_glitch',
    'dance_loop',
    'shoe_glue',
    'hiccup_boost',
    'phantom_honk'
}


local funCommandUsage = {}
local placedProps = {}
local playerPropCounts = {}
local propBehaviorCooldowns = {}

local function getBuildToolConfig()
    return type(Config.BuildTool) == 'table' and Config.BuildTool or {}
end

local function getBuildAllowedEntries()
    local entriesById = {}
    local entriesByModel = {}
    local catalog = type(Config.BuildToolModelCatalog) == 'table' and Config.BuildToolModelCatalog or {}
    local buildConfig = getBuildToolConfig()
    local groups = buildConfig.AllowedModels

    if type(groups) ~= 'table' then
        return entriesById, entriesByModel
    end

    for _, group in pairs(groups) do
        local groupEntries = type(group) == 'table' and group.entries or nil
        if type(groupEntries) == 'table' then
            for _, entry in ipairs(groupEntries) do
                if type(entry) == 'table' and type(entry.id) == 'string' then
                    local catalogEntry = catalog[entry.id]
                    if type(catalogEntry) == 'table' and type(catalogEntry.model) == 'string' then
                        local modelHash = joaat(catalogEntry.model)
                        local behavior = type(entry.behavior) == 'table' and entry.behavior or nil
                        local payload = {
                            id = entry.id,
                            model = modelHash,
                            behavior = behavior
                        }
                        entriesById[entry.id] = payload
                        entriesByModel[modelHash] = payload
                    end
                end
            end
        end
    end

    return entriesById, entriesByModel
end


local function getBuildCatalogPayload()
    local payload = {}
    local catalog = type(Config.BuildToolModelCatalog) == 'table' and Config.BuildToolModelCatalog or {}
    local groups = getBuildToolConfig().AllowedModels

    if type(groups) ~= 'table' then
        return payload
    end

    for categoryId, group in pairs(groups) do
        local entries = type(group) == 'table' and group.entries or nil
        if type(entries) == 'table' then
            for _, entry in ipairs(entries) do
                local propId = type(entry) == 'table' and entry.id or nil
                local item = propId and catalog[propId] or nil
                if type(item) == 'table' and type(item.model) == 'string' then
                    table.insert(payload, {
                        id = propId,
                        label = item.label or propId,
                        description = item.description or '',
                        categoryId = categoryId,
                        categoryLabel = type(group.label) == 'string' and group.label or tostring(categoryId)
                    })
                end
            end
        end
    end

    table.sort(payload, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)

    return payload
end

local function isBuildAdmin(src)
    local buildConfig = getBuildToolConfig()
    local ace = tostring(buildConfig.AdminAce or 'chaos_mode.build_admin')
    return src == 0 or IsPlayerAceAllowed(src, ace)
end

local function sendBuildMessage(src, message)
    if src == 0 then
        print('[build] ' .. message)
        return
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = { '^3Build', message }
    })
end

local function getPlayerPropCount(src)
    return playerPropCounts[src] or 0
end

local function adjustPlayerPropCount(src, delta)
    local current = getPlayerPropCount(src)
    local updated = current + delta
    if updated <= 0 then
        playerPropCounts[src] = nil
    else
        playerPropCounts[src] = updated
    end
end

local function countPlacedProps()
    local count = 0
    for _ in pairs(placedProps) do
        count = count + 1
    end
    return count
end

local function sanitizeRotation(value)
    local numeric = tonumber(value)
    if not numeric then
        return nil
    end

    while numeric > 180.0 do
        numeric = numeric - 360.0
    end

    while numeric < -180.0 do
        numeric = numeric + 360.0
    end

    return numeric
end

local function getNumericVector3(input)
    if type(input) ~= 'table' then
        return nil
    end

    local x = tonumber(input.x)
    local y = tonumber(input.y)
    local z = tonumber(input.z)
    if not x or not y or not z then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function getBuildBehaviorConfig()
    local buildConfig = getBuildToolConfig()
    local behavior = type(buildConfig.PropBehavior) == 'table' and buildConfig.PropBehavior or {}

    return {
        serverValidationRange = math.max(1.0, tonumber(behavior.ServerValidationRange) or 5.0),
        majorBoostForwardThreshold = math.max(0.0, tonumber(behavior.MajorBoostForwardThreshold) or 8.5)
    }
end

local function getSanitizedBehavior(entryBehavior)
    if type(entryBehavior) ~= 'table' then
        return nil
    end

    local bounceForce = tonumber(entryBehavior.bounceForce)
    local forwardBoost = tonumber(entryBehavior.forwardBoost)
    local cooldownMs = tonumber(entryBehavior.cooldownMs)

    if not bounceForce and not forwardBoost then
        return nil
    end

    return {
        bounceForce = math.max(0.0, math.min(20.0, bounceForce or 0.0)),
        forwardBoost = math.max(0.0, math.min(25.0, forwardBoost or 0.0)),
        cooldownMs = math.max(0, math.floor(cooldownMs or 1500))
    }
end

local function isPositionInBounds(position)
    local bounds = getBuildToolConfig().Bounds
    if type(bounds) ~= 'table' then
        return true
    end

    local min = getNumericVector3(bounds.min)
    local max = getNumericVector3(bounds.max)
    if not min or not max then
        return true
    end

    return position.x >= math.min(min.x, max.x)
        and position.x <= math.max(min.x, max.x)
        and position.y >= math.min(min.y, max.y)
        and position.y <= math.max(min.y, max.y)
        and position.z >= math.min(min.z, max.z)
        and position.z <= math.max(min.z, max.z)
end

local function isRotationInBounds(pitch, roll, heading)
    local rotationLimits = getBuildToolConfig().RotationLimits
    if type(rotationLimits) ~= 'table' then
        return true
    end

    local function within(value, range)
        if type(range) ~= 'table' then
            return true
        end
        local minValue = tonumber(range.min)
        local maxValue = tonumber(range.max)
        if not minValue or not maxValue then
            return true
        end
        return value >= math.min(minValue, maxValue) and value <= math.max(minValue, maxValue)
    end

    return within(pitch, rotationLimits.pitch) and within(roll, rotationLimits.roll) and within(heading, rotationLimits.heading)
end

local function getEntityFromNetId(netId)
    local numericNetId = tonumber(netId)
    if not numericNetId or numericNetId <= 0 then
        return nil
    end

    if not NetworkDoesNetworkIdExist(numericNetId) then
        return nil
    end

    local entity = NetworkGetEntityFromNetworkId(numericNetId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil
    end

    return entity
end

local function getAttachData(payload)
    if type(payload) ~= 'table' then
        return nil
    end

    local targetNetId = tonumber(payload.targetNetId)
    if not targetNetId or targetNetId <= 0 then
        return nil
    end

    local offset = getNumericVector3(payload.offset)
    local rotation = getNumericVector3(payload.rotation)
    if not offset or not rotation then
        return nil
    end

    rotation.x = sanitizeRotation(rotation.x)
    rotation.y = sanitizeRotation(rotation.y)
    rotation.z = sanitizeRotation(rotation.z)

    if not rotation.x or not rotation.y or not rotation.z then
        return nil
    end

    return {
        targetNetId = targetNetId,
        offset = offset,
        rotation = rotation
    }
end

local function removePlacedProp(netId, reason)
    local propData = placedProps[netId]
    if not propData then
        return false
    end

    local entity = propData.entity
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    placedProps[netId] = nil
    adjustPlayerPropCount(propData.owner, -1)

    TriggerClientEvent('chaos_mode:propRemoved', -1, {
        netId = netId,
        reason = reason or 'removed'
    })

    return true
end

local function cleanupPlayerProps(src, reason)
    local targets = {}
    for netId, propData in pairs(placedProps) do
        if propData.owner == src then
            targets[#targets + 1] = netId
        end
    end

    for _, netId in ipairs(targets) do
        removePlacedProp(netId, reason)
    end

    playerPropCounts[src] = nil
end

local function getPlacedPropSnapshot()
    local snapshot = {}
    for netId, propData in pairs(placedProps) do
        snapshot[#snapshot + 1] = {
            netId = netId,
            owner = propData.owner,
            propId = propData.propId,
            model = propData.model,
            position = propData.position,
            heading = propData.heading,
            pitch = propData.pitch,
            roll = propData.roll,
            placementMode = propData.placementMode,
            attach = propData.attach,
            behavior = propData.behavior
        }
    end
    return snapshot
end

AddEventHandler('playerDropped', function()
    cleanupPlayerProps(source, 'owner_disconnected')
    propBehaviorCooldowns[source] = nil
end)

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
local eventToggles = {}

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
    if eventToggles[eventName] == false then
        return 0
    end

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

local function buildEnabledEventPool()
    local enabled = {}
    for _, eventName in ipairs(Config.EventPool) do
        if eventToggles[eventName] ~= false then
            enabled[#enabled + 1] = eventName
        end
    end
    return enabled
end

local function setEventToggle(eventName, enabled)
    eventToggles[eventName] = enabled == true
end

local function getEventToggleMap()
    local toggles = {}
    for _, eventName in ipairs(Config.EventPool) do
        toggles[eventName] = eventToggles[eventName] ~= false
    end
    return toggles
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
    local enabledPool = buildEnabledEventPool()
    if #enabledPool == 0 then
        return nil
    end

    local primaryEvent = chooseEvent(enabledPool, 'combo-primary')
    if not primaryEvent then
        return nil
    end

    local candidates = {}
    for _, eventName in ipairs(enabledPool) do
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

for _, eventName in ipairs(Config.EventPool) do
    eventToggles[eventName] = true
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
                local enabledPool = buildEnabledEventPool()
                if #enabledPool > 0 then
                    if Config.ComboEnabled and randomBetween(1, 100) <= Config.ComboChance then
                        local combo = chooseComboEvent()
                        if combo and #combo > 0 then
                            triggerChaosEvent(combo)
                        end
                    else
                        local chosen = chooseEvent(enabledPool, 'single')
                        if chosen then
                            triggerChaosEvent({ chosen })
                        end
                    end
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
        trollActionMeta = Config.TrollActionMeta or {},
        eventMeta = Config.EventMeta or {},
        eventToggles = getEventToggleMap(),
        buildCatalog = getBuildCatalogPayload(),
        buildProps = getPlacedPropSnapshot()
    })
end)

RegisterNetEvent('chaos_mode:requestHudState', function()
    broadcastHudState(source)
end)

RegisterNetEvent('chaos_mode:placePropRequest', function(payload)
    local src = source
    local buildConfig = getBuildToolConfig()

    if buildConfig.Enabled == false then
        sendBuildMessage(src, 'Build mode is disabled by server configuration.')
        return
    end

    if type(payload) ~= 'table' then
        return
    end

    local propId = tostring(payload.propId or '')
    local model = tonumber(payload.model)
    local position = getNumericVector3(payload.position)
    local heading = sanitizeRotation(payload.heading)
    local pitch = sanitizeRotation(payload.pitch)
    local roll = sanitizeRotation(payload.roll)
    local placementMode = tostring(payload.placementMode or 'world')
    local attachData = placementMode == 'attach' and getAttachData(payload.attach) or nil

    if placementMode ~= 'world' and placementMode ~= 'attach' then
        sendBuildMessage(src, 'Unknown placement mode.')
        return
    end

    if not model or not position or not heading or not pitch or not roll then
        sendBuildMessage(src, 'Invalid prop placement data.')
        return
    end

    if placementMode == 'attach' and not attachData then
        sendBuildMessage(src, 'Invalid attachment payload.')
        return
    end

    local allowedById, allowedByModel = getBuildAllowedEntries()
    local allowedEntryById = allowedById[propId]
    if not allowedEntryById then
        sendBuildMessage(src, 'Unknown or disallowed prop id.')
        return
    end

    if allowedEntryById.model ~= model then
        sendBuildMessage(src, 'Prop model mismatch for the selected prop id.')
        return
    end

    if not allowedByModel[model] then
        sendBuildMessage(src, 'That prop model is not allowed.')
        return
    end

    local behavior = getSanitizedBehavior(allowedEntryById.behavior)

    local maxPerPlayer = math.max(1, math.floor(tonumber(buildConfig.MaxPropsPerPlayer) or 30))
    local maxGlobal = math.max(1, math.floor(tonumber(buildConfig.MaxPropsGlobal) or 300))
    if getPlayerPropCount(src) >= maxPerPlayer then
        sendBuildMessage(src, ('Prop limit reached (%d per player).'):format(maxPerPlayer))
        return
    end

    if countPlacedProps() >= maxGlobal then
        sendBuildMessage(src, ('Global prop limit reached (%d).'):format(maxGlobal))
        return
    end

    if not isPositionInBounds(position) then
        sendBuildMessage(src, 'Placement position is outside allowed bounds.')
        return
    end

    if not isRotationInBounds(pitch, roll, heading) then
        sendBuildMessage(src, 'Rotation exceeds server limits.')
        return
    end

    local object = CreateObjectNoOffset(model, position.x, position.y, position.z, true, true, false)
    if not object or object == 0 or not DoesEntityExist(object) then
        sendBuildMessage(src, 'Failed to create networked prop.')
        return
    end

    SetEntityHeading(object, heading)
    SetEntityRotation(object, pitch, roll, heading, 2, true)

    if placementMode == 'attach' then
        local attachTarget = getEntityFromNetId(attachData.targetNetId)
        if not attachTarget then
            DeleteEntity(object)
            sendBuildMessage(src, 'Attachment target no longer exists.')
            return
        end

        local ownerPed = GetPlayerPed(src)
        if ownerPed and ownerPed ~= 0 and DoesEntityExist(ownerPed) then
            local ownerCoords = GetEntityCoords(ownerPed)
            local targetCoords = GetEntityCoords(attachTarget)
            local maxDistance = tonumber(buildConfig.MaxPlaceDistance) or tonumber(buildConfig.Snap and buildConfig.Snap.MaxPlaceDistance) or 25.0
            if #(ownerCoords - targetCoords) > (maxDistance + 5.0) then
                DeleteEntity(object)
                sendBuildMessage(src, 'Attachment target is too far away.')
                return
            end
        end

        AttachEntityToEntity(
            object,
            attachTarget,
            0,
            attachData.offset.x,
            attachData.offset.y,
            attachData.offset.z,
            attachData.rotation.x,
            attachData.rotation.y,
            attachData.rotation.z,
            false,
            false,
            true,
            false,
            2,
            true
        )
    else
        FreezeEntityPosition(object, true)
    end

    local netId = NetworkGetNetworkIdFromEntity(object)
    if not netId or netId <= 0 then
        DeleteEntity(object)
        sendBuildMessage(src, 'Failed to register networked prop.')
        return
    end

    placedProps[netId] = {
        netId = netId,
        entity = object,
        owner = src,
        model = model,
        propId = propId,
        position = position,
        heading = heading,
        pitch = pitch,
        roll = roll,
        createdAt = os.time(),
        placementMode = placementMode,
        attach = attachData,
        behavior = behavior
    }
    adjustPlayerPropCount(src, 1)

    TriggerClientEvent('chaos_mode:propSpawned', -1, {
        netId = netId,
        owner = src,
        propId = propId,
        model = model,
        position = position,
        heading = heading,
        pitch = pitch,
        roll = roll,
        placementMode = placementMode,
        attach = attachData,
        behavior = behavior
    })
end)

RegisterNetEvent('chaos_mode:removePropRequest', function(payload)
    local src = source
    if type(payload) ~= 'table' then
        return
    end

    local netId = tonumber(payload.netId)
    if not netId then
        return
    end

    local propData = placedProps[netId]
    if not propData then
        sendBuildMessage(src, 'Prop no longer exists.')
        return
    end

    if propData.owner ~= src and not isBuildAdmin(src) then
        sendBuildMessage(src, 'You do not own that prop.')
        return
    end

    removePlacedProp(netId, 'manual_remove')
end)

RegisterNetEvent('chaos_mode:editPropRequest', function(payload)
    local src = source
    if type(payload) ~= 'table' then
        return
    end

    local netId = tonumber(payload.netId)
    if not netId then
        return
    end

    local propData = placedProps[netId]
    if not propData then
        sendBuildMessage(src, 'Prop no longer exists.')
        return
    end

    if propData.owner ~= src and not isBuildAdmin(src) then
        sendBuildMessage(src, 'You do not own that prop.')
        return
    end

    local newPosition = payload.position and getNumericVector3(payload.position) or propData.position
    local newHeading = payload.heading ~= nil and sanitizeRotation(payload.heading) or propData.heading
    local newPitch = payload.pitch ~= nil and sanitizeRotation(payload.pitch) or propData.pitch
    local newRoll = payload.roll ~= nil and sanitizeRotation(payload.roll) or propData.roll

    if not newPosition or not newHeading or not newPitch or not newRoll then
        sendBuildMessage(src, 'Invalid prop edit values.')
        return
    end

    if not isPositionInBounds(newPosition) then
        sendBuildMessage(src, 'New position is outside allowed bounds.')
        return
    end

    if not isRotationInBounds(newPitch, newRoll, newHeading) then
        sendBuildMessage(src, 'New rotation exceeds server limits.')
        return
    end

    local entity = propData.entity
    if not entity or not DoesEntityExist(entity) then
        entity = NetworkGetEntityFromNetworkId(netId)
    end

    if not entity or entity == 0 or not DoesEntityExist(entity) then
        placedProps[netId] = nil
        adjustPlayerPropCount(propData.owner, -1)
        sendBuildMessage(src, 'Unable to edit prop because entity no longer exists.')
        TriggerClientEvent('chaos_mode:propRemoved', -1, { netId = netId, reason = 'desync_cleanup' })
        return
    end

    SetEntityCoordsNoOffset(entity, newPosition.x, newPosition.y, newPosition.z, false, false, false)
    SetEntityHeading(entity, newHeading)
    SetEntityRotation(entity, newPitch, newRoll, newHeading, 2, true)
    FreezeEntityPosition(entity, true)

    propData.entity = entity
    propData.position = newPosition
    propData.heading = newHeading
    propData.pitch = newPitch
    propData.roll = newRoll

    TriggerClientEvent('chaos_mode:propSpawned', -1, {
        netId = netId,
        owner = propData.owner,
        propId = propData.propId,
        model = propData.model,
        position = newPosition,
        heading = newHeading,
        pitch = newPitch,
        roll = newRoll,
        behavior = propData.behavior,
        edited = true
    })
end)


RegisterNetEvent('chaos_mode:requestPropBehaviorBoost', function(payload)
    local src = source
    if type(payload) ~= 'table' then
        return
    end

    local netId = tonumber(payload.netId)
    if not netId then
        return
    end

    local propData = placedProps[netId]
    if not propData or type(propData.behavior) ~= 'table' then
        return
    end

    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        return
    end

    local propEntity = propData.entity
    if (not propEntity or not DoesEntityExist(propEntity)) and NetworkDoesNetworkIdExist(netId) then
        propEntity = NetworkGetEntityFromNetworkId(netId)
    end

    if not propEntity or propEntity == 0 or not DoesEntityExist(propEntity) then
        return
    end

    local behaviorConfig = getBuildBehaviorConfig()
    local playerCoords = GetEntityCoords(playerPed)
    local propCoords = GetEntityCoords(propEntity)
    if #(playerCoords - propCoords) > behaviorConfig.serverValidationRange then
        return
    end

    local now = GetGameTimer()
    local playerCooldowns = propBehaviorCooldowns[src] or {}
    local nextAllowedAt = playerCooldowns[netId] or 0
    if now < nextAllowedAt then
        return
    end

    playerCooldowns[netId] = now + (propData.behavior.cooldownMs or 0)
    propBehaviorCooldowns[src] = playerCooldowns

    local approvedPayload = {
        netId = netId,
        bounceForce = propData.behavior.bounceForce,
        forwardBoost = propData.behavior.forwardBoost,
        cooldownMs = propData.behavior.cooldownMs,
        playerSrc = src
    }

    if (propData.behavior.forwardBoost or 0.0) >= behaviorConfig.majorBoostForwardThreshold then
        TriggerClientEvent('chaos_mode:syncPropBehaviorBoost', -1, approvedPayload)
    else
        TriggerClientEvent('chaos_mode:applyPropBehaviorBoost', src, approvedPayload)
    end
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

    if eventToggles[eventName] == false then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Chaos', ('Event "%s" is disabled in options.'):format(eventName) }
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

RegisterNetEvent('chaos_mode:setEventToggle', function(payload)
    local src = source
    if type(payload) ~= 'table' then
        return
    end

    local eventName = tostring(payload.eventName or '')
    local enabled = payload.enabled == true
    if eventName == '' or not eventExists(eventName) then
        return
    end

    setEventToggle(eventName, enabled)

    local toggleMap = getEventToggleMap()
    TriggerClientEvent('chaos_mode:eventTogglesUpdated', -1, toggleMap)

    local actor = GetPlayerName(src) or ('Player ' .. tostring(src))
    print(('[chaos_mode] %s set "%s" %s'):format(actor, eventName, enabled and 'ENABLED' or 'DISABLED'))
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

    local enabledPool = buildEnabledEventPool()
    if #enabledPool == 0 then
        print('[chaos_mode] No enabled events available to trigger.')
        return
    end

    if Config.ComboEnabled and randomBetween(1, 100) <= Config.ComboChance then
        local combo = chooseComboEvent()
        if combo and #combo > 0 then
            triggerChaosEvent(combo)
        end
    else
        local chosen = chooseEvent(enabledPool, 'single')
        if chosen then
            triggerChaosEvent({ chosen })
        end
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
