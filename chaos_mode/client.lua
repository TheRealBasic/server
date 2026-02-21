local hostilePeds = {}
local lowGravityActive = false
local activeTimedEffects = {}
local menuOpen = false

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('~o~CHAOS~s~: %s'):format(message))
    EndTextCommandThefeedPostTicker(false, true)
end

local function setMenuState(isOpen)
    menuOpen = isOpen
    SetNuiFocus(isOpen, isOpen)
    SendNUIMessage({
        action = 'setVisible',
        visible = isOpen
    })
end

local function openChaosMenu()
    TriggerServerEvent('chaos_mode:requestMenuData')
    setMenuState(true)
end

local function closeChaosMenu()
    setMenuState(false)
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

local function withTimedEffect(effectKey, durationMs, onStart, onTick, onStop, tickMs)
    tickMs = tickMs or 100

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
            Wait(tickMs)
        end

        if onStop then
            onStop()
        end

        activeTimedEffects[effectKey] = false
    end)

    return true
end

local function getEffectMeta(eventName, data)
    local compatibility = data and data.eventCompatibility or nil
    if type(compatibility) ~= 'table' then
        return nil
    end

    local meta = compatibility[eventName]
    if type(meta) ~= 'table' then
        return nil
    end

    return meta
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
    local targetCount = 6
    local maxRetriesPerSpawn = 4
    local maxSpawnAttempts = targetCount * 4

    if not loadModel(pedModel) then
        notify('Failed to load hostile NPC model')
        return
    end

    notify('NPC rebellion started!')

    local spawnedCount = 0
    local attempts = 0

    while spawnedCount < targetCount and attempts < maxSpawnAttempts do
        attempts = attempts + 1
        local offset = vec3(math.random(-20, 20), math.random(-20, 20), 0.0)
        local spawnX = playerCoords.x + offset.x
        local spawnY = playerCoords.y + offset.y
        local spawnZ = nil

        for retry = 1, maxRetriesPerSpawn do
            local probeZ = playerCoords.z + 40.0 + ((retry - 1) * 20.0)
            local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, probeZ, false)
            if foundGround then
                spawnZ = groundZ + 1.0
                break
            end

            local foundGroundNormal, normalZ = GetGroundZAndNormalFor_3dCoord(spawnX, spawnY, probeZ)
            if foundGroundNormal then
                spawnZ = normalZ + 1.0
                break
            end
        end

        if spawnZ == nil then
            goto continue
        end

        local ped = CreatePed(4, pedModel, spawnX, spawnY, spawnZ, 0.0, true, true)
        if DoesEntityExist(ped) then
            GiveWeaponToPed(ped, `WEAPON_BAT`, 1, false, true)
            SetPedAsEnemy(ped, true)
            SetPedCombatAttributes(ped, 46, true)
            TaskCombatPed(ped, playerPed, 0, 16)
            table.insert(hostilePeds, ped)
            spawnedCount = spawnedCount + 1
        end

        ::continue::
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
        nil,
        0
    ) then end
end

local function explosive_ammo_burst()
    if withTimedEffect('explosive_ammo_burst', 12000,
        function() notify('Explosive ammo enabled for 12s') end,
        function() SetExplosiveAmmoThisFrame(PlayerId()) end,
        nil,
        0
    ) then end
end

local function explosive_melee_burst()
    if withTimedEffect('explosive_melee_burst', 12000,
        function() notify('Explosive melee enabled for 12s') end,
        function() SetExplosiveMeleeThisFrame(PlayerId()) end,
        nil,
        0
    ) then end
end

local function fire_ammo_burst()
    if withTimedEffect('fire_ammo_burst', 12000,
        function() notify('Incendiary ammo enabled for 12s') end,
        function() SetFireAmmoThisFrame(PlayerId()) end,
        nil,
        0
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
        nil,
        0
    ) then end
end


local function moon_jump_mania()
    if withTimedEffect('moon_jump_mania', 15000,
        function() notify('Moon jump mania for 15s') end,
        function() SetSuperJumpThisFrame(PlayerId()) end,
        nil,
        0
    ) then end
end

local function chaos_fog()
    if withTimedEffect('chaos_fog', 20000,
        function()
            notify('Chaos fog rolled in for 20s')
            SetWeatherTypeOvertimePersist('FOGGY', 6.0)
        end,
        nil,
        function()
            ClearOverrideWeather()
            ClearWeatherTypePersist()
        end
    ) then end
end

