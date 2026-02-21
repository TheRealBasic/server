Config = {}

Config.Enabled = true
Config.MinIntervalMs = 120000 -- 2 minutes
Config.MaxIntervalMs = 300000 -- 5 minutes
Config.HostileNpcDurationMs = 60000
Config.ObjectCleanupMs = 180000

Config.EventPool = {
    'weather_shift',
    'hostile_npcs',
    'spawn_random_objects',
    'low_gravity_burst',
    'ragdoll_wave'
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
