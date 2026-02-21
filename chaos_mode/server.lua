local chaosEnabled = Config.Enabled

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
