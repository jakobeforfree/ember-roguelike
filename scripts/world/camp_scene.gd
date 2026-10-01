class_name CampScene
extends Node3D
## 3D backdrop for the camp menu: the hero resting by a campfire at night.

var hero: Node3D
var fire_light: OmniLight3D
var camera: Camera3D
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

	var fire := Node3D.new()
	fire.position = Vector3(1.7, 0, -0.4)
	add_child(fire)
	fire_light = Models.campfire(fire)

	hero = Models.player(false)
	hero.position = Vector3(-0.2, 0, 0.7)
	hero.rotation.y = Flat.yaw(Vector3(0.35, 0, 1.0))
	add_child(hero)

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
		var s := rng.randf_range(0.8, 1.4)
		tree.scale = Vector3.ONE * s
		add_child(tree)
		Models.part(tree, Models.cyl(0.12, 0.16, 1.0, 6), trunk, Vector3(0, 0.5, 0))
		for k in 3:
			Models.part(tree, Models.cyl(0.0, 1.1 - k * 0.25, 1.3, 7), leaves[(i + k) % 3], Vector3(0, 1.4 + k * 0.75, 0))
	var rock := Mats.solid(Color("3a3d45"), 0.95)
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(3.0, 8.0)
		Models.part(self, Models.sphere(rng.randf_range(0.2, 0.5), 5, 3), rock, Vector3(cos(a) * d, 0.05, sin(a) * d - 1.0), Vector3(0, rng.randf() * 180, 0), Vector3(1, 0.6, 1))
	# Tent
	var tent := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.4, 1.8, 2.6)
	tent.mesh = prism
	tent.material_override = Mats.solid(Color("4a2a20"), 0.95)
	tent.position = Vector3(-3.6, 0.9, -3.2)
	tent.rotation_degrees.y = 25
	add_child(tent)
	# Log seat
	Models.part(self, Models.cyl(0.22, 0.22, 1.6, 8), Mats.solid(Color("4a3020")), Vector3(1.2, 0.22, 1.2), Vector3(0, 30, 90))

	camera = Camera3D.new()
	camera.fov = 38.0
	camera.position = Vector3(0.6, 2.7, 7.4)
	add_child(camera)
	camera.look_at(Vector3(0.6, 1.0, 0.0))
	camera.current = true


func _process(delta: float) -> void:
	_t += delta
	fire_light.light_energy = 2.8 + sin(_t * 8.0) * 0.25 + sin(_t * 21.0) * 0.15
	hero.position.y = sin(_t * 2.0) * 0.015
	camera.position.x = 0.6 + sin(_t * 0.2) * 0.25
