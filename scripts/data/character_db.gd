class_name CharacterDB
extends RefCounted
## Playable characters (classes). MVP has one; later classes just add entries
## with different base stats and a starting weapon / passive.

const CHARACTERS := {
	"wanderer": {
		"name": "The Wanderer",
		"desc": "A lonely traveling wizard, following the embers deeper.",
		"color": Color("ff8c42"),
		"base": {"max_hp": 120.0, "move_speed": 6.8, "crit_chance": 0.05, "crit_mult": 1.6,
			"dodge_cooldown": 1.1, "dodge_distance": 5.2, "iframe_time": 0.32},
		"default_weapon": "staff",
	},
}


static func get_def(id: String) -> Dictionary:
	return CHARACTERS.get(id, CHARACTERS["wanderer"])
