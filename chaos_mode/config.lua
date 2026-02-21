Config = {}

Config.Enabled = true
Config.MinIntervalMs = 30000
Config.MaxIntervalMs = 30000
Config.HostileNpcDurationMs = 30000
Config.ObjectCleanupMs = 30000
Config.VehicleRadioSyncEnabled = true
Config.VehicleRadioSyncIntervalMs = 1200

Config.BuildTool = {
    Enabled = true,
    OpenKey = 'F6',
    MaxPropsPerPlayer = 30,
    MaxPropsGlobal = 300,
    Snap = {
        GridStep = 0.25,
        RotationStep = 15.0,
        MaxPlaceDistance = 25.0
    },
    BehaviorFlags = {
        isTrampoline = false,
        isSpringPlatform = false,
        allowAttachToVehicle = false
    }
}

Config.BuildToolModelCatalog = {
    ramp_01 = {
        model = 'prop_mp_ramp_01',
        label = 'Compact Ramp',
        description = 'Small launch ramp for quick stunt lines.'
    },
    ramp_02 = {
        model = 'prop_skate_halfpipe_cr',
        label = 'Halfpipe Ramp',
        description = 'Curved halfpipe section for transitions.'
    },
    ramp_03 = {
        model = 'stt_prop_ramp_adj_flip_m',
        label = 'Adjustable Flip Ramp',
        description = 'Medium ramp with a steep angle for flips.'
    },
    trampoline_01 = {
        model = 'stt_prop_stunt_tube_l',
        label = 'Tube Trampoline',
        description = 'Large stunt tube that launches players upward.',
        flags = {
            isTrampoline = true
        }
    },
    trampoline_02 = {
        model = 'stt_prop_stunt_tube_s',
        label = 'Compact Tube Trampoline',
        description = 'Short stunt tube for tighter spaces.',
        flags = {
            isTrampoline = true
        }
    },
    spring_01 = {
        model = 'stt_prop_stunt_jump15',
        label = 'Springboard XL',
        description = 'Aggressive spring jump platform.',
        flags = {
            isSpringPlatform = true
        }
    },
    spring_02 = {
        model = 'stt_prop_stunt_jump30',
        label = 'Springboard Long',
        description = 'Extended spring platform for vehicle launches.',
        flags = {
            isSpringPlatform = true
        }
    },
    obstacle_01 = {
        model = 'prop_mp_barrier_01',
        label = 'Safety Barrier',
        description = 'Basic barricade for lane control.'
    },
    obstacle_02 = {
        model = 'prop_mp_cone_04',
        label = 'Traffic Cone',
        description = 'Small obstacle useful for slalom patterns.'
    },
    obstacle_03 = {
        model = 'prop_rub_tyre_01',
        label = 'Tyre Stack',
        description = 'Soft obstacle that can be clipped by vehicles.',
        flags = {
            allowAttachToVehicle = true
        }
    }
}

