# chaos_mode

A lightweight FiveM chaos addon for sandbox servers.

## Features
- Random timed chaos events
- 55 total effects (5 original + 50 additional chaos effects, including 30 newly added chaos events)
- Weather shifts
- Hostile NPC rebellion waves
- Random prop storms around players
- Expanded movement, combat, camera, HUD, vehicle, world, and control disruption effects
- In-game event trigger menu (default key: `F9`) with targeting for all players or selected lobby players

## Install
1. Drop the `chaos_mode` folder into your server `resources/` directory.
2. Add `ensure chaos_mode` to `server.cfg`.
3. Restart the server.

## Commands (server console)
- `chaos` → toggles scheduled chaos mode on/off
- `chaosnow` → forces an immediate random chaos event

## Config
Edit `config.lua` to tune event pool, timing, spawn counts, weather set, and menu keybind.
