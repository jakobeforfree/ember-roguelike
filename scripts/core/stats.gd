class_name Stats
extends RefCounted
## Generic stat container. Final value = (base + flat) * (1 + pct), then clamped.
## Every source of power (character, gear, run upgrades, later: talents, pets)
## just adds modifiers here, so new systems don't need to touch combat code.

const MOD_FLAT := "flat"
const MOD_PCT := "pct"

## Default value for every known stat. Unknown stats default to 0.
const DEFAULTS := {
	"max_hp": 100.0,
	"damage": 10.0,
	"attack_speed": 1.0,        # attacks per second
	"attack_range": 12.0,
	"projectile_speed": 22.0,
	"move_speed": 6.5,
	"crit_chance": 0.05,
	"crit_mult": 1.6,
	"damage_reduction": 0.0,    # 0..0.7
	"hp_regen": 0.0,            # hp per second
	"lifesteal": 0.0,           # fraction of damage dealt
	"dodge_cooldown": 1.2,
	"dodge_distance": 5.2,
	"iframe_time": 0.32,
	"dash_damage": 0.0,         # damage dealt to enemies you dash through
	"multishot": 0.0,           # extra forward projectiles
	"side_shots": 0.0,          # pairs of diagonal projectiles
	"pierce": 0.0,              # enemies a projectile passes through
	"poison_dps": 0.0,
	"burn_chance": 0.0,
	"slow_chance": 0.0,
	"chain_chance": 0.0,
	"chain_count": 2.0,
	"explode_chance": 0.0,
	"heal_on_clear": 0.0,       # fraction of max hp healed after a room
	"gold_find": 0.0,
	"ability_cooldown": 8.0,    # Ember Burst (Q)
	"ability_power": 1.0,
}

const LIMITS := {
	"crit_chance": Vector2(0.0, 1.0),
	"damage_reduction": Vector2(0.0, 0.7),
	"dodge_cooldown": Vector2(0.3, 10.0),
	"ability_cooldown": Vector2(2.0, 30.0),
	"attack_speed": Vector2(0.2, 12.0),
	"burn_chance": Vector2(0.0, 1.0),
	"slow_chance": Vector2(0.0, 1.0),
	"chain_chance": Vector2(0.0, 1.0),
	"explode_chance": Vector2(0.0, 1.0),
	"lifesteal": Vector2(0.0, 0.5),
}

var _base := {}
var _flat := {}
var _pct := {}


func _init(base: Dictionary = {}) -> void:
	_base = DEFAULTS.duplicate()
	for k in base:
		_base[k] = float(base[k])


func set_base(stat: String, value: float) -> void:
	_base[stat] = value


func add_mod(stat: String, kind: String, value: float) -> void:
	var target := _pct if kind == MOD_PCT else _flat
	target[stat] = target.get(stat, 0.0) + value


## Applies an array of modifier dictionaries: [{stat, kind, value}, ...]
func add_mods(mods: Array) -> void:
	for m in mods:
		add_mod(m["stat"], m["kind"], float(m["value"]))


func get_stat(stat: String) -> float:
	var v: float = (_base.get(stat, 0.0) + _flat.get(stat, 0.0)) * (1.0 + _pct.get(stat, 0.0))
	if LIMITS.has(stat):
		var lim: Vector2 = LIMITS[stat]
		v = clampf(v, lim.x, lim.y)
	return v


func geti(stat: String) -> int:
	return int(round(get_stat(stat)))
