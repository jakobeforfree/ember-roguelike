class_name Fx
extends RefCounted
## Short-lived 3D effects: rings, particle bursts, lightning and floating numbers.


static func ring(parent: Node, pos: Vector3, color: Color, radius: float = 1.0, time: float = 0.35) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.torus(0.8, 1.0)
	var mat := Mats.fx(Color(color, 0.9), true)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, 0.08, 0)
	mi.scale = Vector3(radius * 0.3, 0.1, radius * 0.3)
	parent.add_child(mi)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(radius, 0.1, radius), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, time)
	tw.chain().tween_callback(mi.queue_free)


static func burst(parent: Node, pos: Vector3, color: Color, size: float = 1.0, amount: int = 16) -> void:
	if DisplayServer.get_name() == "headless":
		return  # particles need a real renderer
	var p := CPUParticles3D.new()
	p.position = pos + Vector3(0, 0.6, 0)
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.55
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 2.5 * size
	p.initial_velocity_max = 6.0 * size
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.mesh = Models.box(Vector3.ONE * 0.12 * size)
	p.material_override = Mats.glow(color, 2.5)
	p.emitting = true
	parent.add_child(p)
	parent.get_tree().create_timer(1.0, false).timeout.connect(p.queue_free)


static func bolt(parent: Node, from: Vector3, to: Vector3, color: Color) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	var mat := Mats.fx(Color(color, 1.0), true)
	var pts := [from + Vector3(0, 1, 0)]
	var seg := 6
	var side := (to - from).cross(Vector3.UP).normalized()
	for i in range(1, seg):
		pts.append(from.lerp(to, float(i) / seg) + Vector3(0, 1, 0) + side * randf_range(-0.35, 0.35) + Vector3(0, randf_range(-0.2, 0.2), 0))
	pts.append(to + Vector3(0, 1, 0))
	for i in seg:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var mi := MeshInstance3D.new()
		mi.mesh = Models.box(Vector3(0.07, 0.07, a.distance_to(b)))
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		mi.position = (a + b) * 0.5
		mi.look_at(b + Vector3(0.0001, 0, 0), Vector3.UP)
	var tw := root.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(root.queue_free)


static func text(parent: Node, pos: Vector3, s: String, color: Color, size: int = 48) -> void:
	var l := Label3D.new()
	l.text = s
	l.font = UiKit.font(800)
	l.font_size = size
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	l.pixel_size = 0.008
	l.render_priority = 10
	l.position = pos + Vector3(randf_range(-0.3, 0.3), 2.0, 0)
	parent.add_child(l)
	l.scale = Vector3.ONE * 0.6
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y + 1.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)
