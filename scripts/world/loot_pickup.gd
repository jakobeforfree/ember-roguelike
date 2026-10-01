class_name LootPickup
extends Node3D
## A gear drop on the floor. Walk over it to bank it into the persistent profile.

signal collected(item: GearItem)

var item: GearItem
var player: Player
var _gem: Node3D
var _t := 0.0


func _ready() -> void:
	var m := Models.loot(Rarity.color_of(item.rarity))
	add_child(m)
	_gem = m.get_node("Gem")


func _physics_process(delta: float) -> void:
	_t += delta
	_gem.rotation.y += delta * 2.0
	_gem.position.y = 0.9 + sin(_t * 3.0) * 0.12
	if player and not player.dead and Flat.dist(global_position, player.global_position) < 1.1:
		collected.emit(item)
		Fx.text(get_parent(), global_position + Vector3(0, 0.5, 0), item.name, Rarity.color_of(item.rarity), 52)
		Fx.ring(get_parent(), global_position, Rarity.color_of(item.rarity), 2.0, 0.4)
		queue_free()
