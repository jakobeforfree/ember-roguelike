class_name Rarity
extends RefCounted
## Gear rarity tiers. Higher tiers scale stats, roll more affixes and gain special abilities.

enum { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

const TIERS := [
	{"name": "Common",    "color": Color("b8b8b8"), "mult": 1.0, "affixes": 0, "specials": 0, "weight": 60.0},
	{"name": "Uncommon",  "color": Color("5fd35f"), "mult": 1.3, "affixes": 1, "specials": 0, "weight": 25.0},
	{"name": "Rare",      "color": Color("4aa3ff"), "mult": 1.7, "affixes": 2, "specials": 0, "weight": 10.0},
	{"name": "Epic",      "color": Color("b05cff"), "mult": 2.2, "affixes": 2, "specials": 1, "weight": 4.0},
	{"name": "Legendary", "color": Color("ffae2b"), "mult": 2.9, "affixes": 3, "specials": 1, "weight": 0.9},
	{"name": "Mythic",    "color": Color("ff4d6d"), "mult": 3.8, "affixes": 3, "specials": 2, "weight": 0.1},
]


static func count() -> int:
	return TIERS.size()


static func name_of(r: int) -> String:
	return TIERS[r]["name"]


static func color_of(r: int) -> Color:
	return TIERS[r]["color"]


static func mult_of(r: int) -> float:
	return TIERS[r]["mult"]


## Rolls a rarity. `luck` >= 0 shifts weight toward higher tiers; `min_rarity` floors it.
static func roll(rng: RandomNumberGenerator, luck: float = 0.0, min_rarity: int = COMMON) -> int:
	var weights := []
	var total := 0.0
	for i in TIERS.size():
		var w: float = TIERS[i]["weight"] * pow(1.0 + luck, i)
		if i < min_rarity:
			w = 0.0
		weights.append(w)
		total += w
	var pick := rng.randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return i
	return weights.size() - 1
