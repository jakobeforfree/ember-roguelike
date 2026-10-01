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


## The hero: a lonely traveling wizard. The wide-brimmed, bent hat is the key
## silhouette from the top-down camera. "Hand" holds the equipped weapon model.
static func wizard(weapon_id: String = "staff", with_ring: bool = true) -> Node3D:
	var root := Node3D.new()
	var robe := Mats.solid(Color("2f3d6b"), 0.85)
	var robe_dark := Mats.solid(Color("222c4f"), 0.9)
	var gold := Mats.solid(Color("d4a24c"), 0.35, 0.6)
	var leather := Mats.solid(Color("6b4426"), 0.7)
	var skin := Mats.solid(Color("e9b98f"), 0.7)
	var ember := Mats.solid(Color("e8692e"), 0.8)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	# Boots and robe
	part(body, box(Vector3(0.14, 0.14, 0.26)), Mats.solid(Color("3b2a1e")), Vector3(-0.12, 0.07, -0.04))
	part(body, box(Vector3(0.14, 0.14, 0.26)), Mats.solid(Color("3b2a1e")), Vector3(0.12, 0.07, -0.04))
	part(body, cyl(0.21, 0.46, 1.0, 10), robe, Vector3(0, 0.62, 0))
	part(body, cyl(0.47, 0.47, 0.06, 10), gold, Vector3(0, 0.14, 0))
	part(body, box(Vector3(0.06, 0.8, 0.02)), gold, Vector3(0, 0.58, -0.33), Vector3(-17, 0, 0))
	part(body, cyl(0.24, 0.24, 0.07, 10), leather, Vector3(0, 0.98, 0))
	part(body, box(Vector3(0.09, 0.08, 0.03)), gold, Vector3(0, 0.98, -0.24))
	part(body, cyl(0.19, 0.24, 0.34, 10), robe, Vector3(0, 1.15, 0))
	# Satchel + strap
	part(body, box(Vector3(0.2, 0.22, 0.09)), leather, Vector3(-0.3, 0.86, 0.06), Vector3(0, 0, 8))
	part(body, box(Vector3(0.04, 0.62, 0.03)), leather, Vector3(-0.05, 1.08, -0.2), Vector3(0, 0, 38))
	# Arms: left hangs, right reaches forward to hold the weapon
	part(body, capsule(0.085, 0.5), robe_dark, Vector3(-0.3, 1.02, 0.02), Vector3(0, 0, 14))
	part(body, sphere(0.07, 8, 4), skin, Vector3(-0.36, 0.78, 0.0))
	part(body, capsule(0.085, 0.5), robe_dark, Vector3(0.31, 1.04, -0.12), Vector3(-45, 0, -10))
	# Scarf with a fluttering tail
	part(body, torus(0.15, 0.24), ember, Vector3(0, 1.31, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
	var tail := Node3D.new()
	tail.name = "ScarfTail"
	tail.position = Vector3(0.1, 1.3, 0.18)
	body.add_child(tail)
	part(tail, box(Vector3(0.1, 0.42, 0.03)), ember, Vector3(0, -0.2, 0.02))
	# Head, nose, beard
	part(body, sphere(0.17, 10, 6), skin, Vector3(0, 1.46, 0))
	part(body, sphere(0.045, 6, 3), skin, Vector3(0, 1.44, -0.17))
	part(body, cyl(0.17, 0.02, 0.58, 8), Mats.solid(Color("f1ede6"), 0.9), Vector3(0, 1.16, -0.12), Vector3(-12, 0, 0))
	part(body, box(Vector3(0.24, 0.05, 0.06)), Mats.solid(Color("e7e2d8"), 0.9), Vector3(0, 1.39, -0.17), Vector3(0, 0, 0))
	part(body, sphere(0.028, 6, 3), Mats.glow(Color("ffcf7a"), 2.5), Vector3(-0.065, 1.5, -0.15))
	part(body, sphere(0.028, 6, 3), Mats.glow(Color("ffcf7a"), 2.5), Vector3(0.065, 1.5, -0.15))
	# Hat: wide brim, ember band and a tall bent tip
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 1.58, 0)
	body.add_child(hat)
	var hat_mat := Mats.solid(Color("26335c"), 0.85)
	part(hat, cyl(0.52, 0.55, 0.05, 16), hat_mat, Vector3(0, 0, 0))
	part(hat, cyl(0.25, 0.27, 0.09, 12), Mats.glow(Color("ff7a3d"), 0.8), Vector3(0, 0.07, 0))
	part(hat, cyl(0.15, 0.25, 0.38, 12), hat_mat, Vector3(0, 0.22, 0))
	part(hat, cyl(0.07, 0.15, 0.28, 10), hat_mat, Vector3(0, 0.5, 0.05), Vector3(18, 0, 0))
	part(hat, cyl(0.0, 0.07, 0.25, 8), hat_mat, Vector3(0, 0.69, 0.16), Vector3(48, 0, 0))
	part(hat, sphere(0.035, 6, 3), Mats.glow(Color("fde68a"), 3.0), Vector3(0, 0.78, 0.26))
	part(hat, sphere(0.03, 6, 3), Mats.glow(Color("fde68a"), 2.0), Vector3(0.18, 0.25, -0.12))
	# Weapon hand
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.36, 0.86, -0.32)
	body.add_child(hand)
	part(hand, sphere(0.07, 8, 4), skin)
	set_weapon(root, weapon_id)
	if with_ring:
		ground_ring(root, 0.65, Color("2dd4bf"))
	return root


