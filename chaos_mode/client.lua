local hostilePeds = {}
local lowGravityActive = false
local activeTimedEffects = {}
local menuOpen = false
local trollMenuOpen = false
local lastDriverRadioStation = nil
local lastRadioSyncSentAt = 0
local eventToggleState = {}

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('~o~CHAOS~s~: %s'):format(message))
    EndTextCommandThefeedPostTicker(false, true)
end

local function setMenuState(isOpen)
    menuOpen = isOpen
    trollMenuOpen = false
    SetNuiFocus(isOpen, isOpen)
    SendNUIMessage({
        action = 'setMode',
        mode = 'chaos'
    })
    SendNUIMessage({
        action = 'setVisible',
        visible = isOpen
    })
end

local function setTrollMenuState(isOpen)
    trollMenuOpen = isOpen
    menuOpen = false
    SetNuiFocus(isOpen, isOpen)
    SendNUIMessage({
        action = 'setMode',
        mode = 'troll'
    })
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

local function openTrollMenu()
    TriggerServerEvent('chaos_mode:requestMenuData')
    setTrollMenuState(true)
end

local function closeTrollMenu()
    setTrollMenuState(false)
end


local function requestHudState()
    TriggerServerEvent('chaos_mode:requestHudState')
end

CreateThread(function()
    Wait(1500)
    requestHudState()
end)

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


local function meteor_shower()
    local coords = GetEntityCoords(PlayerPedId())
    notify('Meteor shower incoming!')
    for i = 1, 12 do
        local offset = vec3(math.random(-35, 35), math.random(-35, 35), math.random(18, 35))
        AddExplosion(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z, 29, 0.7, true, false, 1.0)
        Wait(120)
    end
end

local function lightning_strike()
    local coords = GetEntityCoords(PlayerPedId())
    notify('Lightning strike!')
    SetWeatherTypeOvertimePersist('THUNDER', 1.5)
    AddExplosion(coords.x + math.random(-4, 4), coords.y + math.random(-4, 4), coords.z, 38, 0.0, true, false, 0.0)
end

local function earthquake_wave()
    if withTimedEffect('earthquake_wave', 10000,
        function() notify('Earthquake wave for 10s') end,
        function() ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.1) end,
        function() StopGameplayCamShaking(true) end,
        400
    ) then end
end

local function volcanic_smog()
    if withTimedEffect('volcanic_smog', 18000,
        function()
            notify('Volcanic smog chokes the skyline for 18s')
            SetTimecycleModifier('NG_blackout')
            SetTimecycleModifierStrength(0.9)
        end,
        nil,
        function() ClearTimecycleModifier() end
    ) then end
end

local function hailstorm()
    notify('Hailstorm! Random impacts incoming')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _ = 1, 10 do
        ApplyDamageToPed(ped, math.random(1, 3), false)
        AddExplosion(coords.x + math.random(-10, 10), coords.y + math.random(-10, 10), coords.z + 6.0, 0, 0.0, true, false, 0.0)
        Wait(100)
    end
end

local function wildfire_burst()
    notify('Wildfire burst!')
    local coords = GetEntityCoords(PlayerPedId())
    for i = 1, 8 do
        StartScriptFire(coords.x + math.random(-14, 14), coords.y + math.random(-14, 14), coords.z, 25, true)
    end
end

local function tornado_twist()
    if withTimedEffect('tornado_twist', 10000,
        function() notify('Tornado twist for 10s') end,
        function()
            local ped = PlayerPedId()
            ApplyForceToEntity(ped, 1, math.random(-30, 30) * 0.02, math.random(-30, 30) * 0.02, 1.7, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
        end,
        nil,
        200
    ) then end
end

local function sandstorm()
    if withTimedEffect('sandstorm', 12000,
        function()
            notify('Sandstorm! Visibility nuked for 12s')
            SetTimecycleModifier('spectator5')
            SetTimecycleModifierStrength(1.0)
        end,
        nil,
        function() ClearTimecycleModifier() end
    ) then end
end

local function aftershock()
    notify('Aftershock!')
    SetPedToRagdoll(PlayerPedId(), 1800, 1800, 0, false, false, false)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.9)
    CreateThread(function()
        Wait(1500)
        StopGameplayCamShaking(true)
    end)
