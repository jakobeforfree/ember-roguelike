class_name LootGenerator
extends RefCounted
## Creates random gear. Pure function of RNG + params so it is easy to test,
## and later reusable for shops, crafting and daily-challenge rewards.

static var _counter := 0


static func make_uid(rng: RandomNumberGenerator) -> String:
	_counter += 1
	return "%x%x%x" % [Time.get_unix_time_from_system(), _counter, rng.randi() % 0xffff]


static func generate(rng: RandomNumberGenerator, level: int, rarity: int = -1, slot: String = "") -> GearItem:
	if rarity < 0:
		rarity = Rarity.roll(rng)
	if slot == "":
		slot = GearDB.SLOTS[rng.randi() % GearDB.SLOTS.size()]
	var it := GearItem.new()
	it.uid = make_uid(rng)
	it.slot = slot
	it.rarity = rarity
	it.level = maxi(1, level)
	var scale := Rarity.mult_of(rarity) * (1.0 + 0.12 * (it.level - 1))
	var info: Dictionary = GearDB.SLOT_INFO[slot]

	if slot == "weapon":
		var ids := WeaponDB.ids()
		it.weapon_id = ids[rng.randi() % ids.size()]
		var names: Array = WeaponDB.get_def(it.weapon_id)["item_names"]
		it.name = names[rng.randi() % names.size()]
	else:
		var names: Array = info["names"]
		it.name = names[rng.randi() % names.size()]

	var implicit: Dictionary = info["implicit"]
	it.mods.append(_scaled(implicit, scale))

	var pool := GearDB.AFFIXES.duplicate()
	pool.shuffle()  # uses global rng; fine for variety, deterministic enough for tests
	var affix_count: int = Rarity.TIERS[rarity]["affixes"]
	for i in mini(affix_count, pool.size()):
		it.mods.append(_scaled(pool[i], scale * rng.randf_range(0.8, 1.2)))

	var specials := GearDB.SPECIALS.duplicate()
	specials.shuffle()
	var special_count: int = Rarity.TIERS[rarity]["specials"]
	var special_scale := 1.0 + 0.5 * (rarity - Rarity.EPIC)
	for i in mini(special_count, specials.size()):
		var s: Dictionary = specials[i].duplicate()
		s["value"] = s["value"] * special_scale
		it.specials.append(s)
	return it


static func _scaled(m: Dictionary, scale: float) -> Dictionary:
	return {"stat": m["stat"], "kind": m["kind"], "value": snappedf(m["value"] * scale, 0.001)}
