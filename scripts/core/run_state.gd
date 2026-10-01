class_name RunState
extends RefCounted
## Everything that lives only for the current run. Discarded on death.

const ROOMS_PER_STAGE := 5   # rooms 1-4 combat, room 5 boss

var rng := RandomNumberGenerator.new()
var character_id := "wanderer"
var stage := 1
var room_index := 0          # 0-based within the stage
var upgrades := {}           # id -> stacks
var gold := 0
var kills := 0
var loot: Array = []         # GearItems found this run (already banked in Profile)


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func world() -> Dictionary:
	return WorldDB.for_stage(stage)


func ascension() -> int:
	return WorldDB.ascension_for_stage(stage)


func is_boss_room() -> bool:
	return room_index == ROOMS_PER_STAGE - 1


## Smooth difficulty curve across rooms and stages.
func difficulty() -> float:
	return (stage - 1) * 2.5 + room_index * 0.5


func item_level() -> int:
	return 1 + (stage - 1) * 3 + room_index / 2


func add_upgrade(id: String) -> void:
	upgrades[id] = upgrades.get(id, 0) + 1


func advance_room() -> void:
	room_index += 1
	if room_index >= ROOMS_PER_STAGE:
		room_index = 0
		stage += 1
