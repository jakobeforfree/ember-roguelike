class_name GearItem
extends RefCounted
## A single piece of gear. Serializes to a plain Dictionary for saving
## (and later, cloud saves / trading / crafting inputs).

var uid: String = ""
var slot: String = "helmet"
var name: String = ""
var rarity: int = Rarity.COMMON
var level: int = 1
var weapon_id: String = ""      # only for weapons
var mods: Array = []            # [{stat, kind, value}] implicit + affixes
var specials: Array = []        # [{id, name, desc, stat, kind, value}]


func all_mods() -> Array:
	var out := mods.duplicate()
	for s in specials:
		out.append({"stat": s["stat"], "kind": s["kind"], "value": s["value"]})
	return out


func display_name() -> String:
	return "%s %s" % [Rarity.name_of(rarity), name]


func describe_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for m in mods:
		lines.append(GearDB.describe_mod(m))
	for s in specials:
		var shown: float = s["value"] * s.get("fmt", 1.0)
		lines.append("★ %s: %s" % [s["name"], s["desc"] % roundi(shown)])
	return lines


## Rough power score used for sorting / auto-compare.
func power() -> float:
	return (rarity + 1) * 10.0 + level * 2.0 + specials.size() * 15.0


func to_dict() -> Dictionary:
	return {"uid": uid, "slot": slot, "name": name, "rarity": rarity, "level": level,
		"weapon_id": weapon_id, "mods": mods, "specials": specials}


static func from_dict(d: Dictionary) -> GearItem:
	var it := GearItem.new()
	it.uid = d.get("uid", "")
	it.slot = d.get("slot", "helmet")
	it.name = d.get("name", "Item")
	it.rarity = int(d.get("rarity", 0))
	it.level = int(d.get("level", 1))
	it.weapon_id = d.get("weapon_id", "")
	it.mods = d.get("mods", [])
	it.specials = d.get("specials", [])
	return it
