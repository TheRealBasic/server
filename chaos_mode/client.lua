local hostilePeds = {}
local lowGravityActive = false
local activeTimedEffects = {}

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

local function withTimedEffect(effectKey, durationMs, onStart, onTick, onStop)
    if activeTimedEffects[effectKey] then return false end
    activeTimedEffects[effectKey] = true

    if onStart then
        onStart()
    end

    CreateThread(function()
        local endAt = GetGameTimer() + durationMs
        while GetGameTimer() < endAt do
            if onTick then
                onTick()
            end
            Wait(0)
        end

        if onStop then
            onStop()
        end

        activeTimedEffects[effectKey] = false
    end)

    return true
end

local function cleanObjectsAfter(objects, ms)
    CreateThread(function()
        Wait(ms)
        for _, object in ipairs(objects) do
            if DoesEntityExist(object) then
                DeleteEntity(object)
            end
        end
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
    local eventObjects = {}

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
                table.insert(eventObjects, object)
            end
            SetModelAsNoLongerNeeded(model)
        end
    end

    cleanObjectsAfter(eventObjects, data.cleanupMs)
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

local function drunk_vision()
    if withTimedEffect('drunk_vision', 20000,
        function()
            notify('Drunk vision for 20s')
            StartScreenEffect('DrugsDrivingOut', 0, true)
            ShakeGameplayCam('DRUNK_SHAKE', 1.0)
        end,
        nil,
        function()
            StopGameplayCamShaking(true)
            StopScreenEffect('DrugsDrivingOut')
        end
    ) then end
end

local function speed_burst()
    if withTimedEffect('speed_burst', 15000,
        function()
            notify('Sprint speed x1.4 for 15s')
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.4)
        end,
        nil,
        function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
    ) then end
end

local function super_jump_burst()
    if withTimedEffect('super_jump_burst', 15000,
        function() notify('Super jump for 15s') end,
        function() SetSuperJumpThisFrame(PlayerId()) end,
        nil
    ) then end
end

local function explosive_ammo_burst()
    if withTimedEffect('explosive_ammo_burst', 12000,
        function() notify('Explosive ammo enabled for 12s') end,
        function() SetExplosiveAmmoThisFrame(PlayerId()) end,
        nil
    ) then end
end

local function explosive_melee_burst()
    if withTimedEffect('explosive_melee_burst', 12000,
        function() notify('Explosive melee enabled for 12s') end,
        function() SetExplosiveMeleeThisFrame(PlayerId()) end,
        nil
    ) then end
end

local function fire_ammo_burst()
    if withTimedEffect('fire_ammo_burst', 12000,
        function() notify('Incendiary ammo enabled for 12s') end,
        function() SetFireAmmoThisFrame(PlayerId()) end,
        nil
    ) then end
end

local function rapid_fire_burst()
    if withTimedEffect('rapid_fire_burst', 12000,
        function() notify('Rapid fire enabled for 12s') end,
        function() SetPedInfiniteAmmoClip(PlayerPedId(), true) end,
        function() SetPedInfiniteAmmoClip(PlayerPedId(), false) end
    ) then end
end

local function random_wanted_level()
    local wanted = math.random(1, 5)
    notify(('Wanted level raised to %d'):format(wanted))
    SetPlayerWantedLevel(PlayerId(), wanted, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
end

local function armor_refill()
    local ped = PlayerPedId()
    notify('Armor topped up')
    SetPedArmour(ped, 100)
end

local function health_boost()
    local ped = PlayerPedId()
    notify('Health boosted')
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + 75))
end

local function health_drain()
    local ped = PlayerPedId()
    local newHealth = math.max(110, GetEntityHealth(ped) - 60)
    notify('Health drained')
    SetEntityHealth(ped, newHealth)
end

local function teleport_shuffle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local offset = vec3(math.random(-40, 40), math.random(-40, 40), 0.0)
    local destination = coords + offset
    notify('Teleport shuffle!')
    SetEntityCoordsNoOffset(ped, destination.x, destination.y, destination.z, false, false, false)
