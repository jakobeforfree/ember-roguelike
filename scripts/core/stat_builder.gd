class_name StatBuilder
extends RefCounted
## Combines every power source into one Stats object for the player.


static func build(character_id: String, gear: Array, upgrades: Dictionary) -> Stats:
	var ch := CharacterDB.get_def(character_id)
	var stats := Stats.new(ch["base"])
	var weapon_id: String = ch["default_weapon"]
	for item in gear:
		if item.slot == "weapon" and item.weapon_id != "":
			weapon_id = item.weapon_id
	var wdef := WeaponDB.get_def(weapon_id)
	for k in wdef["base"]:
		stats.set_base(k, wdef["base"][k])
	for item in gear:
		stats.add_mods(item.all_mods())
	for id in upgrades:
		for i in upgrades[id]:
			stats.add_mods(UpgradeDB.mods_of(id))
	return stats


static func weapon_id_for(character_id: String, gear: Array) -> String:
	for item in gear:
		if item.slot == "weapon" and item.weapon_id != "":
			return item.weapon_id
	return CharacterDB.get_def(character_id)["default_weapon"]
