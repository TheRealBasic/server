Config = {}

Config.Enabled = true
Config.MinIntervalMs = 30000
Config.MaxIntervalMs = 30000
Config.HostileNpcDurationMs = 30000
Config.ObjectCleanupMs = 30000
Config.VehicleRadioSyncEnabled = true
Config.VehicleRadioSyncIntervalMs = 1200

Config.ComboEnabled = true
Config.ComboChance = 30 -- percent chance to trigger two events at once
Config.EventRecentHistoryWindow = 6 -- number of recently triggered events used to lower repeat odds
Config.EventWeights = {
    -- Optional per-event base weights.
    -- Omitted events default to weight 1.0.
    -- Set below 1.0 to make an event rarer, or above 1.0 to make it more common.
    -- Example:
    -- tsunami_surge = 0.5,
    -- random_weapon = 1.5
}

Config.TrollActionMeta = {
    launch_up = {
        label = 'Launch Up',
        description = 'Throws the player straight into the air.'
    },
    spin_out = {
        label = 'Spin Out',
        description = 'Applies a sudden spin force and disorients movement.',
        durationMs = 5000
    },
    ragdoll_drop = {
        label = 'Ragdoll Drop',
        description = 'Forces the player into a ragdoll fall.'
    },
    ignite = {
        label = 'Ignite',
        description = 'Sets the player on fire for a short burst.',
        durationMs = 5000
    },
    strip_weapon = {
        label = 'Strip Weapon',
        description = 'Removes the currently equipped weapon.'
    },
    drain_armor = {
        label = 'Drain Armor',
        description = 'Clears all armor from the player.'
    },
    blur_vision = {
        label = 'Blur Vision',
        description = 'Applies a heavy blur visual effect.',
        durationMs = 8000
    },
    freeze_feet = {
        label = 'Freeze Feet',
        description = 'Temporarily roots the player in place.',
        durationMs = 5000
    },
    drunk_walk = {
        label = 'Drunk Walk',
        description = 'Makes movement unstable and sloppy.',
        durationMs = 10000
    },
    fake_explosion = {
        label = 'Fake Explosion',
        description = 'Plays an explosion effect near the player without lethal damage.'
    },
    seat_shuffle = {
        label = 'Seat Shuffle',
        description = 'Moves the player to another available vehicle seat.'
    },
    stall_engine = {
        label = 'Stall Engine',
        description = 'Kills the engine of the current vehicle.'
    },
    burst_tires = {
        label = 'Burst Tires',
        description = 'Pops every tire on the current vehicle.'
    },
    teleport_back = {
        label = 'Teleport Back',
        description = 'Snaps the player back to a previous position.'
    },
    reverse_controls = {
        label = 'Reverse Controls',
        description = 'Inverts movement controls for maximum confusion.',
        durationMs = 10000
    },
    moonwalk = {
        label = 'Moonwalk Curse',
        description = 'Forces a slick backwards movement style.',
        durationMs = 9000
    },
    random_trip = {
        label = 'Random Trip',
        description = 'Makes the player unexpectedly faceplant.'
    },
    invisible_brief = {
        label = 'Invisible Brief',
        description = 'Turns the player invisible for a short prank.',
        durationMs = 6000
    },
    camera_whiplash = {
        label = 'Camera Whiplash',
        description = 'Violent camera shake and blur combo.',
        durationMs = 7000
    },
    weapon_jam = {
        label = 'Weapon Jam',
        description = 'Temporarily blocks firing controls.',
        durationMs = 7000
    },
    yeet_sideways = {
        label = 'Yeet Sideways',
        description = 'Throws the player hard to one side.'
    },
    clown_horn = {
        label = 'Clown Horn',
        description = 'Honks repeatedly around the target for chaos.',
        durationMs = 5000
    },
    sudden_brake = {
        label = 'Sudden Brake',
        description = 'Slams the current vehicle to a stop.'
    }
}

