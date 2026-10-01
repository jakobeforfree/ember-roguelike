class_name CampScene
extends Node3D
## 3D camp that doubles as the main menu: click the campfire to set out,
## click the backpack to manage gear. Objects highlight when hovered.

const INTERACTABLES := {
	"fire": {"pos": Vector3(1.7, 0.6, -0.4), "radius": 1.0},
	"pack": {"pos": Vector3(-1.75, 0.55, 0.55), "radius": 0.75},
}

var hero: Node3D
var fire_light: OmniLight3D
var camera: Camera3D
var pack: Node3D
var _fire_root: Node3D
var _hover := ""
var _t := 0.0


func _ready() -> void:
	var sun := WorldKit.setup(self, Color("2e3a5c"), Color("070910"))
	sun.light_energy = 0.25
	sun.light_color = Color("9fb4ff")

	var ground := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 18.0
	disc.bottom_radius = 18.0
	disc.height = 0.2
	disc.radial_segments = 48
	ground.mesh = disc
	ground.position.y = -0.1
	ground.material_override = Mats.solid(Color("161a1f"), 1.0)
	add_child(ground)

	_fire_root = Node3D.new()
	_fire_root.position = Vector3(1.7, 0, -0.4)
	add_child(_fire_root)
	fire_light = Models.campfire(_fire_root)

	hero = Models.wizard(_equipped_weapon(), false)
	hero.position = Vector3(-0.1, 0, 0.6)
	hero.rotation.y = Flat.yaw(Vector3(0.45, 0, 1.0))
	add_child(hero)
	Profile.changed.connect(_refresh_weapon)

	pack = Models.backpack()
	pack.position = Vector3(-1.75, 0, 0.55)
	pack.rotation_degrees.y = 160
	add_child(pack)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trunk := Mats.solid(Color("3b2a1e"))
	var leaves := [Mats.solid(Color("1d3b34")), Mats.solid(Color("234a3f")), Mats.solid(Color("17302b"))]
	for i in 22:
		var a := rng.randf() * TAU
		var d := rng.randf_range(6.5, 14.0)
		var pos := Vector3(cos(a) * d, 0, sin(a) * d - 2.0)
		if pos.z > 3.0 and absf(pos.x) < 6.0:
			continue  # keep the camera's view clear
		var tree := Node3D.new()
		tree.position = pos
		tree.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
		add_child(tree)
		Models.part(tree, Models.cyl(0.12, 0.16, 1.0, 6), trunk, Vector3(0, 0.5, 0))
		for k in 3:
			Models.part(tree, Models.cyl(0.0, 1.1 - k * 0.25, 1.3, 7), leaves[(i + k) % 3], Vector3(0, 1.4 + k * 0.75, 0))
	var rock := Mats.solid(Color("3a3d45"), 0.95)
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(3.2, 8.0)
		Models.part(self, Models.sphere(rng.randf_range(0.2, 0.5), 5, 3), rock, Vector3(cos(a) * d, 0.05, sin(a) * d - 1.0), Vector3(0, rng.randf() * 180, 0), Vector3(1, 0.6, 1))
	var tent := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.4, 1.8, 2.6)
	tent.mesh = prism
	tent.material_override = Mats.solid(Color("3d4352"), 0.95)
	tent.position = Vector3(-3.6, 0.9, -3.2)
	tent.rotation_degrees.y = 25
	add_child(tent)
	Models.part(self, Models.cyl(0.22, 0.22, 1.6, 8), Mats.solid(Color("4a3020")), Vector3(1.4, 0.22, 1.25), Vector3(0, 30, 90))

	camera = Camera3D.new()
	camera.fov = 38.0
	camera.position = Vector3(0.0, 2.8, 7.6)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.9, 0.0))
	camera.current = true


func _equipped_weapon() -> String:
	return StatBuilder.weapon_id_for(Profile.character_id, Profile.equipped_items())


func _refresh_weapon() -> void:
	if is_instance_valid(hero):
		Models.set_weapon(hero, _equipped_weapon())


## Screen-space circle (center, radius) for an interactable, for mouse picking and prompts.
func screen_circle(id: String) -> Array:
	var info: Dictionary = INTERACTABLES[id]
	var c: Vector3 = info["pos"]
	var center := camera.unproject_position(c)
	var edge := camera.unproject_position(c + Vector3(info["radius"], 0, 0))
	return [center, center.distance_to(edge)]


func set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	for n in [pack]:
		for m in n.find_children("*", "MeshInstance3D", true, false):
			m.material_overlay = Mats.overlay(Color(1, 0.85, 0.6, 0.18)) if id == "pack" else null
	var tw := pack.create_tween()
	tw.tween_property(pack, "scale", Vector3.ONE * (1.08 if id == "pack" else 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tf := _fire_root.create_tween()
	tf.tween_property(_fire_root, "scale", Vector3.ONE * (1.12 if id == "fire" else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	var boost := 1.6 if _hover == "fire" else 0.0
	fire_light.light_energy = 2.8 + boost + sin(_t * 8.0) * 0.25 + sin(_t * 21.0) * 0.15
	hero.position.y = sin(_t * 2.0) * 0.015
	var tail := hero.get_node_or_null("Body/ScarfTail")
	if tail:
		tail.rotation.x = 0.3 + sin(_t * 3.0) * 0.12
	camera.position.x = sin(_t * 0.2) * 0.2
