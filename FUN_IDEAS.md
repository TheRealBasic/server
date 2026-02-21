# Chaos Mode: 10 Fun Changes + Suggested Tasks

## 1) Chaos Wheel Vote (players vote next event)
Create a live vote every interval so players choose one of 3 random chaos events instead of purely random picks.

**Suggested tasks**
- Add a server-side vote state (`activeVote`, `options`, `endsAt`).
- Add client UI/chat prompt for selecting option 1/2/3.
- Add command bindings (`/chaosvote 1-3`) and anti-spam cooldown.
- Trigger winning event and broadcast result.

## 2) Combo Events (two effects at once)
Trigger short “combo rounds” where two compatible effects run together (e.g., drunk vision + ragdoll wave).

**Suggested tasks**
- Add a compatibility matrix in `config.lua`.
- Build `chooseComboEvent()` with blacklist for conflicting effects.
- Show combined notification text and shared duration.
- Add safety cap for max concurrent timed effects.

## 3) Boss Round: Juggernaut NPC
Spawn a single high-health chaos boss with dramatic intro and reward if players survive/defeat it.

**Suggested tasks**
- Add `juggernaut_round` event handler and config section.
- Create boss with armor/weapon tuning and map blip.
- Add timeout/despawn logic and cleanup.
- Broadcast start/end summary in chat.

## 4) Loot Piñata Props
Spawn breakable prop clusters that drop random goodies (armor, health, ammo, weapon).

**Suggested tasks**
- Add prop metadata tracking (owner event, spawnedAt).
- Detect prop destruction and roll loot table.
- Add small pickup effects/sounds.
- Clean up abandoned props after timeout.

## 5) Chaos Streak System
Reward players for surviving multiple events in a row without dying.

**Suggested tasks**
- Track per-player streak counters server-side.
- Reset on death/disconnect; increment on successful round end.
- Add streak milestones and bonuses (armor, temporary perk).
- Add `/chaosstreak` command to display stats.

## 6) Event Announcer Personality Pack
Add rotating announcer lines and themes (arcade, sci-fi, sports commentator).

**Suggested tasks**
- Add announcer line tables in a new shared file.
- Pick random line variants per event start/end.
- Add config toggle for family-friendly mode.
- Add optional subtitle color/theme per announcer.

## 7) Region-Based Chaos Zones
Instead of global effects, pick random map zones where chaos is active for a limited time.

**Suggested tasks**
- Define zone list (center + radius + display name).
- Apply event effects only to players inside zone.
- Add zone enter/exit notifications and map marker.
- Auto-rotate zone after timer expires.

## 8) Chaos Contracts (mini-objectives)
Offer optional micro-missions during chaos (e.g., “survive 60s in vehicle slip”).

**Suggested tasks**
- Add contract generator tied to active event type.
- Track objective progress client-side and validate server-side.
- Grant rewards/cosmetics for completion.
- Add per-player contract cooldown.

## 9) Replayable “Chaos of the Day” Seed
Generate a daily deterministic event sequence so communities can compare runs.

**Suggested tasks**
- Add daily seed based on date/server name.
- Add deterministic chooser for event order.
- Add command to print today’s seed and next event preview.
- Keep optional random mode fallback for normal play.

## 10) Party Mode Audio + Screen FX Packs
Add optional themed audio stingers and visual packs for each event category.

**Suggested tasks**
- Add client-side FX profiles (minimal, normal, extreme).
- Map events to sound and post-FX bundles.
- Add per-player preference command (`/chaosfx`).
- Ensure safe cleanup when effect ends or resource restarts.
