class_name WeaponDB
extends RefCounted
## Weapon types. Each points at a behavior script (HOW it attacks) plus base stats.
## Weapons differ in behavior, range and risk - not just damage numbers.
## Adding a weapon = an entry here + a WeaponBehavior script + a model in Models.weapon().

const WEAPONS := {
	"staff": {
		"name": "Staff", "icon": "flare", "color": Color("ff8a3d"),
		"behavior": "res://scripts/weapons/staff_behavior.gd",
		"desc": "Slow homing embers that burst on impact, splashing nearby foes.",
		"base": {"damage": 19.0, "attack_speed": 1.0, "attack_range": 12.0, "projectile_speed": 11.0},
		"item_names": ["Ashwood Staff", "Wanderer's Staff", "Cinderbough", "Hearthkeeper"],
	},
	"bow": {
		"name": "Bow", "icon": "north_east", "color": Color("ffc56b"),
		"behavior": "res://scripts/weapons/bow_behavior.gd",
		"desc": "Fast, long-range arrows. Multishot adds parallel arrows.",
		"base": {"damage": 14.0, "attack_speed": 1.5, "attack_range": 13.0, "projectile_speed": 24.0},
		"item_names": ["Ashwood Bow", "Ember Longbow", "Hunter's Recurve", "Cinder Arc"],
	},
	"sword": {
		"name": "Sword", "icon": "colorize", "color": Color("e2e8f0"),
		"behavior": "res://scripts/weapons/sword_behavior.gd",
		"desc": "Wide melee sweeps that cleave everything in front of you. High risk, high damage.",
		"base": {"damage": 30.0, "attack_speed": 1.15, "attack_range": 3.4},
		"item_names": ["Runeblade", "Pilgrim's Edge", "Emberbrand", "Oathkeeper"],
	},
	"daggers": {
		"name": "Daggers", "icon": "content_cut", "color": Color("a3e635"),
		"behavior": "res://scripts/weapons/daggers_behavior.gd",
		"desc": "A rapid fan of short-range knives. Shred anything up close.",
		"base": {"damage": 5.5, "attack_speed": 2.4, "attack_range": 7.5, "projectile_speed": 20.0},
		"item_names": ["Twin Fangs", "Whisper Knives", "Ashen Shivs", "Viper Pair"],
	},
	"crossbow": {
		"name": "Crossbow", "icon": "near_me", "color": Color("94a3b8"),
		"behavior": "res://scripts/weapons/crossbow_behavior.gd",
		"desc": "Slow, heavy bolts that pierce through two extra enemies.",
		"base": {"damage": 34.0, "attack_speed": 0.7, "attack_range": 15.0, "projectile_speed": 34.0},
		"item_names": ["Ironjaw", "Siege Arbalest", "Warden's Crossbow", "Bolt Thrower"],
	},
	"wand": {
		"name": "Wand", "icon": "auto_fix_high", "color": Color("7dd3fc"),
		"behavior": "res://scripts/weapons/wand_behavior.gd",
		"desc": "Instant lightning that leaps between nearby enemies.",
		"base": {"damage": 11.0, "attack_speed": 1.8, "attack_range": 10.0},
		"item_names": ["Spark Wand", "Stormtwig", "Galvanic Rod", "Thunderquill"],
	},
	"tome": {
		"name": "Tome", "icon": "menu_book", "color": Color("a5b4fc"),
		"behavior": "res://scripts/weapons/tome_behavior.gd",
		"desc": "Calls a frost nova on your target, damaging and slowing everything nearby.",
		"base": {"damage": 18.0, "attack_speed": 0.9, "attack_range": 11.0},
		"item_names": ["Frost Codex", "Rimebound Tome", "Winter Almanac", "Glacial Grimoire"],
	},
}


static func get_def(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["staff"])


static func ids() -> Array:
	return WEAPONS.keys()
