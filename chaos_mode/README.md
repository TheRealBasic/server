# chaos_mode

A lightweight FiveM chaos addon for sandbox servers.

## Features
- Random timed chaos events
- 120+ total effects, including a new gameplay-focused combat expansion pack
- Weather shifts
- Hostile NPC rebellion waves
- Random prop storms around players
- Expanded movement, combat, camera, HUD, vehicle, world, and control disruption effects
- **NEW: Singularity Vortex** that drags nearby vehicles and NPCs into a violent mini black hole around each player
- **NEW: Gameplay Pack** with 20 additional combat-style events (perfect dodge matrix, parry power, stance shift, arena objectives, style rank rush, and more)
- **NEW: Per-event options toggle** in the chaos menu so each event can be enabled/disabled at any time
- In-game event trigger menu (default key: `F9`) with targeting for all players or selected lobby players

## Install
1. Drop the `chaos_mode` folder into your server `resources/` directory.
2. Add `ensure chaos_mode` to `server.cfg`.
3. Restart the server.

## Commands (server console)
- `chaos` → toggles scheduled chaos mode on/off
- `chaosnow` → forces an immediate random chaos event


## Commands (players)
- `/coinflip` → flips a coin and announces the result in chat
- `/roll [max]` → rolls a random number (default 1-100, capped at 1000)
- `/challenge` → posts a random sandbox mini-challenge for everyone

These fun commands are configurable in `Config.FunCommands` and `Config.FunChallengeList`.

## Config
Edit `config.lua` to tune event pool, timing, spawn counts, weather set, and menu keybind.

## Event weight and anti-repeat tuning
Use these optional settings to make event selection feel less repetitive while still allowing fine-grained biasing:

- `Config.EventWeights`
  - Table keyed by event name.
  - Default weight is `1.0` for any event not listed.
  - Higher values make events appear more often (for example `2.0`).
  - Lower values make events rarer (for example `0.5`).
  - `0` disables an event for weighted random picks without removing it from `EventPool`.

- `Config.EventRecentHistoryWindow`
  - Number of most-recently-triggered events to keep in rolling history.
  - Repeated events inside this history get automatically deprioritized.
  - `0` disables anti-repeat behavior.

### Practical balancing workflow
1. Start with default weights and set `EventRecentHistoryWindow` to around `5-8`.
2. Run the server and observe debug logs from `server.lua` (single and combo picks include base/effective weight and history).
3. Reduce noisy or overbearing events to `0.4-0.8`.
4. Raise underrepresented "fun" events to `1.2-1.8`.
5. If repeats still feel common, increase the history window by 1-2 and re-test.