Config.BuildTool.AllowedModels = {
    ramps = {
        label = 'Ramps',
        description = 'Launch and transition ramps for stunt builds.',
        entries = {
            { id = 'ramp_01' },
            { id = 'ramp_02' },
            { id = 'ramp_03' }
        }
    },
    trampolines = {
        label = 'Trampolines',
        description = 'Bounce surfaces tuned for high vertical launches.',
        entries = {
            { id = 'trampoline_01' },
            { id = 'trampoline_02' }
        }
    },
    springs = {
        label = 'Springs',
        description = 'Directional spring platforms for speed boosts.',
        entries = {
            { id = 'spring_01' },
            { id = 'spring_02' }
        }
    },
    obstacles = {
        label = 'Obstacles',
        description = 'General-purpose blockers and challenge props.',
        entries = {
            { id = 'obstacle_01' },
            { id = 'obstacle_02' },
            { id = 'obstacle_03' }
        }
    }
}

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
    },
    banana_spin = {
        label = 'Banana Spin',
        description = 'Adds a goofy spin force like a cartoon banana peel.'
    },
    noodle_legs = {
        label = 'Noodle Legs',
        description = 'Applies wobbly movement controls for a short time.',
        durationMs = 8000
    },
    sneeze_nudge = {
        label = 'Sneeze Nudge',
        description = 'A sudden sneeze-like shove launches the target forward.'
    },
    confetti_pop = {
        label = 'Confetti Pop',
        description = 'Creates harmless confetti-like mini blasts around the player.'
    },
    radio_scramble = {
        label = 'Radio Scramble',
        description = 'Rapidly cycles radio stations in the current vehicle.',
        durationMs = 6000
    },
    map_shuffle = {
        label = 'Map Shuffle',
        description = 'Drops a random nearby waypoint to confuse navigation.'
    },
    brake_tap = {
        label = 'Brake Tap',
        description = 'Instantly bleeds off speed from the current vehicle.'
    },
    tiny_bounce = {
        label = 'Tiny Bounce',
        description = 'Pops the target into a quick mini hop.'
    },
    butterhands = {
        label = 'Butterhands',
        description = 'Forces the currently equipped weapon away.'
    },
    compass_flip = {
        label = 'Compass Flip',
        description = 'Snaps the camera heading to disorient direction.'
    },
    gravity_glitch = {
        label = 'Gravity Glitch',
        description = 'Temporarily disables gravity on the target.',
        durationMs = 4000
    },
    dance_loop = {
        label = 'Dance Loop',
        description = 'Forces an awkward dance break.',
        durationMs = 5000
    },
    shoe_glue = {
        label = 'Shoe Glue',
        description = 'Freezes the player in place very briefly.',
        durationMs = 3000
    },
    hiccup_boost = {
        label = 'Hiccup Boost',
        description = 'Applies repeated little upward hiccup jolts.',
        durationMs = 5000
    },
    phantom_honk = {
        label = 'Phantom Honk',
        description = 'Plays random honk bursts around the target.',
        durationMs = 5000
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
    'brainlag_controls',
    'singularity_vortex',
    'perfect_dodge_matrix',
    'parry_power',
    'charged_branching',
    'armor_breaker',
    'hazard_kicker',
    'air_combo_mania',
    'momentum_strike',
    'overdrive_mode',
    'finisher_window',
    'morale_break',
    'shield_reactor',
    'stance_shift',
    'clash_counter',
    'trap_spree',
    'combat_weather',
    'last_stand',
    'pack_tactics',
    'limb_cracker',
    'arena_objectives',
    'style_rank_rush'
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
    brainlag_controls = { effectKey = 'ui_modifier', durationMs = 9000 },
    singularity_vortex = {
        effectKey = 'physics_modifier',
        durationMs = 12000,
        blacklist = {
            low_gravity_burst = true,
            moon_jump_mania = true,
            tornado_twist = true,
            gravity_flip = true,
            gravity_io = true,
            tiny_tornado = true,
            pogo_protocol = true
        }
    },
    perfect_dodge_matrix = { effectKey = 'combat_modifier', durationMs = 14000 },
    parry_power = { effectKey = 'combat_modifier', durationMs = 14000 },
    charged_branching = { effectKey = 'combat_modifier', durationMs = 14000 },
    armor_breaker = { effectKey = 'combat_modifier', durationMs = 15000 },
    hazard_kicker = { effectKey = 'combat_modifier', durationMs = 12000 },
    air_combo_mania = { effectKey = 'combat_modifier', durationMs = 12000 },
    momentum_strike = { effectKey = 'combat_modifier', durationMs = 12000 },
    overdrive_mode = { effectKey = 'combat_modifier', durationMs = 15000 },
    finisher_window = { effectKey = 'combat_modifier', durationMs = 12000 },
    morale_break = { effectKey = 'combat_modifier', durationMs = 10000 },
    shield_reactor = { effectKey = 'combat_modifier', durationMs = 12000 },
    stance_shift = { effectKey = 'combat_modifier', durationMs = 15000 },
    clash_counter = { effectKey = 'combat_modifier', durationMs = 10000 },
    trap_spree = { effectKey = 'combat_modifier', durationMs = 12000 },
    combat_weather = { effectKey = 'world_lighting', durationMs = 15000, blacklist = { weather_shift = true } },
    last_stand = { effectKey = 'combat_modifier', durationMs = 20000 },
    pack_tactics = { effectKey = 'combat_modifier', durationMs = 10000 },
    limb_cracker = { effectKey = 'combat_modifier', durationMs = 12000 },
    arena_objectives = { effectKey = 'combat_modifier', durationMs = 25000 },
    style_rank_rush = { effectKey = 'combat_modifier', durationMs = 16000 }
}