end

local function blackout_burst()
    if withTimedEffect('blackout_burst', 10000,
        function()
            notify('City blackout for 10s')
            SetArtificialLightsState(true)
            SetArtificialLightsStateAffectsVehicles(false)
        end,
        nil,
        function()
            SetArtificialLightsState(false)
        end
    ) then end
end

local function random_time_shift()
    local hour = math.random(0, 23)
    local minute = math.random(0, 59)
    notify(('Time jumped to %02d:%02d'):format(hour, minute))
    NetworkOverrideClockTime(hour, minute, 0)
end

local function camera_shake_burst()
    if withTimedEffect('camera_shake_burst', 8000,
        function()
            notify('Earthquake camera shake for 8s')
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.75)
        end,
        nil,
        function()
            StopGameplayCamShaking(true)
        end
    ) then end
end

local function random_weapon()
    local weapons = {
        `WEAPON_BAT`,
        `WEAPON_PISTOL`,
        `WEAPON_SAWNOFFSHOTGUN`,
        `WEAPON_MICROSMG`,
        `WEAPON_MOLOTOV`
    }

    local ped = PlayerPedId()
    local weapon = weapons[math.random(1, #weapons)]
    notify('Weapon roulette!')
    GiveWeaponToPed(ped, weapon, 120, false, true)
end

local function vehicle_slip()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Slip failed: you are not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Vehicle slip!')
    SetVehicleReduceGrip(vehicle, true)

    CreateThread(function()
        Wait(7000)
        if DoesEntityExist(vehicle) then
            SetVehicleReduceGrip(vehicle, false)
        end
    end)
end

local function vehicle_boost()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Boost failed: you are not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Nitro-ish vehicle boost!')
    SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + 30.0)
end

local function random_screen_filter()
    local filters = { 'spectator5', 'rply_saturation_neg', 'BarryFadeOut', 'scanline_cam_cheap' }
    local filter = filters[math.random(1, #filters)]

    if withTimedEffect('random_screen_filter', 12000,
        function()
            notify('Screen filter chaos for 12s')
            SetTimecycleModifier(filter)
        end,
        nil,
        function()
            ClearTimecycleModifier()
        end
    ) then end
end

local function no_hud_burst()
    if withTimedEffect('no_hud_burst', 7000,
        function() notify('HUD disabled for 7s') end,
        function()
            HideHudAndRadarThisFrame()
            HideHudComponentThisFrame(1)
            HideHudComponentThisFrame(2)
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
        end,
        nil
    ) then end
end

local eventHandlers = {
    weather_shift = function(data) weatherShift(data.weather) end,
    hostile_npcs = function(data) spawnHostilePeds(data.hostileDuration) end,
    spawn_random_objects = function(data) spawnRandomObjects(data) end,
    low_gravity_burst = lowGravityBurst,
    ragdoll_wave = ragdollWave,
    drunk_vision = drunk_vision,
    speed_burst = speed_burst,
    super_jump_burst = super_jump_burst,
    explosive_ammo_burst = explosive_ammo_burst,
    explosive_melee_burst = explosive_melee_burst,
    fire_ammo_burst = fire_ammo_burst,
    rapid_fire_burst = rapid_fire_burst,
    random_wanted_level = random_wanted_level,
    armor_refill = armor_refill,
    health_boost = health_boost,
    health_drain = health_drain,
    teleport_shuffle = teleport_shuffle,
    blackout_burst = blackout_burst,
    random_time_shift = random_time_shift,
    camera_shake_burst = camera_shake_burst,
    random_weapon = random_weapon,
    vehicle_slip = vehicle_slip,
    vehicle_boost = vehicle_boost,
    random_screen_filter = random_screen_filter,
    no_hud_burst = no_hud_burst
}

RegisterNetEvent('chaos_mode:runEvent', function(eventName, data)
    local handler = eventHandlers[eventName]
    if handler then
        handler(data)
    else
        notify(('Unknown chaos event: %s'):format(eventName))
    end
end)