Config.EventPool = {
    'weather_shift',
    'hostile_npcs',
    'spawn_random_objects',
    'low_gravity_burst',
    'ragdoll_wave',
    'drunk_vision',
    'speed_burst',
    'super_jump_burst',
    'explosive_ammo_burst',
    'explosive_melee_burst',
    'fire_ammo_burst',
    'rapid_fire_burst',
    'random_wanted_level',
    'armor_refill',
    'health_boost',
    'health_drain',
    'teleport_shuffle',
    'blackout_burst',
    'random_time_shift',
    'camera_shake_burst',
    'random_weapon',
    'vehicle_slip',
    'vehicle_boost',
    'random_screen_filter',
    'no_hud_burst',
    'moon_jump_mania',
    'chaos_fog',
    'rainbow_car',
    'vehicle_malfunction',
    'eject_from_vehicle',
    'brake_failure',
    'horn_boost',
    'random_door_open',
    'tire_burst_all',
    'ignite_player_brief',
    'slippery_feet',
    'forced_melee',
    'disable_aim',
    'butterfingers',
    'ammo_drain',
    'fake_cops',
    'pacifist_mode',
    'screen_blur',
    'pixel_world',
    'random_camera_zoom',
    'drunk_walk',
    'npc_panic',
    'explosion_ring',
    'trampoline_steps',
    'teleport_micro_shuffle',
    'freeze_burst',
    'slow_motion_burst',
    'vehicle_jump',
    'confused_inputs',
    'cinematic_burst',
    'wrecking_punch',
    'tsunami_surge',
    'meteor_shower',
    'lightning_strike',
    'earthquake_wave',
    'volcanic_smog',
    'hailstorm',
    'wildfire_burst',
    'tornado_twist',
    'sandstorm',
    'aftershock',
    'flash_flood',
    'lava_floor',
    'comet_tail',
    'sharknado_warning',
    'panic_evacuate',
    'solar_flare',
    'gravity_flip',
    'adhd_horns',
    'ufo_blink',
    'loot_rain',
    'confetti_bomb',
    'npc_moshpit',
    'traffic_magnet',
    'yeet_vehicle',
    'reverse_daynight',
    'glitch_scream',
    'dance_fever',
    'sticky_bombs_party',
    'blimp_shadow',
    'rogue_wave',
    'apocalypse_sky',
    'banana_peel_panic',
    'disco_inferno',
    'yoink_gun_lottery',
    'quantum_seatbelt',
    'gremlin_mechanics',
    'bass_boosted_horns',
    'confetti_overdrive',
    'tiny_tornado',
    'pogo_protocol',
    'rubber_band_lag',
    'cinema_quake',
    'gravity_io',
    'meteor_snack_attack',
    'panic_pinata',
    'fog_of_memes',
    'nightclub_blackout',
    'bouncy_bullets',
    'blizzard_of_cones',
    'npc_karaoke',
    'car_sneeze',
    'sandwich_timewarp',
    'screaming_sky',
    'reverse_moshpit',
    'loot_pinata',
    'cursed_zoomies',
    'fishtank_mode',
    'honkpocalypse',
    'sticky_floor_lite',
    'dancequake',
    'brainlag_controls'
}

