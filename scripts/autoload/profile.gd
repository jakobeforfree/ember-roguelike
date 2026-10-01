extends Node
## Persistent player progression: gear inventory, equipped items, currency, records.
## Saved as JSON locally. A cloud-save backend can later sync `to_dict()/load_dict()`.

signal changed

const SAVE_VERSION := 1
const MAX_INVENTORY := 60

var save_path := "user://profile.json"
var character_id := "wanderer"
var gold := 0
var inventory: Array = []        # Array[GearItem]
var equipped := {}               # slot -> uid
var best_stage := 0
var best_room := 0
var total_runs := 0


func _ready() -> void:
	load_profile()


func reset() -> void:
	gold = 0
	inventory.clear()
	equipped.clear()
	best_stage = 0
	best_room = 0
	total_runs = 0
	ensure_starter_gear()


func ensure_starter_gear() -> void:
	if get_equipped("weapon") != null:
		return
	var rng := RandomNumberGenerator.new()
	var bow := LootGenerator.generate(rng, 1, Rarity.COMMON, "weapon")
	bow.weapon_id = "bow"
	bow.name = "Ashwood Bow"
	add_item(bow)
	equip(bow.uid)


func find_item(uid: String) -> GearItem:
	for it in inventory:
		if it.uid == uid:
			return it
	return null


func add_item(item: GearItem) -> void:
	inventory.append(item)
	changed.emit()


func equip(uid: String) -> void:
	var it := find_item(uid)
	if it == null:
		return
	equipped[it.slot] = uid
	changed.emit()


func unequip(slot: String) -> void:
	if slot == "weapon":
		return  # always keep a weapon
	equipped.erase(slot)
	changed.emit()


func is_equipped(item: GearItem) -> bool:
	return equipped.get(item.slot, "") == item.uid


func get_equipped(slot: String) -> GearItem:
	if not equipped.has(slot):
		return null
	return find_item(equipped[slot])


func equipped_items() -> Array:
	var out := []
	for slot in GearDB.SLOTS:
		var it := get_equipped(slot)
		if it:
			out.append(it)
	return out


func salvage_value(item: GearItem) -> int:
	return int(5 * pow(2.2, item.rarity) * (1.0 + 0.1 * item.level))


## Turns an unequipped item into gold. Returns gold gained.
func salvage(uid: String) -> int:
	var it := find_item(uid)
	if it == null or is_equipped(it):
		return 0
	var value := salvage_value(it)
	inventory.erase(it)
	gold += value
	changed.emit()
	return value


func build_stats(upgrades: Dictionary = {}) -> Stats:
	return StatBuilder.build(character_id, equipped_items(), upgrades)


## Called when a run ends (death or retreat). Gear was banked on pickup already.
func record_run(run: RunState) -> void:
	total_runs += 1
	gold += run.gold
	if run.stage > best_stage or (run.stage == best_stage and run.room_index > best_room):
		best_stage = run.stage
		best_room = run.room_index
	save_profile()


func to_dict() -> Dictionary:
	var items := []
	for it in inventory:
		items.append(it.to_dict())
	return {"version": SAVE_VERSION, "character_id": character_id, "gold": gold,
		"inventory": items, "equipped": equipped, "best_stage": best_stage,
		"best_room": best_room, "total_runs": total_runs}


func load_dict(d: Dictionary) -> void:
	character_id = d.get("character_id", "wanderer")
	gold = int(d.get("gold", 0))
	inventory.clear()
	for item_d in d.get("inventory", []):
		inventory.append(GearItem.from_dict(item_d))
	equipped = d.get("equipped", {})
	best_stage = int(d.get("best_stage", 0))
	best_room = int(d.get("best_room", 0))
	total_runs = int(d.get("total_runs", 0))
	ensure_starter_gear()
	changed.emit()


func save_profile() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save profile: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(to_dict()))


func load_profile() -> void:
	if not FileAccess.file_exists(save_path):
		reset()
		save_profile()
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f else null
	if parsed is Dictionary:
		load_dict(parsed)
	else:
		push_warning("Profile corrupt, starting fresh")
		reset()
