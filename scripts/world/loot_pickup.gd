class_name LootPickup
extends Node2D
## A gear drop on the floor. Walk over it to bank it into the persistent profile.

signal collected(item: GearItem)

var item: GearItem
var player: Player
var _t := 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if player and not player.dead and global_position.distance_to(player.global_position) < 44.0:
		collected.emit(item)
		Fx.float_text(get_parent(), global_position, item.display_name(), Rarity.color_of(item.rarity), 24)
		queue_free()


func _draw() -> void:
	var c := Rarity.color_of(item.rarity)
	var bob := sin(_t * 4.0) * 4.0
	draw_rect(Rect2(-3, -140, 6, 140), Color(c, 0.18))
	draw_circle(Vector2(0, 6), 14.0, Color(0, 0, 0, 0.3))
	var s := 14.0
	draw_colored_polygon(PackedVector2Array([Vector2(0, -s + bob), Vector2(s, bob), Vector2(0, s + bob), Vector2(-s, bob)]), c)
	draw_arc(Vector2(0, bob), 22.0 + sin(_t * 3.0) * 3.0, 0, TAU, 24, Color(c, 0.6), 2.0)