## Kept for older call sites: the hero model.
static func player(with_ring: bool = true) -> Node3D:
	return wizard("staff", with_ring)


## Replaces the weapon model held by a wizard model.
static func set_weapon(wizard_root: Node3D, weapon_id: String) -> void:
	var hand: Node3D = wizard_root.get_node("Body/Hand")
	var old := hand.get_node_or_null("Weapon")
	if old:
		old.free()
	var w := weapon(weapon_id)
	w.name = "Weapon"
	hand.add_child(w)


## Weapon models, gripped at the origin, pointing forward (-Z) or upright.
static func weapon(id: String) -> Node3D:
	var root := Node3D.new()
	var col: Color = WeaponDB.get_def(id)["color"]
	var wood := Mats.solid(Color("7a4a26"), 0.6)
	var steel := Mats.solid(Color("cbd5e1"), 0.25, 0.85)
	var gold := Mats.solid(Color("d4a24c"), 0.35, 0.6)
	match id:
		"staff":
			part(root, cyl(0.03, 0.04, 1.75, 6), wood, Vector3(0, 0.05, 0))
			part(root, torus(0.08, 0.13), wood, Vector3(0, 0.98, 0), Vector3(90, 0, 0))
			var gem := part(root, sphere(0.1, 8, 4), Mats.glow(col, 1.8), Vector3(0, 0.98, 0))
			gem.name = "Gem"
			part(root, sphere(0.17, 8, 4), Mats.fx(Color(col, 0.12), true), Vector3(0, 0.98, 0))
		"bow":
			part(root, capsule(0.035, 0.65), wood, Vector3(0, 0.28, -0.06), Vector3(-20, 0, 0))
			part(root, capsule(0.035, 0.65), wood, Vector3(0, -0.28, -0.06), Vector3(20, 0, 0))
			part(root, box(Vector3(0.012, 1.08, 0.012)), Mats.glow(col, 2.0), Vector3(0, 0, 0.05))
		"sword":
			part(root, cyl(0.03, 0.03, 0.22, 6), Mats.solid(Color("3b2a1e")), Vector3(0, 0, 0.0), Vector3(90, 0, 0))
			part(root, sphere(0.045, 6, 3), gold, Vector3(0, 0, 0.13))
			part(root, box(Vector3(0.3, 0.04, 0.06)), gold, Vector3(0, 0, -0.12))
			part(root, box(Vector3(0.08, 0.02, 0.85)), steel, Vector3(0, 0, -0.56))
			part(root, box(Vector3(0.015, 0.025, 0.7)), Mats.glow(Color("ff7a3d"), 2.0), Vector3(0, 0, -0.5))
		"daggers":
			for x in [0.0, -0.72]:
				part(root, cyl(0.025, 0.025, 0.12, 6), Mats.solid(Color("3b2a1e")), Vector3(x, 0, 0.02), Vector3(90, 0, 0))
				part(root, box(Vector3(0.14, 0.03, 0.04)), Mats.glow(col, 1.2), Vector3(x, 0, -0.06))
				part(root, box(Vector3(0.05, 0.015, 0.32)), steel, Vector3(x, 0, -0.24))
		"crossbow":
			part(root, box(Vector3(0.08, 0.09, 0.62)), wood, Vector3(0, 0, -0.1))
			part(root, box(Vector3(0.72, 0.05, 0.06)), Mats.solid(Color("57534e"), 0.5, 0.6), Vector3(0, 0.02, -0.38))
			part(root, box(Vector3(0.7, 0.01, 0.01)), Mats.glow(col, 1.5), Vector3(0, 0.03, -0.3))
			part(root, box(Vector3(0.04, 0.04, 0.5)), Mats.solid(Color("57534e")), Vector3(0, 0.07, -0.25))
		"wand":
			part(root, cyl(0.018, 0.028, 0.45, 6), Mats.solid(Color("f5f5f4"), 0.4), Vector3(0, 0, -0.2), Vector3(-90, 0, 0))
			part(root, box(Vector3(0.06, 0.06, 0.06)), gold, Vector3(0, 0, 0.0))
			var tip := part(root, sphere(0.05, 6, 3), Mats.glow(col, 5.0), Vector3(0, 0, -0.44))
			tip.name = "Gem"
		"tome":
			var book := Node3D.new()
			book.name = "Book"
			book.position = Vector3(0, 0.3, -0.05)
			book.rotation_degrees = Vector3(-20, 15, 0)
			root.add_child(book)
			part(book, box(Vector3(0.34, 0.09, 0.42)), Mats.solid(Color("312e81"), 0.6), Vector3.ZERO)
			part(book, box(Vector3(0.31, 0.07, 0.4)), Mats.solid(Color("f5f0e6"), 0.9), Vector3(0.015, 0, 0))
			part(book, box(Vector3(0.12, 0.1, 0.12)), Mats.glow(col, 3.0), Vector3(0, 0.0, 0))
	return root


