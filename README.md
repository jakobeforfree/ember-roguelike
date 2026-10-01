# Ember Roguelike (prototype)

An original mobile action roguelike built in **Godot 4.3** (GDScript, Compatibility renderer),
rendered in stylized low-poly 3D from a tilted top-down camera.
You move with a virtual joystick, your weapon fires on its own, and a dodge button with
invincibility frames is your main defensive skill. You fight through randomized rooms, choose
upgrades, beat a boss, and keep the gear you find between runs.

## Why Godot
Godot is a good fit here: it's light (fast iteration, small APKs), has solid 2D and touch input,
exports to Android and iOS without extra cost, and GDScript keeps the code easy to read.
Unity would also work but is heavier and costs more for this scope. A web framework would make
native mobile export and performance harder.

## Running
1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot`, then press **F5**.

Play in the browser: **https://ember-roguelike.vercel.app**. It's built PC-first (keyboard + mouse or gamepad);
touch controls appear automatically if you touch the screen.

| Action | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Move | WASD / arrows | Left stick / D-pad | Left-half floating stick |
| Dodge | Space / Shift (standing still: toward the mouse cursor) | A / RB | DODGE button |
| Attack | Automatic, nearest visible enemy | | |
| Pick upgrade | 1 / 2 / 3, or arrows + Enter, or click | D-pad + A | Tap |
| Pause | Esc / P | Start | `II` button |
| Start run | Enter | A | Tap |

Settings (fullscreen, screen shake, damage numbers) are in the gear menu at camp and in the pause menu,
and are saved to `user://settings.cfg`.

## What's in the MVP
- **Player**: the Ember Wanderer, who moves freely and shoots the nearest visible enemy in range
  automatically. The bow can shoot while you move.
- **Dodge**: a quick dash in the direction you're moving, with a cooldown and i-frames.
  **Perfect dodge**: if an attack would have hit you during the i-frames, time slows briefly,
  your next 3 shots are guaranteed crits, and half the dodge cooldown is refunded. This rewards
  good timing over spamming the button.
- **Enemies**: each one shows its attack before it lands. The red zone fills up, and the hit
  lands exactly when it's full, using the same shape you see.
  - *Grunt* (melee): walks up to you and swipes in an arc.
  - *Spitter* (ranged): keeps its distance, shows an aim line, then fires a slow orb.
    From difficulty 3 it fires 3 at once.
  - *Charger*: shows a long lane, then charges down it. It's stunned afterward, which is your chance to punish it.
