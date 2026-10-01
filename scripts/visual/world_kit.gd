class_name WorldKit
extends RefCounted
## Shared lighting/post setup so every 3D scene has the same moody, modern look.


static func setup(parent: Node, ambient := Color("4b5578"), bg := Color("0b0d14"), sun_color := Color("ffe4c7")) -> DirectionalLight3D:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_light_color = bg.lightened(0.05)
	env.fog_density = 0.008
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -30, 0)
	sun.light_color = sun_color
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 45.0
	parent.add_child(sun)
	return sun


## Ambient weather drifting over an area: embers rise, snow falls, spores and motes float.
static func weather(parent: Node3D, kind: String, area: Rect2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(area.size.x * 0.5 + 4.0, 0.5, area.size.y * 0.5 + 4.0)
	p.position = Vector3(area.get_center().x, 0.0, area.get_center().y)
	p.spread = 25.0
	var color := Color.WHITE
	var size := 0.05
	match kind:
		"embers":
			p.position.y = 0.2
			p.direction = Vector3.UP
			p.gravity = Vector3(0.3, 0.35, 0)
			p.initial_velocity_min = 0.3
			p.initial_velocity_max = 0.9
			color = Color("ff9a4d")
			p.material_override = Mats.glow(color, 4.0)
		"snow":
			p.position.y = 9.0
			p.direction = Vector3.DOWN
			p.gravity = Vector3(0.4, -0.6, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.6
			size = 0.06
			p.material_override = Mats.solid(Color("e8f4ff"), 0.6)
		"spores":
			p.position.y = 1.2
			p.direction = Vector3.UP
			p.gravity = Vector3(0.15, 0.05, 0.1)
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.25
			p.material_override = Mats.glow(Color("bef264"), 2.5)
		_:
			p.position.y = 1.0
			p.direction = Vector3.UP
			p.gravity = Vector3(0, 0.15, 0)
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.4
			p.material_override = Mats.glow(Color("d8b4fe"), 3.0)
	p.mesh = Models.sphere(size, 4, 2)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
