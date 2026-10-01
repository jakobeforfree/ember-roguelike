class_name WeaponDB
extends RefCounted
## Weapon type definitions. Each weapon points to a behavior script (how it attacks)
## plus base stats. Add a new weapon = add an entry + a behavior script.
## MVP ships with the bow; the others are listed to show the intended shape.

const WEAPONS := {
	"bow": {
		"name": "Bow",
		"behavior": "res://scripts/weapons/bow_behavior.gd",
		"base": {"damage": 14.0, "attack_speed": 1.5, "attack_range": 520.0, "projectile_speed": 950.0},
		"item_names": ["Ashwood Bow", "Ember Longbow", "Hunter's Recurve", "Cinder Arc"],
		"color": Color("e8c36a"),
	},
	# Planned:
	# "sword":    melee arc sweep, short range, cleaves, high damage
	# "staff":    slow homing orbs that explode
	# "daggers":  rapid fan of short-range knives
	# "crossbow": slow, heavy bolts with built-in pierce
}


static func get_def(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["bow"])


static func ids() -> Array:
	return WEAPONS.keys()
