class_name UpgradeDB
extends RefCounted
## In-run upgrades offered as 1-of-3 choices. Each upgrade is data: stat modifiers
## plus an optional instant effect. They stack up to max_stacks.

const CATEGORY_COLORS := {
	"offense": Color("ff6b4a"),
	"defense": Color("4ab0ff"),
	"mobility": Color("6be36b"),
	"elemental": Color("c77dff"),
	"utility": Color("ffd166"),
}

const UPGRADES := {
	# --- Offense
	"power": {"name": "Sharpened Focus", "cat": "offense", "desc": "+20% damage", "max": 5,
		"mods": [["damage", "pct", 0.2]]},
	"haste": {"name": "Quick Draw", "cat": "offense", "desc": "+15% attack speed", "max": 5,
		"mods": [["attack_speed", "pct", 0.15]]},
	"crit": {"name": "Eagle Eye", "cat": "offense", "desc": "+10% crit chance", "max": 4,
		"mods": [["crit_chance", "flat", 0.1]]},
	"critdmg": {"name": "Brutal Strikes", "cat": "offense", "desc": "+40% crit damage", "max": 3,
		"mods": [["crit_mult", "flat", 0.4]]},
	"multishot": {"name": "Twin Volley", "cat": "offense", "desc": "+1 forward projectile, -10% damage", "max": 3,
		"mods": [["multishot", "flat", 1.0], ["damage", "pct", -0.1]]},
	"sideshot": {"name": "Fan Shot", "cat": "offense", "desc": "+2 diagonal projectiles", "max": 2,
		"mods": [["side_shots", "flat", 1.0]]},
	"pierce": {"name": "Piercing Tips", "cat": "offense", "desc": "Projectiles pierce +1 enemy", "max": 3,
		"mods": [["pierce", "flat", 1.0]]},
	# --- Defense
	"vitality": {"name": "Hearty", "cat": "defense", "desc": "+25% max HP and heal 25%", "max": 5,
		"mods": [["max_hp", "pct", 0.25]], "heal": 0.25},
	"armor": {"name": "Ironskin", "cat": "defense", "desc": "Take 8% less damage", "max": 4,
		"mods": [["damage_reduction", "flat", 0.08]]},
	"regen": {"name": "Ember Heart", "cat": "defense", "desc": "Regenerate 1.5 HP/s", "max": 3,
		"mods": [["hp_regen", "flat", 1.5]]},
	"heal": {"name": "Second Breath", "cat": "defense", "desc": "Heal 40% of max HP", "max": 99,
		"mods": [], "heal": 0.4},
	# --- Mobility
	"swift": {"name": "Fleet Foot", "cat": "mobility", "desc": "+12% move speed", "max": 3,
		"mods": [["move_speed", "pct", 0.12]]},
	"quickstep": {"name": "Quickstep", "cat": "mobility", "desc": "-18% dodge cooldown", "max": 3,
		"mods": [["dodge_cooldown", "pct", -0.18]]},
	"stride": {"name": "Long Stride", "cat": "mobility", "desc": "+30% dodge distance, longer invincibility", "max": 2,
		"mods": [["dodge_distance", "pct", 0.3], ["iframe_time", "flat", 0.08]]},
	"phantom": {"name": "Phantom Edge", "cat": "mobility", "desc": "Dodging through enemies deals 25 damage", "max": 3,
		"mods": [["dash_damage", "flat", 25.0]]},
	# --- Elemental
	"venom": {"name": "Venom Tips", "cat": "elemental", "desc": "Hits poison for 4 dmg/s (stacks)", "max": 3,
		"mods": [["poison_dps", "flat", 4.0]]},
	"ember": {"name": "Ember Shot", "cat": "elemental", "desc": "25% chance to ignite enemies", "max": 3,
		"mods": [["burn_chance", "flat", 0.25]]},
	"frost": {"name": "Rime Shot", "cat": "elemental", "desc": "30% chance to slow enemies", "max": 2,
		"mods": [["slow_chance", "flat", 0.3]]},
	"chain": {"name": "Arc Conductor", "cat": "elemental", "desc": "20% chance to chain lightning, +1 jump", "max": 3,
		"mods": [["chain_chance", "flat", 0.2], ["chain_count", "flat", 1.0]]},
	"explode": {"name": "Volatile Tips", "cat": "elemental", "desc": "15% chance to explode on hit", "max": 3,
		"mods": [["explode_chance", "flat", 0.15]]},
	# --- Utility
	"vamp": {"name": "Bloodthirst", "cat": "utility", "desc": "+4% lifesteal", "max": 3,
		"mods": [["lifesteal", "flat", 0.04]]},
	"mender": {"name": "Room Mender", "cat": "utility", "desc": "Heal 10% after clearing a room", "max": 3,
		"mods": [["heal_on_clear", "flat", 0.1]]},
	"greed": {"name": "Prospector", "cat": "utility", "desc": "+30% gold found", "max": 3,
		"mods": [["gold_find", "flat", 0.3]]},
}


static func get_def(id: String) -> Dictionary:
	return UPGRADES[id]


static func mods_of(id: String) -> Array:
	var out := []
	for m in UPGRADES[id]["mods"]:
		out.append({"stat": m[0], "kind": m[1], "value": m[2]})
	return out


## Picks `count` distinct upgrades that are not yet maxed out.
static func roll_choices(rng: RandomNumberGenerator, taken: Dictionary, count: int = 3) -> Array:
	var pool := []
	for id in UPGRADES:
		if taken.get(id, 0) < UPGRADES[id]["max"]:
			pool.append(id)
	var out := []
	while out.size() < count and not pool.is_empty():
		var i := rng.randi() % pool.size()
		out.append(pool[i])
		pool.remove_at(i)
	return out
