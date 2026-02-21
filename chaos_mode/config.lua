Config = {}

Config.Enabled = true
Config.MinIntervalMs = 120000 -- 2 minutes
Config.MaxIntervalMs = 300000 -- 5 minutes
Config.HostileNpcDurationMs = 60000
Config.ObjectCleanupMs = 180000
Config.ComboEnabled = true
Config.ComboChance = 30 -- percent chance to trigger two events at once

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
    'no_hud_burst'
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
    no_hud_burst = { effectKey = 'ui_modifier', durationMs = 7000 }
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
