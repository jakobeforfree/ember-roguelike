class_name GearDB
extends RefCounted
## Gear slots, their implicit (main) stat, the random affix pool and special abilities.
## Values here are for a Common, level-1 item; rarity and item level scale them.

const SLOTS := ["weapon", "helmet", "chest", "gloves", "boots", "ring", "amulet"]

const SLOT_INFO := {
	"weapon": {"label": "Weapon", "icon": "my_location", "implicit": {"stat": "damage", "kind": "flat", "value": 3.0}},
	"helmet": {"label": "Helmet", "icon": "sports_motorsports", "implicit": {"stat": "max_hp", "kind": "flat", "value": 12.0},
		"names": ["Iron Cap", "Ashen Hood", "Warden Helm"]},
	"chest": {"label": "Chest", "icon": "shield",  "implicit": {"stat": "damage_reduction", "kind": "flat", "value": 0.03},
		"names": ["Padded Vest", "Scale Mail", "Ember Plate"]},
	"gloves": {"label": "Gloves", "icon": "back_hand", "implicit": {"stat": "attack_speed", "kind": "pct", "value": 0.05},
		"names": ["Leather Grips", "Quickdraw Gloves", "Smolder Gauntlets"]},
	"boots": {"label": "Boots", "icon": "hiking",  "implicit": {"stat": "move_speed", "kind": "pct", "value": 0.04},
		"names": ["Worn Boots", "Strider Boots", "Ashwalkers"]},
	"ring": {"label": "Ring", "icon": "radio_button_checked",   "implicit": {"stat": "crit_chance", "kind": "flat", "value": 0.03},
		"names": ["Copper Band", "Spark Ring", "Signet of Embers"]},
	"amulet": {"label": "Amulet", "icon": "diamond", "implicit": {"stat": "damage", "kind": "pct", "value": 0.05},
		"names": ["Bone Charm", "Coal Pendant", "Heartflame Amulet"]},
}

## Random secondary stats any slot can roll.
const AFFIXES := [
	{"stat": "max_hp", "kind": "flat", "value": 10.0},
	{"stat": "damage", "kind": "pct", "value": 0.04},
	{"stat": "attack_speed", "kind": "pct", "value": 0.04},
	{"stat": "move_speed", "kind": "pct", "value": 0.03},
	{"stat": "crit_chance", "kind": "flat", "value": 0.025},
	{"stat": "crit_mult", "kind": "flat", "value": 0.1},
	{"stat": "hp_regen", "kind": "flat", "value": 0.4},
	{"stat": "dodge_cooldown", "kind": "pct", "value": -0.04},
	{"stat": "gold_find", "kind": "flat", "value": 0.08},
]

## Special abilities, granted on Epic+ items. Value scales with rarity.
const SPECIALS := [
	{"id": "venom", "name": "Venomous", "desc": "Hits poison for %d dmg/s", "stat": "poison_dps", "kind": "flat", "value": 3.0, "fmt": 1.0},
	{"id": "storm", "name": "Stormcaller", "desc": "%d%% chance to chain lightning", "stat": "chain_chance", "kind": "flat", "value": 0.07, "fmt": 100.0},
	{"id": "volatile", "name": "Volatile", "desc": "%d%% chance to explode on hit", "stat": "explode_chance", "kind": "flat", "value": 0.06, "fmt": 100.0},
	{"id": "vampiric", "name": "Vampiric", "desc": "%d%% lifesteal", "stat": "lifesteal", "kind": "flat", "value": 0.02, "fmt": 100.0},
	{"id": "swift", "name": "Swiftstep", "desc": "Dodge cooldown -%d%%", "stat": "dodge_cooldown", "kind": "pct", "value": -0.06, "fmt": -100.0},
	{"id": "frost", "name": "Frostbite", "desc": "%d%% chance to slow", "stat": "slow_chance", "kind": "flat", "value": 0.08, "fmt": 100.0},
	{"id": "phantom", "name": "Phantom Dash", "desc": "Dodging through enemies deals %d dmg", "stat": "dash_damage", "kind": "flat", "value": 10.0, "fmt": 1.0},
	{"id": "keen", "name": "Keen Edge", "desc": "+%d%% crit damage", "stat": "crit_mult", "kind": "flat", "value": 0.15, "fmt": 100.0},
]

const STAT_LABELS := {
	"max_hp": "Max HP", "damage": "Damage", "attack_speed": "Attack Speed",
	"move_speed": "Move Speed", "crit_chance": "Crit Chance", "crit_mult": "Crit Damage",
	"hp_regen": "HP Regen/s", "dodge_cooldown": "Dodge Cooldown", "gold_find": "Gold Find",
	"damage_reduction": "Damage Reduction", "poison_dps": "Poison", "chain_chance": "Chain Lightning",
	"explode_chance": "Explosion", "lifesteal": "Lifesteal", "slow_chance": "Slow",
	"dash_damage": "Dash Damage",
}

## Stats displayed as percentages when used with a flat modifier.
const PERCENT_STATS := ["crit_chance", "crit_mult", "damage_reduction", "gold_find", "lifesteal",
	"chain_chance", "explode_chance", "slow_chance", "burn_chance"]


static func describe_mod(m: Dictionary) -> String:
	var stat: String = m["stat"]
	var v: float = m["value"]
	var label: String = STAT_LABELS.get(stat, stat.capitalize())
	var sign := "+" if v >= 0.0 else ""
	if m["kind"] == "pct" or stat in PERCENT_STATS:
		return "%s%d%% %s" % [sign, roundi(v * 100.0), label]
	if absf(v) < 10.0 and absf(v - roundf(v)) > 0.05:
		return "%s%.1f %s" % [sign, v, label]
	return "%s%d %s" % [sign, roundi(v), label]