Config.EventCompatibility = {
    weather_shift = { blacklist = { random_time_shift = true } },
    hostile_npcs = { blacklist = { spawn_random_objects = true } },
    spawn_random_objects = { blacklist = { hostile_npcs = true, teleport_shuffle = true } },
    low_gravity_burst = { effectKey = 'physics_modifier', durationMs = 20000 },
    ragdoll_wave = {},
    drunk_vision = { effectKey = 'visual_overlay', durationMs = 20000, blacklist = { random_screen_filter = true } },
    speed_burst = { effectKey = 'mobility_modifier', durationMs = 15000, blacklist = { super_jump_burst = true } },
    super_jump_burst = { effectKey = 'mobility_modifier', durationMs = 15000, blacklist = { speed_burst = true } },
    explosive_ammo_burst = { effectKey = 'ammo_modifier', durationMs = 12000, blacklist = { fire_ammo_burst = true } },
    explosive_melee_burst = { effectKey = 'melee_modifier', durationMs = 12000 },
    fire_ammo_burst = { effectKey = 'ammo_modifier', durationMs = 12000, blacklist = { explosive_ammo_burst = true } },
    rapid_fire_burst = { effectKey = 'weapon_modifier', durationMs = 12000 },
    random_wanted_level = {},
    armor_refill = {},
    health_boost = {},
    health_drain = {},
    teleport_shuffle = { blacklist = { spawn_random_objects = true } },
    blackout_burst = { effectKey = 'world_lighting', durationMs = 10000 },
    random_time_shift = { blacklist = { weather_shift = true } },
    camera_shake_burst = { effectKey = 'camera_motion', durationMs = 8000, blacklist = { drunk_vision = true } },
    random_weapon = {},
    vehicle_slip = { effectKey = 'vehicle_modifier', durationMs = 7000 },
    vehicle_boost = { effectKey = 'vehicle_modifier', blacklist = { vehicle_slip = true } },
    random_screen_filter = { effectKey = 'visual_overlay', durationMs = 12000, blacklist = { drunk_vision = true } },
    no_hud_burst = { effectKey = 'ui_modifier', durationMs = 7000 },
    moon_jump_mania = { effectKey = 'physics_modifier', durationMs = 15000, blacklist = { low_gravity_burst = true } },
    chaos_fog = { effectKey = 'world_lighting', durationMs = 20000, blacklist = { weather_shift = true } },
    rainbow_car = { effectKey = 'vehicle_modifier', durationMs = 12000 },
    vehicle_malfunction = {},
    eject_from_vehicle = {},
    brake_failure = { effectKey = 'vehicle_modifier', durationMs = 9000 },
    horn_boost = {},
    random_door_open = {},
    tire_burst_all = {},
    ignite_player_brief = {},
    slippery_feet = { effectKey = 'mobility_modifier', durationMs = 10000 },
    forced_melee = { effectKey = 'weapon_modifier', durationMs = 15000 },
    disable_aim = { effectKey = 'weapon_modifier', durationMs = 10000 },
    butterfingers = {},
    ammo_drain = {},
    fake_cops = {},
    pacifist_mode = { effectKey = 'weapon_modifier', durationMs = 10000 },
    screen_blur = { effectKey = 'visual_overlay', durationMs = 10000, blacklist = { random_screen_filter = true, drunk_vision = true } },
    pixel_world = { effectKey = 'visual_overlay', durationMs = 12000, blacklist = { random_screen_filter = true, drunk_vision = true, screen_blur = true } },
    random_camera_zoom = {},
    drunk_walk = { effectKey = 'mobility_modifier', durationMs = 12000 },
    npc_panic = {},
    explosion_ring = {},
    trampoline_steps = { effectKey = 'physics_modifier', durationMs = 9000 },
    teleport_micro_shuffle = {},
    freeze_burst = { effectKey = 'mobility_modifier', durationMs = 5000 },
    slow_motion_burst = { effectKey = 'world_lighting', durationMs = 6000 },
    vehicle_jump = {},
    confused_inputs = { effectKey = 'ui_modifier', durationMs = 9000 },
    cinematic_burst = { effectKey = 'camera_motion', durationMs = 12000 },
    wrecking_punch = { effectKey = 'melee_modifier', durationMs = 15000, blacklist = { forced_melee = true, pacifist_mode = true } },
    tsunami_surge = { effectKey = 'water_modifier', durationMs = 20000, blacklist = { chaos_fog = true, weather_shift = true } },
    meteor_shower = {},
    lightning_strike = {},
    earthquake_wave = { effectKey = 'camera_motion', durationMs = 10000, blacklist = { cinematic_burst = true } },
    volcanic_smog = { effectKey = 'visual_overlay', durationMs = 18000, blacklist = { random_screen_filter = true, drunk_vision = true, pixel_world = true } },
    hailstorm = {},
    wildfire_burst = {},
    tornado_twist = { effectKey = 'physics_modifier', durationMs = 10000, blacklist = { low_gravity_burst = true, moon_jump_mania = true } },
    sandstorm = { effectKey = 'visual_overlay', durationMs = 12000, blacklist = { random_screen_filter = true, screen_blur = true, pixel_world = true } },
    aftershock = {},
    flash_flood = { effectKey = 'water_modifier', durationMs = 12000, blacklist = { tsunami_surge = true } },
    lava_floor = { effectKey = 'world_lighting', durationMs = 12000, blacklist = { blackout_burst = true, chaos_fog = true } },
    comet_tail = {},
    sharknado_warning = { effectKey = 'water_modifier', durationMs = 8000, blacklist = { tsunami_surge = true } },
    panic_evacuate = {},
    solar_flare = { effectKey = 'visual_overlay', durationMs = 8000, blacklist = { random_screen_filter = true, screen_blur = true, pixel_world = true } },
    gravity_flip = { effectKey = 'physics_modifier', durationMs = 6000, blacklist = { low_gravity_burst = true, moon_jump_mania = true } },
    adhd_horns = {},
    ufo_blink = {},
    loot_rain = {},
    confetti_bomb = {},
    npc_moshpit = {},
    traffic_magnet = {},
    yeet_vehicle = {},
    reverse_daynight = { blacklist = { random_time_shift = true } },
    glitch_scream = { effectKey = 'audio_modifier', durationMs = 9000 },
    dance_fever = { effectKey = 'mobility_modifier', durationMs = 10000, blacklist = { drunk_walk = true, slippery_feet = true } },
    sticky_bombs_party = {},
    blimp_shadow = {},
    rogue_wave = { effectKey = 'water_modifier', durationMs = 10000, blacklist = { tsunami_surge = true, flash_flood = true } },
    apocalypse_sky = { effectKey = 'world_lighting', durationMs = 18000, blacklist = { weather_shift = true, random_time_shift = true } },
    banana_peel_panic = { effectKey = 'mobility_modifier', durationMs = 10000 },
    disco_inferno = {},
    yoink_gun_lottery = {},
    quantum_seatbelt = {},
    gremlin_mechanics = {},
    bass_boosted_horns = {},
    confetti_overdrive = {},
    tiny_tornado = { effectKey = 'physics_modifier', durationMs = 10000 },
    pogo_protocol = { effectKey = 'physics_modifier', durationMs = 9000 },
    rubber_band_lag = {},
    cinema_quake = { effectKey = 'camera_motion', durationMs = 12000 },
    gravity_io = { effectKey = 'physics_modifier', durationMs = 6000 },
    meteor_snack_attack = {},
    panic_pinata = {},
    fog_of_memes = { effectKey = 'world_lighting', durationMs = 20000 },
    nightclub_blackout = { effectKey = 'world_lighting', durationMs = 10000 },
    bouncy_bullets = { effectKey = 'ammo_modifier', durationMs = 12000 },
    blizzard_of_cones = {},
    npc_karaoke = {},
    car_sneeze = {},
    sandwich_timewarp = {},
    screaming_sky = { effectKey = 'audio_modifier', durationMs = 9000 },
    reverse_moshpit = {},
    loot_pinata = {},
    cursed_zoomies = {},
    fishtank_mode = { effectKey = 'water_modifier', durationMs = 20000 },
    honkpocalypse = {},
    sticky_floor_lite = { effectKey = 'mobility_modifier', durationMs = 5000 },
    dancequake = { effectKey = 'mobility_modifier', durationMs = 10000 },
    brainlag_controls = { effectKey = 'ui_modifier', durationMs = 9000 }
}

