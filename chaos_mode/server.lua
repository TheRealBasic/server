local chaosEnabled = Config.Enabled

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

local function triggerChaosEvent(eventName)
    TriggerClientEvent('chaos_mode:runEvent', -1, eventName, {
        weather = randomFrom(Config.WeatherTypes),
        hostileDuration = Config.HostileNpcDurationMs,
        objectMin = Config.RandomObjectCount.min,
        objectMax = Config.RandomObjectCount.max,
        spawnRadius = Config.SpawnRadius,
        cleanupMs = Config.ObjectCleanupMs,
        models = Config.RandomObjectModels
    })

    print(('[chaos_mode] Triggered event: %s'):format(eventName))
end

local function chooseEvent()
    return randomFrom(Config.EventPool)
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
                triggerChaosEvent(chooseEvent())
            end
        else
            Wait(2000)
        end
    end
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

    triggerChaosEvent(chooseEvent())
end, true)