end

local function flash_flood()
    if withTimedEffect('flash_flood', 12000,
        function()
            notify('Flash flood surge for 12s')
            SetWavesIntensity(3.2)
            SetRainLevel(1.0)
        end,
        nil,
        function()
            SetWavesIntensity(1.0)
            SetRainLevel(0.0)
        end
    ) then end
end

local function lava_floor()
    if withTimedEffect('lava_floor', 12000,
        function()
            notify('Floor is lava for 12s!')
            SetArtificialLightsState(true)
        end,
        function()
            local ped = PlayerPedId()
            if IsPedOnFoot(ped) then
                ApplyDamageToPed(ped, 2, false)
            end
        end,
        function() SetArtificialLightsState(false) end,
        700
    ) then end
end

local function comet_tail()
    notify('Comet tail whiplash!')
    local ped = PlayerPedId()
    ApplyForceToEntity(ped, 1, 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end

local function sharknado_warning()
    notify('Sharknado warning: seek higher ground!')
    SetWavesIntensity(3.8)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.4)
    CreateThread(function()
        Wait(8000)
        SetWavesIntensity(1.0)
        StopGameplayCamShaking(true)
    end)
end

local function panic_evacuate()
    notify('Panic evacuation! NPCs running wild')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, npc in ipairs(GetGamePool('CPed')) do
        if npc ~= ped and not IsPedAPlayer(npc) then
            local npcCoords = GetEntityCoords(npc)
            if #(coords - npcCoords) < 60.0 then
                TaskReactAndFleePed(npc, ped)
            end
        end
    end
end

local function solar_flare()
    if withTimedEffect('solar_flare', 8000,
        function()
            notify('Solar flare! Blinded for 8s')
            TriggerScreenblurFadeIn(300)
            ShakeGameplayCam('HAND_SHAKE', 0.35)
        end,
        nil,
        function()
            TriggerScreenblurFadeOut(300)
            StopGameplayCamShaking(true)
        end
    ) then end
end