local function rainbow_car()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Rainbow failed: you are not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if withTimedEffect('rainbow_car', 12000,
        function() notify('Rainbow car mode for 12s') end,
        function()
            SetVehicleCustomPrimaryColour(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
            SetVehicleCustomSecondaryColour(vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
        end,
        nil,
        600
    ) then end
end

local function vehicle_malfunction()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Malfunction failed: you are not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Vehicle malfunction! Engine stalling')
    SetVehicleEngineOn(vehicle, false, true, true)
    CreateThread(function()
        Wait(2500)
        if DoesEntityExist(vehicle) then
            SetVehicleEngineOn(vehicle, true, true, false)
        end
    end)
end

local function eject_from_vehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Eject skipped: not in a vehicle')
        return
    end

    notify('EJECT!')
    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 4160)
end

local function brake_failure()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Brake failure failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if withTimedEffect('brake_failure', 9000,
        function() notify('Brake failure for 9s') end,
        function()
            SetVehicleBrakeLights(vehicle, false)
            SetVehicleForwardSpeed(vehicle, math.max(GetEntitySpeed(vehicle), 22.0))
        end,
        nil,
        150
    ) then end
end

local function horn_boost()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Horn boost failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('HONK BOOST!')
    StartVehicleHorn(vehicle, 800, `HELDDOWN`, false)
    SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + 18.0)
end

local function random_door_open()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Door chaos failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local doorIndex = math.random(0, 5)
    notify(('Vehicle door %d flung open'):format(doorIndex))
    SetVehicleDoorOpen(vehicle, doorIndex, false, false)
end

local function tire_burst_all()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Tire burst failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('All tires burst!')
    for i = 0, 7 do
        SetVehicleTyreBurst(vehicle, i, true, 1000.0)
    end
end

local function ignite_player_brief()
    notify('You are on fire!')
    StartEntityFire(PlayerPedId())
    CreateThread(function()
        Wait(3500)
        StopEntityFire(PlayerPedId())
    end)
end

local function slippery_feet()
    if withTimedEffect('slippery_feet', 10000,
        function() notify('Slippery feet for 10s') end,
        function()
            local ped = PlayerPedId()
            if IsPedOnFoot(ped) then
                SetPedToRagdoll(ped, 300, 300, 0, false, false, false)
            end
        end,
        nil,
        1500
    ) then end
end

local function forced_melee()
    if withTimedEffect('forced_melee', 15000,
        function()
            notify('Forced melee only for 15s')
            SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
        end,
        function()
            DisablePlayerFiring(PlayerId(), true)
        end,
        nil,
        0
    ) then end
end

local function disable_aim()
    if withTimedEffect('disable_aim', 10000,
        function() notify('Aiming disabled for 10s') end,
        function()
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 91, true)
        end,
        nil,
        0
    ) then end
end

local function butterfingers()
    local ped = PlayerPedId()
    notify('Butterfingers! Dropped weapon')
    SetPedDropsWeapon(ped)
end

local function ammo_drain()
    local ped = PlayerPedId()
    local _, weapon = GetCurrentPedWeapon(ped, true)
    notify('Ammo drained')
    SetPedAmmo(ped, weapon, 0)
end

local function fake_cops()
    notify('Fake cops called!')
    SetFakeWantedLevel(math.random(2, 5))
    CreateThread(function()
        Wait(8000)
        SetFakeWantedLevel(0)
    end)
end

local function pacifist_mode()
    if withTimedEffect('pacifist_mode', 10000,
        function() notify('Pacifist mode for 10s') end,
        function() DisablePlayerFiring(PlayerId(), true) end,
        nil,
        0
    ) then end
end

local function screen_blur()
    if withTimedEffect('screen_blur', 10000,
        function()
            notify('Screen blur for 10s')
            TriggerScreenblurFadeIn(500)
        end,
        nil,
        function()
            TriggerScreenblurFadeOut(500)
        end
    ) then end
end

local function pixel_world()
    if withTimedEffect('pixel_world', 12000,
        function()
            notify('Pixel world for 12s')
            SetTimecycleModifier('mp_corona_switch')
            SetTimecycleModifierStrength(1.0)
        end,
        nil,
        function()
            ClearTimecycleModifier()
        end
    ) then end
end

local function random_camera_zoom()
    local fov = math.random(35, 95)
    notify(('Camera FOV set to %d for 6s'):format(fov))
    SetGameplayCamFov(fov)
    CreateThread(function()
        Wait(6000)
        SetGameplayCamFov(70.0)
    end)
end

local function drunk_walk()
    if withTimedEffect('drunk_walk', 12000,
        function()
            notify('Drunk walk for 12s')
            RequestAnimSet('move_m@drunk@verydrunk')
            while not HasAnimSetLoaded('move_m@drunk@verydrunk') do
                Wait(0)
            end
            SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 0.2)
        end,
        nil,
        function()
            ResetPedMovementClipset(PlayerPedId(), 0.5)
        end
    ) then end
