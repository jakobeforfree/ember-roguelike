class_name LorePickup
extends Node3D
## A lost journal page lying on the floor. Walk over it to add it to the Journal.

signal collected(page_id: String)

var page_id := ""
var player: Player
var _scroll: Node3D
var _t := 0.0


func _ready() -> void:
	_scroll = Node3D.new()
	_scroll.position.y = 0.8
	add_child(_scroll)
	Models.part(_scroll, Models.cyl(0.09, 0.09, 0.55, 10), Mats.solid(Color("efe2c4"), 0.8), Vector3.ZERO, Vector3(0, 0, 90))
	Models.part(_scroll, Models.cyl(0.11, 0.11, 0.06, 10), Mats.solid(Color("8b5a2b")), Vector3(-0.3, 0, 0), Vector3(0, 0, 90))
	Models.part(_scroll, Models.cyl(0.11, 0.11, 0.06, 10), Mats.solid(Color("8b5a2b")), Vector3(0.3, 0, 0), Vector3(0, 0, 90))
	Models.part(_scroll, Models.box(Vector3(0.12, 0.02, 0.2)), Mats.glow(Color("ffcf7a"), 3.0), Vector3(0, 0.0, -0.08))
	Models.ground_ring(self, 0.55, Color("ffcf7a"))
	var light := OmniLight3D.new()
	light.light_color = Color("ffcf7a")
	light.light_energy = 1.0
	light.omni_range = 3.0
	light.position.y = 1.0
	add_child(light)


func _physics_process(delta: float) -> void:
	_t += delta
	_scroll.rotation.y += delta * 1.5
	_scroll.position.y = 0.8 + sin(_t * 3.0) * 0.1
	if player and not player.dead and Flat.dist(global_position, player.global_position) < 1.1:
		collected.emit(page_id)
		Fx.ring(get_parent(), global_position, Color("ffcf7a"), 2.0, 0.4)
		queue_free()
