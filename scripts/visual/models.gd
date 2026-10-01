class_name Models
extends RefCounted
## Stylized low-poly placeholder models built from primitives. All models face -Z.
## Swap any of these for imported .glb art later: entities only need a Node3D.


static func part(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func sphere(r: float, segs: int = 12, rings: int = 6) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cyl(top: float, bottom: float, h: float, segs: int = 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 3
	return m


static func torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 32
	m.ring_segments = 6
	return m


## Flat ring on the ground used to mark an actor's footprint.
static func ground_ring(parent: Node3D, r: float, color: Color) -> MeshInstance3D:
	var ring := part(parent, torus(r - 0.05, r), Mats.fx(Color(color, 0.55), true), Vector3(0, 0.03, 0))
	ring.scale = Vector3(1, 0.15, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring


static func player(with_ring: bool = true) -> Node3D:
	var root := Node3D.new()
	var cloak := Mats.solid(Color("c2410c"))
	var dark := Mats.solid(Color("3b2a26"))
	var trim := Mats.solid(Color("f3d9b1"), 0.6)
	part(root, capsule(0.11, 0.55), dark, Vector3(-0.13, 0.28, 0))
	part(root, capsule(0.11, 0.55), dark, Vector3(0.13, 0.28, 0))
	part(root, cyl(0.2, 0.42, 0.85, 8), cloak, Vector3(0, 0.78, 0))
	part(root, cyl(0.21, 0.22, 0.06, 8), trim, Vector3(0, 1.2, 0))
	part(root, sphere(0.21), Mats.solid(Color("2a1d1a"), 0.8), Vector3(0, 1.36, 0))
	part(root, cyl(0.0, 0.27, 0.5, 8), cloak, Vector3(0, 1.52, 0.04))
	part(root, sphere(0.045, 6, 3), Mats.glow(Color("ffd36b"), 2.5), Vector3(-0.08, 1.37, -0.19))
	part(root, sphere(0.045, 6, 3), Mats.glow(Color("ffd36b"), 2.5), Vector3(0.08, 1.37, -0.19))
	part(root, torus(0.2, 0.26), Mats.glow(Color("ff7a3d"), 2.0), Vector3(0, 1.17, 0), Vector3.ZERO, Vector3(1, 0.5, 1))
	# Bow held forward-left: two limbs and a glowing string.
	var bow := Node3D.new()
	bow.position = Vector3(-0.38, 0.95, -0.25)
	root.add_child(bow)
	var wood := Mats.solid(Color("8b5a2b"), 0.5)
	part(bow, capsule(0.035, 0.6), wood, Vector3(0, 0.26, -0.06), Vector3(-20, 0, 0))
	part(bow, capsule(0.035, 0.6), wood, Vector3(0, -0.26, -0.06), Vector3(20, 0, 0))
	part(bow, box(Vector3(0.012, 1.0, 0.012)), Mats.glow(Color("ffc56b"), 2.0), Vector3(0, 0, 0.04))
	if with_ring:
		ground_ring(root, 0.6, Color("2dd4bf"))
	return root


static func grunt(color: Color) -> Node3D:
	var root := Node3D.new()
	var body := Mats.solid(color.darkened(0.15))
	part(root, sphere(0.55, 10, 5), body, Vector3(0, 0.62, 0), Vector3.ZERO, Vector3(1, 0.85, 0.9))
	part(root, sphere(0.36, 10, 5), Mats.solid(color.lightened(0.15)), Vector3(0, 0.55, -0.22), Vector3.ZERO, Vector3(1, 0.9, 0.7))
	var bone := Mats.solid(Color("f5e6c8"), 0.5)
	part(root, cyl(0.0, 0.1, 0.4, 6), bone, Vector3(-0.28, 1.08, -0.05), Vector3(0, 0, 28))
	part(root, cyl(0.0, 0.1, 0.4, 6), bone, Vector3(0.28, 1.08, -0.05), Vector3(0, 0, -28))
	part(root, sphere(0.07, 6, 3), Mats.glow(Color("fde047"), 3.0), Vector3(-0.17, 0.82, -0.45))
	part(root, sphere(0.07, 6, 3), Mats.glow(Color("fde047"), 3.0), Vector3(0.17, 0.82, -0.45))
	var fist := Mats.solid(color.darkened(0.4))
	part(root, sphere(0.2, 8, 4), fist, Vector3(-0.58, 0.5, -0.22))
	part(root, sphere(0.2, 8, 4), fist, Vector3(0.58, 0.5, -0.22))
	part(root, box(Vector3(0.22, 0.2, 0.3)), fist, Vector3(-0.22, 0.1, 0))
	part(root, box(Vector3(0.22, 0.2, 0.3)), fist, Vector3(0.22, 0.1, 0))
	return root


static func spitter(color: Color) -> Node3D:
	var root := Node3D.new()
	var hover := Node3D.new()
	hover.name = "Hover"
	hover.position.y = 1.0
	root.add_child(hover)
	part(hover, sphere(0.42, 6, 3), Mats.solid(color.darkened(0.2), 0.4), Vector3.ZERO)
	var spike := Mats.solid(color.lightened(0.2), 0.4)
	for i in 5:
		var a := i * TAU / 5.0
		part(hover, cyl(0.0, 0.1, 0.38, 5), spike, Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4), Vector3(0, -rad_to_deg(a), -90 + 0))
	part(hover, sphere(0.16, 8, 4), Mats.glow(Color("f0abfc"), 4.0), Vector3(0, 0.02, -0.34))
	part(hover, sphere(0.07, 6, 3), Mats.solid(Color("1e1b2e")), Vector3(0, 0.02, -0.47))
	var ring := part(root, torus(0.3, 0.38), Mats.glow(color, 2.5), Vector3(0, 0.2, 0))
	ring.scale = Vector3(1, 0.3, 1)
	return root


static func charger(color: Color) -> Node3D:
	var root := Node3D.new()
	var hide := Mats.solid(color.darkened(0.35))
	part(root, box(Vector3(0.85, 0.65, 1.25)), hide, Vector3(0, 0.62, 0.1))
	part(root, box(Vector3(0.65, 0.55, 0.55)), Mats.solid(color.darkened(0.1)), Vector3(0, 0.62, -0.72))
	var tusk := Mats.solid(Color("fff7e6"), 0.4)
	part(root, cyl(0.0, 0.07, 0.45, 6), tusk, Vector3(-0.22, 0.5, -1.05), Vector3(-80, 0, 0))
	part(root, cyl(0.0, 0.07, 0.45, 6), tusk, Vector3(0.22, 0.5, -1.05), Vector3(-80, 0, 0))
	part(root, sphere(0.06, 6, 3), Mats.glow(Color("ef4444"), 3.5), Vector3(-0.18, 0.75, -1.0))
	part(root, sphere(0.06, 6, 3), Mats.glow(Color("ef4444"), 3.5), Vector3(0.18, 0.75, -1.0))
	var plate := Mats.solid(Color("57534e"), 0.5, 0.3)
	for i in 3:
		part(root, cyl(0.0, 0.14, 0.35, 5), plate, Vector3(0, 1.05, -0.3 + i * 0.35), Vector3(-15, 0, 0))
	var leg := Mats.solid(Color("292524"))
	for x in [-0.3, 0.3]:
		for z in [-0.35, 0.5]:
			part(root, box(Vector3(0.18, 0.35, 0.2)), leg, Vector3(x, 0.17, z))
	return root


static func boss(color: Color) -> Node3D:
	var root := Node3D.new()
	var rock := Mats.solid(Color("3a3335"), 0.9)
	var rock2 := Mats.solid(Color("4b4245"), 0.9)
	var magma := Mats.glow(color, 4.0)
	part(root, box(Vector3(0.6, 1.0, 0.6)), rock, Vector3(-0.55, 0.5, 0))
	part(root, box(Vector3(0.6, 1.0, 0.6)), rock, Vector3(0.55, 0.5, 0))
	part(root, sphere(1.15, 7, 4), rock2, Vector3(0, 1.95, 0), Vector3.ZERO, Vector3(1.05, 0.9, 0.85))
	var core := part(root, sphere(0.5, 10, 5), magma, Vector3(0, 2.0, -0.72))
	core.name = "Core"
	part(root, box(Vector3(0.08, 1.4, 0.05)), magma, Vector3(0.45, 2.0, -0.9), Vector3(0, 0, 25))
	part(root, box(Vector3(0.08, 1.1, 0.05)), magma, Vector3(-0.5, 1.8, -0.88), Vector3(0, 0, -30))
	part(root, box(Vector3(0.85, 0.7, 0.75)), rock, Vector3(0, 3.15, -0.1), Vector3(0, 0, 0))
	part(root, box(Vector3(0.16, 0.08, 0.05)), Mats.glow(Color("fde047"), 5.0), Vector3(-0.2, 3.2, -0.49))
	part(root, box(Vector3(0.16, 0.08, 0.05)), Mats.glow(Color("fde047"), 5.0), Vector3(0.2, 3.2, -0.49))
	for x in [-1.3, 1.3]:
		part(root, sphere(0.6, 6, 3), rock2, Vector3(x, 2.6, 0))
		part(root, capsule(0.33, 1.7), rock, Vector3(x * 1.05, 1.5, -0.1))
		part(root, sphere(0.5, 6, 3), rock2, Vector3(x * 1.08, 0.6, -0.2))
		part(root, cyl(0.0, 0.18, 0.5, 5), magma, Vector3(x, 3.05, 0), Vector3(0, 0, -x * 12))
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 6.0
	light.position = Vector3(0, 2.0, -1.4)
	root.add_child(light)
	return root


static func loot(color: Color) -> Node3D:
	var root := Node3D.new()
	var gem := Node3D.new()
	gem.name = "Gem"
	gem.position.y = 0.9
	root.add_child(gem)
	var g := sphere(0.3, 4, 2)
	g.height = 0.75
	part(gem, g, Mats.glow(color, 2.5))
	var beam := part(root, cyl(0.07, 0.07, 5.0, 8), Mats.fx(Color(color, 0.28), true), Vector3(0, 2.5, 0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_ring(root, 0.55, color)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position.y = 1.0
	root.add_child(light)
	return root


static func brazier(parent: Node3D, pos: Vector3) -> OmniLight3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	part(root, cyl(0.32, 0.2, 0.25, 8), Mats.solid(Color("44403c"), 0.4, 0.6), Vector3(0, 0, 0))
	part(root, cyl(0.0, 0.22, 0.55, 6), Mats.glow(Color("ff7a1a"), 3.0), Vector3(0, 0.38, 0))
	part(root, cyl(0.0, 0.12, 0.4, 6), Mats.glow(Color("ffd36b"), 4.0), Vector3(0, 0.36, 0))
	var light := OmniLight3D.new()
	light.light_color = Color("ff9a4d")
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.omni_attenuation = 1.2
	light.position.y = 0.8
	root.add_child(light)
	return light


static func campfire(parent: Node3D) -> OmniLight3D:
	var stone := Mats.solid(Color("57534e"), 0.9)
	for i in 9:
		var a := i * TAU / 9.0
		part(parent, sphere(0.22, 6, 3), stone, Vector3(cos(a) * 0.7, 0.08, sin(a) * 0.7), Vector3(0, i * 37, 0), Vector3(1, 0.6, 1))
	var wood := Mats.solid(Color("5b3a1e"))
	for i in 3:
		part(parent, cyl(0.08, 0.08, 1.0, 6), wood, Vector3(0, 0.12, 0), Vector3(90, i * 60, 0))
	part(parent, cyl(0.0, 0.35, 0.9, 6), Mats.glow(Color("ff5a1f"), 3.0), Vector3(0, 0.5, 0))
	part(parent, cyl(0.0, 0.22, 0.7, 6), Mats.glow(Color("ffb347"), 4.0), Vector3(0.05, 0.45, 0.02))
	part(parent, cyl(0.0, 0.1, 0.45, 6), Mats.glow(Color("fff1b8"), 5.0), Vector3(0, 0.35, 0))
	var light := OmniLight3D.new()
	light.light_color = Color("ff8a3d")
	light.light_energy = 3.0
	light.omni_range = 12.0
	light.shadow_enabled = true
	light.position.y = 1.0
	parent.add_child(light)
	if DisplayServer.get_name() == "headless":
		return light
	var embers := CPUParticles3D.new()
	embers.amount = 40
	embers.lifetime = 2.2
	embers.position.y = 0.6
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.3
	embers.direction = Vector3.UP
	embers.spread = 20.0
	embers.gravity = Vector3(0, 0.6, 0)
	embers.initial_velocity_min = 0.5
	embers.initial_velocity_max = 1.4
	embers.scale_amount_min = 0.5
	embers.scale_amount_max = 1.0
	embers.mesh = sphere(0.025, 4, 2)
	embers.material_override = Mats.glow(Color("ffb347"), 6.0)
	parent.add_child(embers)
	return light