end

local function npc_panic()
    notify('Nearby NPCs panic!')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, npc in ipairs(GetGamePool('CPed')) do
        if npc ~= ped and not IsPedAPlayer(npc) then
            local npcCoords = GetEntityCoords(npc)
            if #(coords - npcCoords) < 50.0 then
                TaskSmartFleePed(npc, ped, 120.0, 6000, false, false)
            end
        end
    end
end

local function explosion_ring()
    local coords = GetEntityCoords(PlayerPedId())
    notify('Explosion ring!')
    for i = 1, 8 do
        local angle = math.rad((i - 1) * 45)
        AddExplosion(
            coords.x + math.cos(angle) * 8.0,
            coords.y + math.sin(angle) * 8.0,
            coords.z,
            2,
            0.4,
            true,
            false,
            0.2
        )
    end
end

local function trampoline_steps()
    if withTimedEffect('trampoline_steps', 9000,
        function() notify('Trampoline steps for 9s') end,
        function()
            local ped = PlayerPedId()
            if IsPedOnFoot(ped) and IsPedRunning(ped) then
                ApplyForceToEntity(ped, 1, 0.0, 0.0, 2.2, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            end
        end,
        nil,
        300
    ) then end
end

local function teleport_micro_shuffle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local destination = coords + vec3(math.random(-8, 8), math.random(-8, 8), 0.0)
    notify('Micro teleport shuffle!')
    SetEntityCoordsNoOffset(ped, destination.x, destination.y, destination.z, false, false, false)
end

local function freeze_burst()
    if withTimedEffect('freeze_burst', 5000,
        function()
            notify('Frozen in place for 5s')
            FreezeEntityPosition(PlayerPedId(), true)
        end,
        nil,
        function()
            FreezeEntityPosition(PlayerPedId(), false)
        end
    ) then end
end

local function slow_motion_burst()
    if withTimedEffect('slow_motion_burst', 6000,
        function()
            notify('Slow motion for 6s')
            SetTimeScale(0.7)
        end,
        nil,
        function()
            SetTimeScale(1.0)
        end
    ) then end
end

local function vehicle_jump()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Vehicle jump failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Vehicle jump!')
    ApplyForceToEntity(vehicle, 1, 0.0, 0.0, 8.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end

local function confused_inputs()
    if withTimedEffect('confused_inputs', 9000,
        function() notify('Confused controls for 9s') end,
        function()
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
        end,
        nil,
        0
    ) then end
end

local function cinematic_burst()
    if withTimedEffect('cinematic_burst', 12000,
        function()
            notify('Cinematic burst for 12s')
            SetCinematicModeActive(true)
        end,
        nil,
        function()
            SetCinematicModeActive(false)
        end
    ) then end
end


local function wrecking_punch()
    if withTimedEffect('wrecking_punch', 15000,
        function()
            notify('Wrecking punch enabled for 15s')
            SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
        end,
        function()
            local playerId = PlayerId()
            local ped = PlayerPedId()
            SetSuperJumpThisFrame(playerId)
            SetExplosiveMeleeThisFrame(playerId)
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + 8.0)
            end
        end,
        nil,
        0
    ) then end
end

local function tsunami_surge()
    if withTimedEffect('tsunami_surge', 20000,
        function()
            notify('Tsunami surge! Massive waves for 20s')
            SetWeatherTypeOvertimePersist('THUNDER', 3.0)
            SetWavesIntensity(4.0)
            SetWindSpeed(12.0)
        end,
        function()
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.2)
        end,
        function()
            SetWavesIntensity(1.0)
            SetWindSpeed(0.0)
            StopGameplayCamShaking(true)
            ClearWeatherTypePersist()
            ClearOverrideWeather()
        end,
        600
    ) then end
end

