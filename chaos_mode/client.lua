local spawnedObjects = {}
local hostilePeds = {}
local lowGravityActive = false

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('~o~CHAOS~s~: %s'):format(message))
    EndTextCommandThefeedPostTicker(false, true)
end

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasModelLoaded(model)
end

local function cleanObjectsAfter(ms)
    CreateThread(function()
        Wait(ms)
        for _, object in ipairs(spawnedObjects) do
            if DoesEntityExist(object) then
                DeleteEntity(object)
            end
        end
        spawnedObjects = {}
    end)
end

local function weatherShift(weather)
    notify(('Weather shift: %s'):format(weather))
    SetWeatherTypeOvertimePersist(weather, 12.0)
end

local function spawnHostilePeds(durationMs)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local pedModel = `g_m_y_lost_01`

    if not loadModel(pedModel) then
        notify('Failed to load hostile NPC model')
        return
    end

    notify('NPC rebellion started!')

    for i = 1, 6 do
        local offset = vec3(math.random(-20, 20), math.random(-20, 20), 0.0)
        local spawn = playerCoords + offset
        local ped = CreatePed(4, pedModel, spawn.x, spawn.y, spawn.z, 0.0, true, true)
        if DoesEntityExist(ped) then
            GiveWeaponToPed(ped, `WEAPON_BAT`, 1, false, true)
            SetPedAsEnemy(ped, true)
            SetPedCombatAttributes(ped, 46, true)
            TaskCombatPed(ped, playerPed, 0, 16)
            table.insert(hostilePeds, ped)
        end
    end

    SetModelAsNoLongerNeeded(pedModel)

    CreateThread(function()
        Wait(durationMs)
        for _, ped in ipairs(hostilePeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        hostilePeds = {}
        notify('NPC rebellion ended')
    end)
end

local function spawnRandomObjects(data)
    local playerPed = PlayerPedId()
    local baseCoords = GetEntityCoords(playerPed)
    local amount = math.random(data.objectMin, data.objectMax)

    notify(('Object storm: %d props dropped nearby'):format(amount))

    for i = 1, amount do
        local model = data.models[math.random(1, #data.models)]
        if loadModel(model) then
            local offset = vec3(
                math.random() * data.spawnRadius * (math.random(0, 1) == 1 and 1 or -1),
                math.random() * data.spawnRadius * (math.random(0, 1) == 1 and 1 or -1),
                math.random(2, 8)
            )
            local spawn = baseCoords + offset
            local object = CreateObject(model, spawn.x, spawn.y, spawn.z, true, true, false)
            if DoesEntityExist(object) then
                PlaceObjectOnGroundProperly(object)
                table.insert(spawnedObjects, object)
            end
            SetModelAsNoLongerNeeded(model)
        end
    end

    cleanObjectsAfter(data.cleanupMs)
end

local function lowGravityBurst()
    if lowGravityActive then return end
    lowGravityActive = true
    notify('Low gravity burst for 20s')
    SetGravityLevel(1)

    CreateThread(function()
        Wait(20000)
        SetGravityLevel(0)
        lowGravityActive = false
        notify('Gravity normalized')
    end)
end

local function ragdollWave()
    local playerPed = PlayerPedId()
    notify('Ragdoll wave!')
    SetPedToRagdoll(playerPed, 3500, 3500, 0, false, false, false)
end

RegisterNetEvent('chaos_mode:runEvent', function(eventName, data)
    if eventName == 'weather_shift' then
        weatherShift(data.weather)
    elseif eventName == 'hostile_npcs' then
        spawnHostilePeds(data.hostileDuration)
    elseif eventName == 'spawn_random_objects' then
        spawnRandomObjects(data)
    elseif eventName == 'low_gravity_burst' then
        lowGravityBurst()
    elseif eventName == 'ragdoll_wave' then
        ragdollWave()
    end
end)
