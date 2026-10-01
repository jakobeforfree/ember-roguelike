class_name EnemyDB
extends RefCounted
## Enemy archetypes. `script` is the behavior; stats scale with difficulty.

const ENEMIES := {
	"grunt":   {"script": "res://scripts/combat/enemies/grunt.gd",   "hp": 45.0,  "damage": 16.0, "speed": 3.8, "radius": 0.55, "color": Color("e5484d"), "gold": 2, "cost": 1},
	"spitter": {"script": "res://scripts/combat/enemies/spitter.gd", "hp": 30.0,  "damage": 12.0, "speed": 2.9, "radius": 0.5, "color": Color("8e5cf7"), "gold": 3, "cost": 1},
	"charger": {"script": "res://scripts/combat/enemies/charger.gd", "hp": 60.0,  "damage": 22.0, "speed": 2.7, "radius": 0.65, "color": Color("f59e0b"), "gold": 3, "cost": 2},
	"boss":    {"script": "res://scripts/combat/enemies/boss_cinder_golem.gd", "hp": 1100.0, "damage": 22.0, "speed": 2.4, "radius": 1.4, "color": Color("ff5a1f"), "gold": 40, "cost": 99},
}

const SPAWNABLE := ["grunt", "spitter", "charger"]


static func get_def(id: String) -> Dictionary:
	return ENEMIES[id]


static func hp_scale(difficulty: float) -> float:
	return 1.0 + 0.3 * difficulty


static func damage_scale(difficulty: float) -> float:
	return 1.0 + 0.12 * difficulty