local function gravity_flip()
    notify('Gravity flip!')
    SetPedToRagdoll(PlayerPedId(), 2500, 2500, 0, false, false, false)
    ApplyForceToEntity(PlayerPedId(), 1, 0.0, 0.0, 12.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end

local function adhd_horns()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Horn chaos skipped: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Horn chaos engaged!')
    for _ = 1, 8 do
        StartVehicleHorn(vehicle, 300, `HELDDOWN`, false)
        Wait(140)
    end
end

local function ufo_blink()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    notify('UFO blink abduct... almost')
    local destination = coords + vec3(math.random(-120, 120), math.random(-120, 120), math.random(10, 22))
    SetEntityCoordsNoOffset(ped, destination.x, destination.y, destination.z, false, false, false)
end

local function loot_rain(data)
    notify('Loot rain! Props falling from the sky')
    local ped = PlayerPedId()
    local baseCoords = GetEntityCoords(ped)
    local spawned = {}
    for i = 1, 15 do
        local model = data.models[math.random(1, #data.models)]
        if loadModel(model) then
            local object = CreateObject(model, baseCoords.x + math.random(-12, 12), baseCoords.y + math.random(-12, 12), baseCoords.z + math.random(8, 22), true, true, false)
            if DoesEntityExist(object) then
                table.insert(spawned, object)
            end
            SetModelAsNoLongerNeeded(model)
        end
    end
    cleanObjectsAfter(spawned, data.cleanupMs)
end

local function confetti_bomb()
    notify('Confetti bomb! (explosions, but make it festive)')
    local coords = GetEntityCoords(PlayerPedId())
    for _ = 1, 14 do
        AddExplosion(coords.x + math.random(-16, 16), coords.y + math.random(-16, 16), coords.z + 0.3, 0, 0.0, true, false, 0.0)
    end
end

local function npc_moshpit()
    notify('NPC moshpit formed!')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, npc in ipairs(GetGamePool('CPed')) do
        if npc ~= ped and not IsPedAPlayer(npc) then
            local npcCoords = GetEntityCoords(npc)
            if #(coords - npcCoords) < 35.0 then
                TaskCombatPed(npc, ped, 0, 16)
            end
        end
    end
end

local function traffic_magnet()
    notify('Traffic magnet! Vehicles pulled in')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(coords - vehicleCoords) < 70.0 then
            local dir = coords - vehicleCoords
            ApplyForceToEntity(vehicle, 1, dir.x * 0.05, dir.y * 0.05, 0.2, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
        end
    end
end

local function yeet_vehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Yeet failed: not in a vehicle')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    notify('Vehicle YEET!')
    ApplyForceToEntity(vehicle, 1, 0.0, 0.0, 12.0, 2.5, 0.0, 0.0, 0, false, true, true, false, true)
end

local function reverse_daynight()
    local hour = GetClockHours()
    local flipped = (hour + 12) % 24
    notify(('Time inverted to %02d:00'):format(flipped))
    NetworkOverrideClockTime(flipped, 0, 0)
end

local function glitch_scream()
    if withTimedEffect('glitch_scream', 9000,
        function()
            notify('Glitch scream mode for 9s')
            ShakeGameplayCam('JOLT_SHAKE', 0.9)
        end,
        function()
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
        end,
        function() StopGameplayCamShaking(true) end,
        0
    ) then end
end

local function dance_fever()
    if withTimedEffect('dance_fever', 10000,
        function()
            notify('Dance fever for 10s')
            RequestAnimSet('move_m@hurry@a')
            while not HasAnimSetLoaded('move_m@hurry@a') do
                Wait(0)
            end
            SetPedMovementClipset(PlayerPedId(), 'move_m@hurry@a', 0.25)
        end,
        nil,
        function() ResetPedMovementClipset(PlayerPedId(), 0.5) end
    ) then end
end

local function sticky_bombs_party()
    notify('Sticky bombs party!')
    GiveWeaponToPed(PlayerPedId(), `WEAPON_STICKYBOMB`, 10, false, true)
end

local function blimp_shadow()
    notify('Blimp shadow incoming... camera drama!')
    SetGameplayCamRelativeHeading(GetGameplayCamRelativeHeading() + math.random(-45, 45))
    SetGameplayCamRelativePitch(GetGameplayCamRelativePitch() + math.random(-10, 10), 1.0)
end

local function rogue_wave()
    if withTimedEffect('rogue_wave', 10000,
        function()
            notify('Rogue wave slams the map for 10s')
            SetWavesIntensity(3.5)
            SetWindSpeed(8.0)
        end,
        function() ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.25) end,
        function()
            SetWavesIntensity(1.0)
            SetWindSpeed(0.0)
            StopGameplayCamShaking(true)
        end,
        500
    ) then end
end

local function apocalypse_sky()
    if withTimedEffect('apocalypse_sky', 18000,
        function()
            notify('Apocalypse sky event for 18s')
            SetWeatherTypeOvertimePersist('THUNDER', 2.0)
            SetTimecycleModifier('REDMIST_blend')
            SetTimecycleModifierStrength(0.7)
        end,
        nil,
        function()
            ClearWeatherTypePersist()
            ClearOverrideWeather()
            ClearTimecycleModifier()
        end
    ) then end
end


local function singularity_vortex()
    if withTimedEffect('singularity_vortex', 12000,
        function()
            notify('Singularity vortex: reality is collapsing!')
            ShakeGameplayCam('SKY_DIVING_SHAKE', 0.65)
            AnimpostfxPlay('FocusIn', 0, true)
        end,
        function()
            local playerPed = PlayerPedId()
            local center = GetEntityCoords(playerPed)
            local nearbyVehicles = GetGamePool('CVehicle')
            local maxPullDistance = 85.0

            for i = 1, #nearbyVehicles do
                local entity = nearbyVehicles[i]
                if DoesEntityExist(entity) then
                    local entityCoords = GetEntityCoords(entity)
                    local delta = center - entityCoords
                    local distance = #(delta)
                    if distance > 4.0 and distance < maxPullDistance then
                        local pullStrength = math.max(7.5, ((maxPullDistance - distance) / maxPullDistance) * 32.0)
                        local nx = delta.x / distance
                        local ny = delta.y / distance
                        local nz = ((delta.z + 1.2) / distance)
                        ApplyForceToEntity(entity, 1, nx * pullStrength, ny * pullStrength, nz * (pullStrength * 0.75), 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    end
                end
            end

            local nearbyPeds = GetGamePool('CPed')
            for i = 1, #nearbyPeds do
                local ped = nearbyPeds[i]
                if ped ~= playerPed and DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local delta = center - pedCoords
                    local distance = #(delta)
                    if distance > 2.5 and distance < 55.0 then
                        local nx = delta.x / distance
                        local ny = delta.y / distance
                        local nz = ((delta.z + 0.8) / distance)
                        local pullStrength = math.max(4.0, ((55.0 - distance) / 55.0) * 14.0)
                        ApplyForceToEntity(ped, 1, nx * pullStrength, ny * pullStrength, nz * (pullStrength * 0.55), 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    end
                end
            end
        end,
        function()
            AnimpostfxStop('FocusIn')
            StopGameplayCamShaking(true)
            notify('Singularity stabilized... for now.')
        end,
        100
    ) then end
end

local function combatModifierEvent(effectKey, label, durationMs, onTick)
    if withTimedEffect(effectKey, durationMs,
        function()
            notify(label)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.15)
            SetPedCanRagdoll(PlayerPedId(), true)
        end,
        onTick,
        function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end,
        150
    ) then end
end

local function perfect_dodge_matrix()
    combatModifierEvent('perfect_dodge_matrix', 'Perfect Dodge Matrix online', 14000, function()
        if IsPedRunning(PlayerPedId()) then
            SetTimeScale(0.92)
        else
            SetTimeScale(1.0)
        end
    end)
    CreateThread(function() Wait(14000) SetTimeScale(1.0) end)
end

local function parry_power() combatModifierEvent('parry_power', 'Parry Power activated', 14000) end
local function charged_branching() combatModifierEvent('charged_branching', 'Charged Branching active', 14000) end
local function armor_breaker() combatModifierEvent('armor_breaker', 'Armor Breaker online', 15000) end
local function hazard_kicker() combatModifierEvent('hazard_kicker', 'Hazard Kicker active', 12000) end
local function air_combo_mania() combatModifierEvent('air_combo_mania', 'Air Combo Mania launched', 12000) end
local function momentum_strike() combatModifierEvent('momentum_strike', 'Momentum Strike engaged', 12000) end
local function overdrive_mode()
    combatModifierEvent('overdrive_mode', 'Overdrive Mode: high risk', 15000, function()
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        if health > 120 and math.random(1, 5) == 1 then
            SetEntityHealth(ped, health - 1)
        end
    end)
end
local function finisher_window() combatModifierEvent('finisher_window', 'Finisher Window open', 12000) end
local function morale_break() combatModifierEvent('morale_break', 'Morale Break triggered', 10000) end
local function shield_reactor() combatModifierEvent('shield_reactor', 'Shield Reactor primed', 12000) end
local function stance_shift() combatModifierEvent('stance_shift', 'Stance Shift rotating', 15000) end
local function clash_counter() combatModifierEvent('clash_counter', 'Clash Counter enabled', 10000) end
local function trap_spree() combatModifierEvent('trap_spree', 'Trap Spree deployed', 12000) end
local function combat_weather()
    weatherShift(({'THUNDER', 'FOGGY', 'RAIN', 'OVERCAST'})[math.random(1, 4)])
    combatModifierEvent('combat_weather', 'Combat Weather turbulence', 15000)
end
local function last_stand() combatModifierEvent('last_stand', 'Last Stand ready', 20000) end
local function pack_tactics() combatModifierEvent('pack_tactics', 'Pack Tactics pressure', 10000) end
local function limb_cracker() combatModifierEvent('limb_cracker', 'Limb Cracker precision', 12000) end
local function arena_objectives() combatModifierEvent('arena_objectives', 'Arena Objectives live', 25000) end
local function style_rank_rush() combatModifierEvent('style_rank_rush', 'Style Rank Rush active', 16000) end

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
    lastDriverRadioStation = nil

    for key in pairs(activeTimedEffects) do
        activeTimedEffects[key] = false
    end
end


local function shouldSyncVehicleRadio()
    return Config.VehicleRadioSyncEnabled ~= false
end

local function syncVehicleRadioWithDriver()
    if not shouldSyncVehicleRadio() then
        return
    end

    local intervalMs = tonumber(Config.VehicleRadioSyncIntervalMs) or 1200
    if intervalMs < 250 then
        intervalMs = 250
    end

    local now = GetGameTimer()
    if now - lastRadioSyncSentAt < intervalMs then
        return
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return
    end

    local stationName = GetPlayerRadioStationName()
    if not stationName or stationName == '' then
        return
    end

    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    if vehicleNetId == 0 then
        return
    end

    lastRadioSyncSentAt = now
    TriggerServerEvent('chaos_mode:syncVehicleRadio', {
        vehicleNetId = vehicleNetId,
        stationName = stationName
    })
end

CreateThread(function()
    while true do
        syncVehicleRadioWithDriver()
        Wait(250)
    end
end)

RegisterNetEvent('chaos_mode:applyVehicleRadioSync', function(payload)
    if not shouldSyncVehicleRadio() then
        return
    end

    if type(payload) ~= 'table' then
        return
    end

    local localServerId = GetPlayerServerId(PlayerId())
    if tonumber(payload.source) == localServerId then
        return
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local incomingVehicleNetId = tonumber(payload.vehicleNetId)
    if not incomingVehicleNetId or incomingVehicleNetId <= 0 then
        return
    end

    if NetworkGetNetworkIdFromEntity(vehicle) ~= incomingVehicleNetId then
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) == ped then
        return
    end

    local stationName = tostring(payload.stationName or '')
    if stationName == '' or stationName == lastDriverRadioStation then
        return
    end

    SetVehRadioStation(vehicle, stationName)
    lastDriverRadioStation = stationName
end)

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
    tsunami_surge = tsunami_surge,
    meteor_shower = meteor_shower,
    lightning_strike = lightning_strike,
    earthquake_wave = earthquake_wave,
    volcanic_smog = volcanic_smog,
    hailstorm = hailstorm,
    wildfire_burst = wildfire_burst,
    tornado_twist = tornado_twist,
    sandstorm = sandstorm,
    aftershock = aftershock,
    flash_flood = flash_flood,
    lava_floor = lava_floor,
    comet_tail = comet_tail,
    sharknado_warning = sharknado_warning,
    panic_evacuate = panic_evacuate,
    solar_flare = solar_flare,
    gravity_flip = gravity_flip,
    adhd_horns = adhd_horns,
    ufo_blink = ufo_blink,
    loot_rain = loot_rain,
    confetti_bomb = confetti_bomb,
    npc_moshpit = npc_moshpit,
    traffic_magnet = traffic_magnet,
    yeet_vehicle = yeet_vehicle,
    reverse_daynight = reverse_daynight,
    glitch_scream = glitch_scream,
    dance_fever = dance_fever,
    sticky_bombs_party = sticky_bombs_party,
    blimp_shadow = blimp_shadow,
    rogue_wave = rogue_wave,
    apocalypse_sky = apocalypse_sky,
    singularity_vortex = singularity_vortex,
    banana_peel_panic = slippery_feet,
    disco_inferno = dance_fever,
    yoink_gun_lottery = random_weapon,
    quantum_seatbelt = vehicle_jump,
    gremlin_mechanics = vehicle_malfunction,
    bass_boosted_horns = adhd_horns,
    confetti_overdrive = confetti_bomb,
    tiny_tornado = tornado_twist,
    pogo_protocol = trampoline_steps,
    rubber_band_lag = teleport_micro_shuffle,
    cinema_quake = cinematic_burst,
    gravity_io = gravity_flip,
    meteor_snack_attack = meteor_shower,
    panic_pinata = npc_panic,
    fog_of_memes = chaos_fog,
    nightclub_blackout = blackout_burst,
    bouncy_bullets = explosive_ammo_burst,
    blizzard_of_cones = spawnRandomObjects,
    npc_karaoke = npc_moshpit,
    car_sneeze = yeet_vehicle,
    sandwich_timewarp = random_time_shift,
    screaming_sky = glitch_scream,
    reverse_moshpit = traffic_magnet,
    loot_pinata = loot_rain,
    cursed_zoomies = speed_burst,
    fishtank_mode = tsunami_surge,
    honkpocalypse = horn_boost,
    sticky_floor_lite = freeze_burst,
    dancequake = dance_fever,
    brainlag_controls = confused_inputs,
    perfect_dodge_matrix = perfect_dodge_matrix,
    parry_power = parry_power,
    charged_branching = charged_branching,
    armor_breaker = armor_breaker,
    hazard_kicker = hazard_kicker,
    air_combo_mania = air_combo_mania,
    momentum_strike = momentum_strike,
    overdrive_mode = overdrive_mode,
    finisher_window = finisher_window,
    morale_break = morale_break,
    shield_reactor = shield_reactor,
    stance_shift = stance_shift,
    clash_counter = clash_counter,
    trap_spree = trap_spree,
    combat_weather = combat_weather,
    last_stand = last_stand,
    pack_tactics = pack_tactics,
    limb_cracker = limb_cracker,
    arena_objectives = arena_objectives,
    style_rank_rush = style_rank_rush
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


RegisterNetEvent('chaos_mode:updateHud', function(payload)
    payload = payload or {}
    SendNUIMessage({
        action = 'setHudData',
        secondsRemaining = payload.secondsRemaining or 0,
        currentEvent = payload.currentEvent or 'Waiting for next event',
        history = payload.history or {}
    })
end)

RegisterNetEvent('chaos_mode:menuData', function(payload)
    eventToggleState = payload.eventToggles or {}
    SendNUIMessage({
        action = 'setData',
        events = payload.events or {},
        players = payload.players or {},
        trollActions = payload.trollActions or {},
        trollActionMeta = payload.trollActionMeta or {},
        eventMeta = payload.eventMeta or {},
        eventToggles = eventToggleState
    })
end)

RegisterNetEvent('chaos_mode:eventTogglesUpdated', function(toggleMap)
    eventToggleState = type(toggleMap) == 'table' and toggleMap or {}
    SendNUIMessage({
        action = 'setEventToggles',
        eventToggles = eventToggleState
    })
end)

local trollHandlers = {
    launch_up = function()
        notify('TROLL: launched')
        ApplyForceToEntity(PlayerPedId(), 1, 0.0, 0.0, 9.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    end,
    spin_out = function()
        notify('TROLL: spin out')
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetEntityAngularVelocity(vehicle, 0.0, 0.0, 6.0)
        else
            SetEntityHeading(ped, GetEntityHeading(ped) + 180.0)
        end
    end,
    ragdoll_drop = function()
        notify('TROLL: ragdoll')
        SetPedToRagdoll(PlayerPedId(), 4500, 4500, 0, false, false, false)
    end,
    ignite = function()
        notify('TROLL: surprise fire')
        StartEntityFire(PlayerPedId())
        CreateThread(function()
            Wait(3000)
            StopEntityFire(PlayerPedId())
        end)
    end,
    strip_weapon = function()
        notify('TROLL: weapon confiscated')
        RemoveAllPedWeapons(PlayerPedId(), true)
    end,
    drain_armor = function()
        notify('TROLL: armor drained')
        SetPedArmour(PlayerPedId(), 0)
    end,
    blur_vision = function()
        withTimedEffect('troll_blur_vision', 10000,
            function()
                notify('TROLL: blurry vision')
                TriggerScreenblurFadeIn(400)
            end,
            nil,
            function() TriggerScreenblurFadeOut(400) end
        )
    end,
    freeze_feet = function()
        withTimedEffect('troll_freeze_feet', 4000,
            function()
                notify('TROLL: frozen in place')
                FreezeEntityPosition(PlayerPedId(), true)
            end,
            nil,
            function() FreezeEntityPosition(PlayerPedId(), false) end
        )
    end,
    drunk_walk = function()
        withTimedEffect('troll_drunk_walk', 10000,
            function()
                notify('TROLL: drunk movement')
                RequestAnimSet('move_m@drunk@verydrunk')
                while not HasAnimSetLoaded('move_m@drunk@verydrunk') do
                    Wait(0)
                end
                SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 0.2)
            end,
            nil,
            function() ResetPedMovementClipset(PlayerPedId(), 0.5) end
        )
    end,
    fake_explosion = function()
        notify('TROLL: boom nearby')
        local coords = GetEntityCoords(PlayerPedId())
        AddExplosion(coords.x + 4.0, coords.y + 2.0, coords.z, 2, 0.0, true, false, 0.0)
    end,
    seat_shuffle = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            notify('TROLL: seat shuffle')
            TaskShuffleToNextVehicleSeat(ped, GetVehiclePedIsIn(ped, false))
        else
            notify('TROLL: seat shuffle missed')
        end
    end,
    stall_engine = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            notify('TROLL: engine stalled')
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleEngineOn(vehicle, false, true, true)
            CreateThread(function()
                Wait(3000)
                if DoesEntityExist(vehicle) then
                    SetVehicleEngineOn(vehicle, true, true, false)
                end
            end)
        else
            notify('TROLL: engine stall missed')
        end
    end,
    burst_tires = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            notify('TROLL: tires burst')
            local vehicle = GetVehiclePedIsIn(ped, false)
            for i = 0, 5 do
                SetVehicleTyreBurst(vehicle, i, true, 1000.0)
            end
        else
            notify('TROLL: tire burst missed')
        end
    end,
    teleport_back = function()
        notify('TROLL: teleported back')
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(ped)
        SetEntityCoordsNoOffset(ped, coords.x - (forward.x * 12.0), coords.y - (forward.y * 12.0), coords.z, false, false, false)
    end,
    reverse_controls = function()
        withTimedEffect('troll_reverse_controls', 9000,
            function() notify('TROLL: controls reversed') end,
            function()
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                if IsDisabledControlPressed(0, 32) then
                    local ped = PlayerPedId()
                    local forward = GetEntityForwardVector(ped)
                    ApplyForceToEntity(ped, 1, -forward.x * 1.8, -forward.y * 1.8, 0.15, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                end
            end,
            nil,
            0
        )
    end,
    moonwalk = function()
        withTimedEffect('troll_moonwalk', 9000,
            function()
                notify('TROLL: moonwalk curse')
                RequestAnimSet('move_m@gangster@var_e')
                while not HasAnimSetLoaded('move_m@gangster@var_e') do
                    Wait(0)
                end
                SetPedMovementClipset(PlayerPedId(), 'move_m@gangster@var_e', 0.2)
            end,
            nil,
            function() ResetPedMovementClipset(PlayerPedId(), 0.5) end
        )
    end,
    random_trip = function()
        notify('TROLL: random trip')
        SetPedToRagdoll(PlayerPedId(), 2500, 2500, 0, false, false, false)
    end,
    invisible_brief = function()
        withTimedEffect('troll_invisible_brief', 6000,
            function()
                notify('TROLL: now you see me')
                SetEntityVisible(PlayerPedId(), false, false)
            end,
            nil,
            function() SetEntityVisible(PlayerPedId(), true, false) end
        )
    end,
    camera_whiplash = function()
        withTimedEffect('troll_camera_whiplash', 7000,
            function()
                notify('TROLL: camera whiplash')
                ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.0)
                TriggerScreenblurFadeIn(250)
            end,
            nil,
            function()
                StopGameplayCamShaking(true)
                TriggerScreenblurFadeOut(250)
            end
        )
    end,
    weapon_jam = function()
        withTimedEffect('troll_weapon_jam', 7000,
            function() notify('TROLL: weapon jam') end,
            function()
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
            end,
            nil,
            0
        )
    end,
    yeet_sideways = function()
        notify('TROLL: yeeted sideways')
        local ped = PlayerPedId()
        local right = GetEntityRightVector(ped)
        ApplyForceToEntity(ped, 1, right.x * 8.0, right.y * 8.0, 2.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    end,
    clown_horn = function()
        withTimedEffect('troll_clown_horn', 5000,
            function() notify('TROLL: clown horn spam') end,
            function()
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    StartVehicleHorn(vehicle, 120, `HELDDOWN`, false)
                end
            end,
            nil,
            800
        )
    end,
    sudden_brake = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            notify('TROLL: sudden brake')
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleForwardSpeed(vehicle, 0.0)
        else
            notify('TROLL: sudden brake missed')
        end
    end
}

RegisterNetEvent('chaos_mode:runTrollAction', function(actionName)
    local handler = trollHandlers[actionName]
    if not handler then
        notify(('Unknown troll action: %s'):format(tostring(actionName)))
        return
    end

    local ok, err = pcall(handler)
    if not ok then
        notify('Troll action failed')
        print(('[chaos_mode] Troll action error for %s: %s'):format(tostring(actionName), tostring(err)))
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeChaosMenu()
    closeTrollMenu()
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

RegisterNUICallback('triggerTrollAction', function(data, cb)
    TriggerServerEvent('chaos_mode:triggerSelectedTrollAction', {
        actionName = data.actionName,
        players = data.players or {}
    })
    cb({ ok = true })
end)

RegisterNUICallback('setEventToggle', function(data, cb)
    TriggerServerEvent('chaos_mode:setEventToggle', {
        eventName = data.eventName,
        enabled = data.enabled == true
    })
    cb({ ok = true })
end)

RegisterCommand('chaosmenu', function()
    if menuOpen or trollMenuOpen then
        closeChaosMenu()
        closeTrollMenu()
    else
        openChaosMenu()
    end
end, false)

RegisterCommand('trollmenu', function()
    if trollMenuOpen or menuOpen then
        closeChaosMenu()
        closeTrollMenu()
    else
        openTrollMenu()
    end
end, false)

RegisterKeyMapping('chaosmenu', 'Open chaos event menu', 'keyboard', Config.Menu.OpenKey)
RegisterKeyMapping('trollmenu', 'Open secret troll menu', 'keyboard', 'NUMPAD2')

CreateThread(function()
    while true do
        if menuOpen or trollMenuOpen then
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