local function resetChaosState()
    local playerId = PlayerId()
    local playerPed = PlayerPedId()

    SetGravityLevel(0)
    StopGameplayCamShaking(true)
    StopScreenEffect('DrugsDrivingOut')
    ClearTimecycleModifier()
    SetArtificialLightsState(false)
    SetArtificialLightsStateAffectsVehicles(true)
    SetPedInfiniteAmmoClip(playerPed, false)
    SetRunSprintMultiplierForPlayer(playerId, 1.0)
    TriggerScreenblurFadeOut(0)
    SetTimeScale(1.0)
    FreezeEntityPosition(playerPed, false)
    SetFakeWantedLevel(0)
    ResetPedMovementClipset(playerPed, 0.5)
    SetCinematicModeActive(false)
    SetWavesIntensity(1.0)
    SetWindSpeed(0.0)

    lowGravityActive = false

    for key in pairs(activeTimedEffects) do
        activeTimedEffects[key] = false
    end
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
    no_hud_burst = no_hud_burst,
    moon_jump_mania = moon_jump_mania,
    chaos_fog = chaos_fog,
    rainbow_car = rainbow_car,
    vehicle_malfunction = vehicle_malfunction,
    eject_from_vehicle = eject_from_vehicle,
    brake_failure = brake_failure,
    horn_boost = horn_boost,
    random_door_open = random_door_open,
    tire_burst_all = tire_burst_all,
    ignite_player_brief = ignite_player_brief,
    slippery_feet = slippery_feet,
    forced_melee = forced_melee,
    disable_aim = disable_aim,
    butterfingers = butterfingers,
    ammo_drain = ammo_drain,
    fake_cops = fake_cops,
    pacifist_mode = pacifist_mode,
    screen_blur = screen_blur,
    pixel_world = pixel_world,
    random_camera_zoom = random_camera_zoom,
    drunk_walk = drunk_walk,
    npc_panic = npc_panic,
    explosion_ring = explosion_ring,
    trampoline_steps = trampoline_steps,
    teleport_micro_shuffle = teleport_micro_shuffle,
    freeze_burst = freeze_burst,
    slow_motion_burst = slow_motion_burst,
    vehicle_jump = vehicle_jump,
    confused_inputs = confused_inputs,
    cinematic_burst = cinematic_burst,
    wrecking_punch = wrecking_punch,
    tsunami_surge = tsunami_surge
}

RegisterNetEvent('chaos_mode:runEvent', function(eventName, data)
    local eventNames = {}
    if type(eventName) == 'table' then
        eventNames = eventName
    elseif type(eventName) == 'string' then
        eventNames = { eventName }
    end

    if #eventNames == 0 then
        notify('Unknown chaos payload received')
        return
    end

    local displayNames = {}
    local skippedEvents = {}

    for _, currentEventName in ipairs(eventNames) do
        local meta = getEffectMeta(currentEventName, data)
        local effectKey = meta and meta.effectKey or currentEventName
        if not activeTimedEffects[effectKey] then
            local handler = eventHandlers[currentEventName]
            if handler then
                local ok, err = pcall(handler, data)
                if ok then
                    table.insert(displayNames, currentEventName)
                    if meta and meta.durationMs then
                        activeTimedEffects[effectKey] = true
                        CreateThread(function()
                            Wait(meta.durationMs)
                            activeTimedEffects[effectKey] = false
                        end)
                    end
                else
                    notify(('Chaos handler failed: %s'):format(currentEventName))
                    print(('[chaos_mode] Handler error for %s: %s'):format(currentEventName, tostring(err)))
                end
            else
                notify(('Unknown chaos event: %s'):format(currentEventName))
            end
        else
            table.insert(skippedEvents, currentEventName)
        end
    end

    if #displayNames > 0 then
        local maxDuration = 0
        for _, dispatchedEventName in ipairs(displayNames) do
            local meta = getEffectMeta(dispatchedEventName, data)
            if meta and meta.durationMs and meta.durationMs > maxDuration then
                maxDuration = meta.durationMs
            end
        end

        if #displayNames > 1 then
            local durationText = maxDuration > 0 and (' for %ds'):format(math.floor(maxDuration / 1000)) or ''
            notify(('Combo chaos: %s + %s%s'):format(displayNames[1], displayNames[2], durationText))
        end
    end

    if #skippedEvents > 0 then
        notify(('Skipped overlapping effect(s): %s'):format(table.concat(skippedEvents, ', ')))
    end
end)

RegisterNetEvent('chaos_mode:menuData', function(payload)
    SendNUIMessage({
        action = 'setData',
        events = payload.events or {},
        players = payload.players or {}
    })
end)

RegisterNUICallback('close', function(_, cb)
    closeChaosMenu()
    cb({ ok = true })
end)

RegisterNUICallback('triggerEvent', function(data, cb)
    TriggerServerEvent('chaos_mode:triggerSelectedEvent', {
        eventName = data.eventName,
        targetType = data.targetType,
        players = data.players or {}
    })
    cb({ ok = true })
end)

RegisterCommand('chaosmenu', function()
    if menuOpen then
        closeChaosMenu()
    else
        openChaosMenu()
    end
end, false)

RegisterKeyMapping('chaosmenu', 'Open chaos event menu', 'keyboard', Config.Menu.OpenKey)

CreateThread(function()
    while true do
        if menuOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    resetChaosState()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    closeChaosMenu()
    resetChaosState()
end)