Config.EventMeta = {
    perfect_dodge_matrix = { label = 'Perfect Dodge Matrix', description = 'Frame-perfect dodges trigger short slow-motion and bonus sprint.', durationMs = 14000 },
    parry_power = { label = 'Parry Power', description = 'Melee defense windows tighten and successful blocks shove enemies harder.', durationMs = 14000 },
    charged_branching = { label = 'Charged Branching', description = 'Holding attack adds directional launch force for branching finishers.', durationMs = 14000 },
    armor_breaker = { label = 'Armor Breaker', description = 'Weapon hits apply extra armor/vehicle deformation and stagger force.', durationMs = 15000 },
    hazard_kicker = { label = 'Hazard Kicker', description = 'Nearby explosive props are highlighted and can be punted with strong force.', durationMs = 12000 },
    air_combo_mania = { label = 'Air Combo Mania', description = 'Jump attacks gain extra lift to keep targets airborne.', durationMs = 12000 },
    momentum_strike = { label = 'Momentum Strike', description = 'The faster you move, the harder your melee impacts hit.', durationMs = 12000 },
    overdrive_mode = { label = 'Overdrive Mode', description = 'Damage output rises but your health slowly drains for risk/reward.', durationMs = 15000 },
    finisher_window = { label = 'Finisher Window', description = 'Sustained hits unlock brief execute blasts and camera flair.', durationMs = 12000 },
    morale_break = { label = 'Morale Break', description = 'Hostile NPCs panic and flee after nearby takedowns.', durationMs = 10000 },
    shield_reactor = { label = 'Shield Reactor', description = 'Blocking while in vehicles creates recoil pulses and bumper force.', durationMs = 12000 },
    stance_shift = { label = 'Stance Shift', description = 'Cycle between speed, balance, and power stances with changing buffs.', durationMs = 15000 },
    clash_counter = { label = 'Clash Counter', description = 'Head-on collisions and melee clashes trigger shockwave knockback.', durationMs = 10000 },
    trap_spree = { label = 'Trap Spree', description = 'Random trap props spawn around combat zones with warning sparks.', durationMs = 12000 },
    combat_weather = { label = 'Combat Weather', description = 'Rapid weather swaps alter visibility and traction mid-fight.', durationMs = 15000 },
    last_stand = { label = 'Last Stand', description = 'Fatal hits are negated once while the mode is active.', durationMs = 20000 },
    pack_tactics = { label = 'Pack Tactics', description = 'Nearby hostile NPCs coordinate rushes and group pressure.', durationMs = 10000 },
    limb_cracker = { label = 'Limb Cracker', description = 'Shots to legs/arms apply extra slow and recoil stagger.', durationMs = 12000 },
    arena_objectives = { label = 'Arena Objectives', description = 'Temporary objective markers appear; hold them to gain armor bursts.', durationMs = 25000 },
    style_rank_rush = { label = 'Style Rank Rush', description = 'Varied attacks build style rank and award periodic buffs.', durationMs = 16000 }
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
