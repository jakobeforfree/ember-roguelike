# Ember Roguelike (prototype)

An original mobile action roguelike built in **Godot 4.3** (GDScript, Compatibility renderer).
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

| Action | Touch | Desktop |
|---|---|---|
| Move | Drag anywhere on the left half (floating stick) | WASD / arrows, or drag with the mouse |
| Dodge | Big **DODGE** button, bottom right | Space / Shift / K |
| Pause | `II` top left | Esc |

The mouse acts as a touch (`emulate_touch_from_mouse`), so you can test the touch controls on desktop.

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
  autoload/   events.gd (signal bus), profile.gd (persistent save)
  core/       stats.gd (modifier-based stats), stat_builder.gd, run_state.gd
  data/       rarity, gear_db, gear_item, loot_generator, weapon_db,
              upgrade_db, character_db, enemy_db   ← data tables
  combat/     player, enemy (base), enemies/*, projectile, telegraph, combat (damage + procs), fx
  weapons/    weapon_behavior.gd (base), bow_behavior.gd
  world/      room.gd (layout, walls, A* nav, waves, door), run_controller.gd, loot_pickup.gd
  ui/         hud, virtual_joystick, dodge_button, upgrade_panel, message_panel, hub, ui_kit
tests/        test_runner (headless tests + bot run), sim_bot, screenshots
```
Placeholder art is drawn in code with `_draw()`, so there are no image files to replace yet.

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
| Procedural maps | `Room.build()` and `LAYOUTS` can be swapped for a generator. Navigation (`AStarGrid2D`) rebuilds itself from obstacles. |
| Cloud saves | `Profile.to_dict()` / `load_dict()` is a versioned JSON document ready to sync. |
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