- **Boss, the Cinder Golem**: rotates between three attacks: Meteor Slam (circles fall where you're standing),
  Ember Nova (rings of orbs with a gap you can slip through) and Molten Rush (a long charge). Below 50% HP it
  enrages: faster windups, double novas, and it summons extra enemies.
- **Run**: 5 connected rooms per stage (4 combat rooms with 2–3 waves each, then the boss). Layouts and
  enemy groups are randomized from a difficulty budget. After the boss the next stage starts, harder.
  Stages continue without end.
- **Upgrades**: one pick at the start of a run and one after each cleared room. Each pick is 1 of 3, drawn
  from 22 stacking upgrades in 5 categories (offense, defense, mobility, elemental, utility).
  Examples: multishot, fan shot, piercing, poison, burning, slow, chain lightning, explosions,
  lifesteal, dodge cooldown, dash damage.
- **Gear**: 7 slots (weapon, helmet, chest, gloves, boots, ring, amulet) and 6 rarities
  (Common → Mythic). Higher rarity means stronger stats and more bonus stats. Epic and above also get ★ special abilities
  (Venomous, Stormcaller, Volatile, Vampiric, Swiftstep, Frostbite, Phantom Dash, Keen Edge).
  Gear drops in rooms (always from the boss) and is **saved as soon as you pick it up**,
  so you keep it when you die.
- **Camp (hub)**: equip, unequip, salvage gear for gold, see your stats, start a run. A clearly labeled
  *Dev: grant random gear* button is included for testing.

## Code layout
```
scripts/
  autoload/   events.gd (signal bus), profile.gd (persistent save), controls.gd (input actions,
              keyboard/gamepad/touch mode), settings.gd (player preferences)
  core/       stats.gd (modifier-based stats), stat_builder.gd, run_state.gd, flat.gd (XZ-plane helpers)
  visual/     models, materials, icons, world_kit (lighting/post)
  data/       rarity, gear_db, gear_item, loot_generator, weapon_db,
              upgrade_db, character_db, enemy_db   ← data tables
  combat/     player, enemy (base), enemies/*, projectile, telegraph, combat (damage + procs), fx
  weapons/    weapon_behavior.gd (base), bow_behavior.gd
  world/      room.gd (layout, walls, A* nav, waves, gate), run_controller.gd, camp_scene.gd, loot_pickup.gd
  ui/         hud, virtual_joystick, dodge_button, upgrade_panel, message_panel, hub, ui_kit, badge, bar
shaders/      telegraph + floor
tools/        build_web.sh, fetch_web_templates.py (web build / Vercel)
tests/        test_runner (headless tests + bot run), sim_bot, screenshots
```
Art is placeholder low-poly 3D built from primitives in `scripts/visual/models.gd`
(each model is just a `Node3D`, so imported `.glb` art can replace them one at a time).
Look and feel live in a few places:
- `scripts/visual/world_kit.gd` sets lighting, tonemapping, glow, fog and shadows
- `shaders/telegraph.gdshader` draws the ground-projected attack warnings, `shaders/floor.gdshader` the floor tiles
- `scripts/ui/ui_kit.gd` holds the UI design system (palette, Outfit font, Material Icons, buttons, chips, animations)

Fonts are Outfit (SIL OFL) and Material Icons (Apache 2.0); licenses are in `assets/fonts/`.

### Where future features plug in
| Feature | Where |
|---|---|
| More weapons | Add an entry to `WeaponDB.WEAPONS` and a `WeaponBehavior` subclass (sword = arc sweep, staff = orbs…). Crits, lifesteal and elemental effects already work for every weapon through `Combat`. |
| More armor, affixes, specials | Add rows to `GearDB` (`SLOT_INFO`, `AFFIXES`, `SPECIALS`). |
| Character classes | Add to `CharacterDB` (base stats and starting weapon). `Profile.character_id` selects one. |
| Talents, pets, set bonuses | Anything that feeds `Stats` modifiers plugs into `StatBuilder.build()`. Pets would be a node like `Player` that uses `Combat.player_hits_enemy`. |
| Elemental builds | Elements are stats (`poison_dps`, `burn_chance`, `chain_chance`…) handled in `Combat`. |
| Shops, crafting | `LootGenerator.generate(rng, level, rarity, slot)` and `Profile.gold` / `salvage`. |
| Daily challenges | `RunState` takes a seed, so a seeded run is reproducible. `Events` covers kill and dodge tracking. |
| Procedural maps | `Room.build()` and `LAYOUTS` can be swapped for a generator. Navigation (`AStarGrid2D`) and the 3D walls are built from the obstacle rectangles. |
| Cloud saves | `Profile.to_dict()` / `load_dict()` is a versioned JSON document ready to sync (e.g. a Supabase table keyed by user id). |
| Ability button | `Hud` has room above the dodge button. Add a button wired like `DodgeButton`. |

## Tests
Headless tests check the stat math, rarity rolls, loot scaling, upgrade rolls, save/load,
telegraph hit shapes, dodge i-frames and cooldown, perfect dodge, poison and lifesteal effects, and auto-attack.
They also run a **full simulated run**: a bot dodges telegraphs, collects loot and takes the doors
through all 5 rooms and the boss into Stage 2.
```
godot --headless --import            # first time only
godot --headless --fixed-fps 60 res://tests/test_runner.tscn   # exit code 0 = pass
```
`tests/screenshots.tscn` renders reference screenshots. It needs a display, for example
`SHOT_DIR=/tmp/shots xvfb-run godot --rendering-driver opengl3 res://tests/screenshots.tscn`.

## Web build (play on your phone's browser)
`bash tools/build_web.sh` downloads Godot plus only the Web export template (~17 MB, taken from the
1 GB template archive with HTTP range requests), then exports to `build/web`. `vercel.json` runs the
same script, so a Vercel project connected to this repo rebuilds on every push. It uses the
no-threads web build, so no special COOP/COEP headers are needed. The offline-app (PWA) service worker
is off on purpose, so browsers always load the newest build after a deploy.

## Toward Steam
The game is PC-first now: rebindable input actions (`Controls`), gamepad support (Steam Deck), a 16:9
desktop window with fullscreen, and a settings file. Still needed for a Steam build: Windows/Linux export
presets, audio, GodotSteam (achievements, cloud saves via `Profile.to_dict()`), and store assets.

## Exporting to Android / iOS
1. In Godot: **Editor → Manage Export Templates → Download**.
2. Android: set up the Android SDK and a debug keystore under *Editor Settings → Export → Android*,
   then **Project → Export → Add… → Android**. The project is already landscape and uses the mobile-friendly
   Compatibility renderer.
3. iOS: export from macOS with Xcode installed (**Add… → iOS**), then build the generated Xcode project.

## Tuning knobs
- Difficulty curve: `RunState.difficulty()`, `EnemyDB.hp_scale/damage_scale`, `Room._plan_waves`
- Dodge feel: `Player.DASH_TIME`, character `dodge_cooldown / dodge_distance / iframe_time`
- Telegraph windups: `WINDUP` / `AIM_TIME` constants in each enemy script
- Drop rates: `RunController.ROOM_LOOT_CHANCE`, `Rarity.TIERS[*].weight`