## Camp prop: the wizard's pack with bedroll and a little lantern.
static func backpack() -> Node3D:
	var root := Node3D.new()
	var leather := Mats.solid(Color("7a4a26"), 0.75)
	var dark := Mats.solid(Color("4a2c16"), 0.8)
	part(root, box(Vector3(0.75, 0.85, 0.42)), leather, Vector3(0, 0.45, 0))
	part(root, sphere(0.38, 10, 5), leather, Vector3(0, 0.88, 0), Vector3.ZERO, Vector3(1, 0.45, 0.58))
	part(root, box(Vector3(0.55, 0.38, 0.14)), dark, Vector3(0, 0.38, -0.25))
	part(root, box(Vector3(0.12, 0.1, 0.03)), Mats.solid(Color("d4a24c"), 0.35, 0.6), Vector3(0, 0.5, -0.33))
	for x in [-0.22, 0.22]:
		part(root, box(Vector3(0.07, 0.9, 0.46)), dark, Vector3(x, 0.47, 0))
	part(root, cyl(0.17, 0.17, 0.95, 12), Mats.solid(Color("5b6b4e"), 0.95), Vector3(0, 1.05, 0.02), Vector3(0, 0, 90))
	part(root, cyl(0.18, 0.18, 0.05, 12), dark, Vector3(-0.3, 1.05, 0.02), Vector3(0, 0, 90))
	part(root, cyl(0.18, 0.18, 0.05, 12), dark, Vector3(0.3, 1.05, 0.02), Vector3(0, 0, 90))
	var lantern := Node3D.new()
	lantern.position = Vector3(0.48, 0.55, -0.1)
	root.add_child(lantern)
	part(lantern, box(Vector3(0.14, 0.2, 0.14)), Mats.solid(Color("44403c"), 0.4, 0.6))
	part(lantern, sphere(0.06, 6, 3), Mats.glow(Color("ffcf7a"), 4.0))
	var light := OmniLight3D.new()
	light.light_color = Color("ffb35c")
	light.light_energy = 0.8
	light.omni_range = 2.5
	lantern.add_child(light)
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
	part(root, cyl(0.0, 0.05, 0.22, 5), bone, Vector3(-0.12, 0.55, -0.48), Vector3(-70, 0, 10))
	part(root, cyl(0.0, 0.05, 0.22, 5), bone, Vector3(0.12, 0.55, -0.48), Vector3(-70, 0, -10))
	var pad := Mats.solid(Color("3f3f46"), 0.5, 0.5)
	for sx in [-1, 1]:
		part(root, sphere(0.2, 6, 3), pad, Vector3(sx * 0.42, 0.85, 0.05), Vector3.ZERO, Vector3(1, 0.6, 1))
		part(root, cyl(0.0, 0.06, 0.2, 5), bone, Vector3(sx * 0.46, 1.0, 0.05), Vector3(0, 0, -sx * 20))
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
	var tendril := Mats.solid(color.darkened(0.45), 0.6)
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		part(hover, cyl(0.06, 0.0, 0.55, 5), tendril, Vector3(cos(a) * 0.2, -0.45, sin(a) * 0.2), Vector3(cos(a) * 18, 0, sin(a) * 18))
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