Config.WeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'CLOUDS',
    'OVERCAST',
    'RAIN',
    'THUNDER',
    'FOGGY'
}

Config.RandomObjectModels = {
    `prop_beachball_02`,
    `prop_roadcone02a`,
    `prop_barrel_02a`,
    `prop_skid_tent_01`,
    `prop_bin_05a`
}

Config.RandomObjectCount = { min = 5, max = 12 }
Config.SpawnRadius = 30.0

Config.Commands = {
    Toggle = 'chaos',
    TriggerNow = 'chaosnow'
}

Config.FunCommands = {
    Enabled = true,
    CooldownMs = 10000,
    CoinFlip = 'coinflip',
    Roll = 'roll',
    Challenge = 'challenge'
}

Config.FunChallengeList = {
    'Find a random hill and race someone to the top without using roads.',
    'Do the most dramatic parking job you can in under 30 seconds.',
    'Form a convoy with at least 3 players and survive one full minute.',
    'Take turns doing your best NPC impression in voice chat for 20 seconds.',
    'Start an impromptu street concert using horns only.',
    'Try to land a clean jump over anything without crashing afterward.',
    'Swap cars with another player and make it back to your original spot.',
    'Hold a sidewalk dance battle for exactly one song.',
    'Pick a random landmark and everyone meet there ASAP.',
    'Drive in reverse for 45 seconds without hitting anything major.'
}

Config.Menu = {
    OpenKey = 'F9'
}
