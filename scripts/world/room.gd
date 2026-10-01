class_name Room
extends Node3D
## One arena on the XZ plane: floor, walls, obstacles, enemy waves and an exit gate.
## Gameplay geometry is 2D (Rect2 in x/z meters) so navigation and hit tests stay
## simple; everything visible is built in 3D from it.

signal cleared
signal exit_reached
signal enemy_spawned(enemy: Enemy)

const NAV_CELL := 1.0
const WALL_H := 1.6
const DOOR_W := 4.0
const FLOOR_SHADER := preload("res://shaders/floor.gdshader")

## Obstacle templates: [x%, z%, width, depth] in meters.
const LAYOUTS := {
	"open": [],
	"pillars": [[0.28, 0.35, 1.8, 1.8], [0.72, 0.35, 1.8, 1.8], [0.28, 0.68, 1.8, 1.8], [0.72, 0.68, 1.8, 1.8]],
	"bar": [[0.5, 0.45, 7.5, 1.5]],
	"gates": [[0.2, 0.5, 1.5, 6.5], [0.8, 0.5, 1.5, 6.5]],
	"cross": [[0.5, 0.42, 1.5, 4.5], [0.3, 0.6, 3.5, 1.3], [0.7, 0.6, 3.5, 1.3]],
}

var bounds := Rect2(0, 0, 34, 25)
var obstacles: Array = []        # Array[Rect2] on the XZ plane
var door_rect := Rect2()
var door_open := false
var layout_name := "open"
var is_boss_room := false
var world: Dictionary = WorldDB.WORLDS[0]
var difficulty := 0.0
var waves: Array = []
var wave_index := -1
var player: Player
var rng: RandomNumberGenerator
var ground: Node3D               # telegraphs
var entities: Node3D             # player, enemies, projectiles, pickups
var alive: Array = []
var boss: Enemy
var astar: AStarGrid2D
var _exited := false
var _cleared := false
var _gate: Node3D
var _gate_body: StaticBody3D
var _portal: MeshInstance3D
var _portal_light: OmniLight3D
var _lights: Array = []
var _t := 0.0


func build(p_rng: RandomNumberGenerator, p_difficulty: float, boss_room: bool, room_index: int, p_world: Dictionary = {}) -> void:
	rng = p_rng
	if not p_world.is_empty():
		world = p_world
	difficulty = p_difficulty
	is_boss_room = boss_room
	if boss_room:
		bounds = Rect2(0, 0, 36, 28)
		layout_name = "open"
	else:
		bounds = Rect2(0, 0, rng.randi_range(31, 37), rng.randi_range(23, 28))
		var names := LAYOUTS.keys()
		layout_name = "open" if room_index == 0 else names[rng.randi() % names.size()]
	for o in LAYOUTS[layout_name]:
		var c := Vector2(bounds.size.x * o[0], bounds.size.y * o[1])
		obstacles.append(Rect2(c - Vector2(o[2], o[3]) * 0.5, Vector2(o[2], o[3])))
	door_rect = Rect2(bounds.size.x * 0.5 - DOOR_W * 0.5, 0.0, DOOR_W, 1.2)
	waves = [] if boss_room else _plan_waves(room_index)

	ground = Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	entities = Node3D.new()
	entities.name = "Entities"
	add_child(entities)
	_build_visuals()
	_build_walls()
	_build_nav()


func player_spawn() -> Vector3:
	return Vector3(bounds.size.x * 0.5, 0, bounds.size.y - 2.8)


## Budget-based wave planning: harder rooms get more and tougher enemies.
func _plan_waves(room_index: int) -> Array:
	var count := 2 if room_index < 2 else 3
	var out := []
	for w in count:
		var budget := 3.0 + difficulty * 1.3 + w
		var wave := []
		while budget >= 1.0 and wave.size() < 9:
			var pool := ["grunt", "spitter"] if room_index == 0 else EnemyDB.SPAWNABLE
			var id: String = pool[rng.randi() % pool.size()]
			var cost: int = EnemyDB.get_def(id)["cost"]
			if cost > budget:
				id = "grunt"
				cost = 1
			wave.append(id)
			budget -= cost
		out.append(wave)
	return out


func start() -> void:
	if is_boss_room:
		boss = spawn_enemy("boss", Vector3(bounds.size.x * 0.5, 0, bounds.size.y * 0.3))
		boss.connect("summon_requested", _on_boss_summon)
	else:
		_next_wave()


func _next_wave() -> void:
	wave_index += 1
	if wave_index >= waves.size():
		_on_cleared()
		return
	for id in waves[wave_index]:
		spawn_enemy(id, Flat.v3(random_spawn_point(8.5)))


func _on_boss_summon(ids: Array, near: Vector3) -> void:
	for id in ids:
		var p := Flat.xz(near) + Vector2.from_angle(rng.randf() * TAU) * 3.5
		spawn_enemy(id, Flat.v3(clamp_point(p, 1.0)))


func spawn_enemy(id: String, pos: Vector3) -> Enemy:
	var e: Enemy = load(EnemyDB.get_def(id)["script"]).new()
	e.setup(id, difficulty, self, player)
	_apply_world(e)
	e.position = pos
	e.died.connect(_on_enemy_died)
	alive.append(e)
	entities.add_child(e)
	enemy_spawned.emit(e)
	return e


## World flavor: tinted enemies; the boss takes the world guardian's name, color and toughness.
func _apply_world(e: Enemy) -> void:
	var tint: Dictionary = world.get("tint", {})
	if tint.has(e.enemy_id):
		e.color = tint[e.enemy_id]
	if e.enemy_id == "boss":
		var b: Dictionary = world["boss"]
		e.color = b["color"]
		e.display_name = b["name"]
		e.max_hp *= b["hp"]
		e.hp = e.max_hp
		e.set("world_index", WorldDB.WORLDS.find(world))


func _on_enemy_died(e: Enemy) -> void:
	alive.erase(e)
	if _cleared:
		return
	if is_boss_room:
		if e == boss:
			boss = null
			for other in alive.duplicate():
				other.die()
			_on_cleared()
	elif alive.is_empty():
		_next_wave()


func _on_cleared() -> void:
	if _cleared:
		return
	_cleared = true
	for tg in ground.get_children():
		tg.queue_free()
	for n in entities.get_children():
		if n is Projectile and n.team == Projectile.Team.ENEMY:
			n.queue_free()
	cleared.emit()


func is_cleared() -> bool:
	return _cleared


func open_door() -> void:
	if door_open:
		return
	door_open = true
	_gate_body.process_mode = Node.PROCESS_MODE_DISABLED
	var tw := create_tween().set_parallel()
	tw.tween_property(_gate, "position:y", -WALL_H - 0.2, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_portal.visible = true
	_portal_light.visible = true
	_portal.scale = Vector3(1, 0.01, 1)
	tw.tween_property(_portal, "scale", Vector3.ONE, 0.6).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func add_telegraph(tg: Telegraph) -> void:
	ground.add_child(tg)


func random_spawn_point(min_player_dist: float) -> Vector2:
	var margin := 1.8
	for attempt in 40:
		var p := Vector2(rng.randf_range(margin, bounds.size.x - margin), rng.randf_range(margin + 1.5, bounds.size.y - margin))
		if is_blocked(p, 0.9):
			continue
		if player and p.distance_to(Flat.xz(player.global_position)) < min_player_dist:
			continue
		return p
	return Vector2(bounds.size.x * 0.5, bounds.size.y * 0.25)


func clamp_point(p: Vector2, margin: float) -> Vector2:
	return Vector2(clampf(p.x, margin, bounds.size.x - margin), clampf(p.y, margin, bounds.size.y - margin))


func is_blocked(p: Vector2, pad: float = 0.0) -> bool:
	if not bounds.grow(-pad).has_point(p):
		return true
	for o in obstacles:
		if o.grow(pad).has_point(p):
			return true
	return false


func segment_blocked(a: Vector2, b: Vector2, pad: float = 0.0) -> bool:
	var steps := int(a.distance_to(b) / 0.4) + 1
	for o in obstacles:
		var r: Rect2 = o.grow(pad)
		if r.has_point(a):
			r = o   # already brushing this obstacle: only its real shape blocks
		for i in steps + 1:
			if r.has_point(a.lerp(b, float(i) / steps)):
				return true
	return false


func _physics_process(delta: float) -> void:
	_t += delta
	for i in _lights.size():
		var l: OmniLight3D = _lights[i]
		l.light_energy = 1.5 + sin(_t * 9.0 + i * 1.7) * 0.12 + sin(_t * 23.0 + i) * 0.08
	if _portal and _portal.visible:
		_portal_light.light_energy = 2.5 + sin(_t * 4.0) * 0.4
	if door_open and not _exited and player and not player.dead:
		if door_rect.grow(0.3).has_point(Flat.xz(player.global_position)):
			_exited = true
			exit_reached.emit()


# --- Navigation ----------------------------------------------------------------

func _build_nav() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, ceili(bounds.size.x / NAV_CELL), ceili(bounds.size.y / NAV_CELL))
	astar.cell_size = Vector2(NAV_CELL, NAV_CELL)
	astar.offset = Vector2(NAV_CELL, NAV_CELL) * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in astar.region.size.x:
		for y in astar.region.size.y:
			if is_blocked(Vector2((x + 0.5) * NAV_CELL, (y + 0.5) * NAV_CELL), 0.65):
				astar.set_point_solid(Vector2i(x, y))


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / NAV_CELL), 0, astar.region.size.x - 1), clampi(int(p.y / NAV_CELL), 0, astar.region.size.y - 1))


## Nearest walkable cell (actors hugging a wall can stand in a padded "solid" cell).
func _open_cell(c: Vector2i) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for r in range(1, 5):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if astar.is_in_boundsv(n) and not astar.is_point_solid(n):
					return n
	return c


## Next point to walk toward to reach `to` around obstacles.
func next_waypoint(from: Vector2, to: Vector2, pad: float) -> Vector2:
	if not segment_blocked(from, to, pad):
		return to
	var path := astar.get_point_path(_open_cell(_cell(from)), _open_cell(_cell(to)), true)
	if path.size() < 2:
		return to
	# String-pull: head for the furthest path point we can walk to in a straight
	# line. Picking just the next cell flip-flops near corners as the start cell changes.
	var best := path[0]
	for i in range(1, mini(path.size(), 12)):
		if not segment_blocked(from, path[i], pad):
			best = path[i]
	if best.distance_to(from) < 0.3 and path.size() > 1:
		best = path[1]
	return best


# --- Building --------------------------------------------------------------------

func _build_visuals() -> void:
	var w := bounds.size.x
	var d := bounds.size.y
	# Floor (extends under the walls)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(w + 4.0, d + 4.0)
	floor_mi.mesh = plane
	floor_mi.position = Vector3(w * 0.5, 0, d * 0.5)
	var fm := ShaderMaterial.new()
	fm.shader = FLOOR_SHADER
	fm.set_shader_parameter("room_size", Vector2(w, d))
	var base: Color = world["floor"]
	fm.set_shader_parameter("base_color", base.lightened(0.08) if is_boss_room else base)
	fm.set_shader_parameter("mortar_color", world["mortar"])
	floor_mi.material_override = fm
	add_child(floor_mi)
	# Outer darkness so the arena floats in the void
	var outer := MeshInstance3D.new()
	var op := PlaneMesh.new()
	op.size = Vector2(w + 80.0, d + 80.0)
	outer.mesh = op
	outer.position = Vector3(w * 0.5, -0.05, d * 0.5)
	outer.material_override = Mats.solid(Color(world["bg"]).lightened(0.02), 1.0)
	add_child(outer)
	_build_decor()
	WorldKit.weather(self, world["weather"], bounds)

	var stone := Mats.solid(world["trim"], 0.9)
	var cap := Mats.solid(Color(world["trim"]).lightened(0.12), 0.8)
	var flame: Color = world["light"]
	for o in obstacles:
		var r: Rect2 = o
		_build_obstacle(r)
		if r.size.x <= 2.0 and r.size.y <= 2.0 and _lights.size() < 6:
			_lights.append(Models.brazier(self, Vector3(r.get_center().x, 2.45, r.get_center().y), flame))
	for c in [Vector2(1.2, 1.2), Vector2(w - 1.2, 1.2), Vector2(1.2, d - 1.2), Vector2(w - 1.2, d - 1.2)]:
		Models.part(self, Models.box(Vector3(1.0, 1.4, 1.0)), stone, Vector3(c.x, 0.7, c.y))
		_lights.append(Models.brazier(self, Vector3(c.x, 1.4, c.y), flame))

	# Gate in the north wall
	var cx := w * 0.5
	_gate = Node3D.new()
	_gate.position = Vector3(cx, 0, 0)
	add_child(_gate)
	var bar := Mats.solid(Color("44403c"), 0.4, 0.7)
	for i in 7:
		Models.part(_gate, Models.box(Vector3(0.14, WALL_H + 0.6, 0.14)), bar, Vector3(-DOOR_W * 0.5 + 0.3 + i * (DOOR_W - 0.6) / 6.0, (WALL_H + 0.6) * 0.5, 0))
	Models.part(_gate, Models.box(Vector3(DOOR_W, 0.15, 0.2)), bar, Vector3(0, 0.9, 0))
	_portal = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(DOOR_W - 0.3, 2.4)
	_portal.mesh = q
	_portal.material_override = Mats.fx(Color(1.0, 0.55, 0.2, 0.55), true)
	_portal.position = Vector3(cx, 1.2, -0.3)
	_portal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal.visible = false
	add_child(_portal)
	_portal_light = OmniLight3D.new()
	_portal_light.light_color = Color("ff9a4d")
	_portal_light.omni_range = 7.0
	_portal_light.position = Vector3(cx, 1.5, 0.8)
	_portal_light.visible = false
	add_child(_portal_light)
	# Arch pillars beside the gate
	for sx in [-1, 1]:
		Models.part(self, Models.box(Vector3(0.8, 3.0, 1.2)), cap, Vector3(cx + sx * (DOOR_W * 0.5 + 0.4), 1.5, -0.1))
	Models.part(self, Models.box(Vector3(DOOR_W + 1.6, 0.6, 1.2)), cap, Vector3(cx, 3.0, -0.1))


func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var w := bounds.size.x
	var d := bounds.size.y
	var t := 1.0
	var cx := w * 0.5
	var left_w := cx - DOOR_W * 0.5
	var rects := [
		Rect2(-t, -t, left_w + t, t),                         # north-left
		Rect2(cx + DOOR_W * 0.5, -t, left_w + t, t),          # north-right
		Rect2(-t, d, w + 2 * t, t),                           # south
		Rect2(-t, 0, t, d),                                   # west
		Rect2(w, 0, t, d),                                    # east
	]
	var wall_mat := Mats.solid(world["wall"], 0.95)
	var trim := Mats.solid(world["trim"], 0.8)
	for r in rects:
		_add_box(body, r, WALL_H)
		Models.part(self, Models.box(Vector3(r.size.x, WALL_H, r.size.y)), wall_mat, Vector3(r.get_center().x, WALL_H * 0.5, r.get_center().y))
		Models.part(self, Models.box(Vector3(r.size.x + 0.1, 0.15, r.size.y + 0.1)), trim, Vector3(r.get_center().x, WALL_H, r.get_center().y))
	for o in obstacles:
		_add_box(body, o, 2.2)
	# Gate collision (disabled when the door opens)
	_gate_body = StaticBody3D.new()
	_gate_body.collision_layer = 1
	add_child(_gate_body)
	_add_box(_gate_body, Rect2(cx - DOOR_W * 0.5, -t, DOOR_W, t + 0.2), WALL_H)


## Obstacles are styled per world: charred stumps, ice crystals, mossy ruins, obsidian.
func _build_obstacle(r: Rect2) -> void:
	var h := 2.2
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var body_col: Color = world["obstacle_color"]
	var accent: Color = world["accent"]
	match world["obstacle"]:
		"crystal":
			Models.part(self, Models.box(Vector3(r.size.x, h * 0.55, r.size.y)), Mats.solid(body_col, 0.3, 0.2), c + Vector3(0, h * 0.275, 0))
			var n := int(clampf(r.size.x * r.size.y / 1.5, 2, 9))
			for i in n:
				var off := Vector3(rng.randf_range(-0.4, 0.4) * r.size.x, 0, rng.randf_range(-0.4, 0.4) * r.size.y)
				var ch := rng.randf_range(1.4, 2.6)
				Models.part(self, Models.cyl(0.0, rng.randf_range(0.25, 0.45), ch, 5), Mats.glow(accent.darkened(0.2), 0.6), c + off + Vector3(0, h * 0.55 + ch * 0.4, 0), Vector3(rng.randf_range(-15, 15), rng.randf() * 90, rng.randf_range(-15, 15)))
		"ruin":
			Models.part(self, Models.box(Vector3(r.size.x, h * 0.8, r.size.y)), Mats.solid(body_col, 0.95), c + Vector3(0, h * 0.4, 0))
			Models.part(self, Models.box(Vector3(r.size.x + 0.15, 0.22, r.size.y + 0.15)), Mats.solid(accent.darkened(0.72), 0.95), c + Vector3(0, h * 0.8 + 0.1, 0))
			for i in 2:
				var off := Vector3(rng.randf_range(-0.3, 0.3) * r.size.x, 0, rng.randf_range(-0.3, 0.3) * r.size.y)
				Models.part(self, Models.cyl(0.22, 0.26, rng.randf_range(0.6, 1.4), 8), Mats.solid(body_col.lightened(0.1), 0.9), c + off + Vector3(0, h * 0.8 + 0.4, 0))
		"obsidian":
			Models.part(self, Models.box(Vector3(r.size.x, h, r.size.y)), Mats.solid(body_col, 0.15, 0.4), c + Vector3(0, h * 0.5, 0))
			Models.part(self, Models.box(Vector3(r.size.x + 0.04, 0.05, r.size.y + 0.04)), Mats.glow(accent, 2.0), c + Vector3(0, h * 0.35, 0))
			Models.part(self, Models.box(Vector3(r.size.x + 0.04, 0.05, r.size.y + 0.04)), Mats.glow(accent, 2.0), c + Vector3(0, h * 0.75, 0))
		_:  # stump: charred wood with glowing cracks
			Models.part(self, Models.box(Vector3(r.size.x, h * 0.7, r.size.y)), Mats.solid(body_col, 0.95), c + Vector3(0, h * 0.35, 0))
			Models.part(self, Models.box(Vector3(r.size.x + 0.04, 0.03, r.size.y + 0.04)), Mats.glow(accent.darkened(0.3), 0.7), c + Vector3(0, h * 0.45, 0))
			Models.part(self, Models.box(Vector3(r.size.x * 0.9, 0.2, r.size.y * 0.9)), Mats.solid(body_col.lightened(0.1), 0.9), c + Vector3(0, h * 0.7 + 0.12, 0))


## Scenery outside the walls so each world reads as a place, not just a floor.
func _build_decor() -> void:
	var w := bounds.size.x
	var d := bounds.size.y
	var col: Color = world["obstacle_color"]
	var accent: Color = world["accent"]
	for i in 26:
		var side := i % 4
		var p: Vector2
		match side:
			0: p = Vector2(rng.randf_range(-6, w + 6), rng.randf_range(-7, -2.5))
			1: p = Vector2(rng.randf_range(-6, w + 6), rng.randf_range(d + 2.5, d + 5))
			2: p = Vector2(rng.randf_range(-7, -2.5), rng.randf_range(0, d))
			_: p = Vector2(rng.randf_range(w + 2.5, w + 7), rng.randf_range(0, d))
		if side == 0 and absf(p.x - w * 0.5) < 4.0:
			continue  # keep the gate clear
		var root := Node3D.new()
		root.position = Flat.v3(p)
		root.rotation.y = rng.randf() * TAU
		root.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
		add_child(root)
		match world["obstacle"]:
			"crystal":
				Models.part(root, Models.cyl(0.0, 0.5, rng.randf_range(2.0, 4.0), 5), Mats.glow(accent.darkened(0.35), 0.5), Vector3(0, 1.2, 0), Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12)))
			"ruin":
				Models.part(root, Models.cyl(0.08, 0.15, 2.4, 5), Mats.solid(Color("3b3222")), Vector3(0, 1.2, 0), Vector3(0, 0, rng.randf_range(-15, 15)))
				Models.part(root, Models.sphere(0.9, 7, 4), Mats.solid(accent.darkened(0.55), 0.9), Vector3(0, 2.6, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
			"obsidian":
				Models.part(root, Models.cyl(0.0, 0.6, rng.randf_range(2.5, 5.0), 4), Mats.solid(col, 0.15, 0.4), Vector3(0, 1.5, 0))
			_:
				Models.part(root, Models.cyl(0.1, 0.2, 2.6, 6), Mats.solid(Color("1c1714")), Vector3(0, 1.3, 0))
				Models.part(root, Models.cyl(0.0, 0.7, 1.4, 6), Mats.solid(Color("241e1a")), Vector3(0, 2.4, 0))


func _add_box(body: StaticBody3D, r: Rect2, h: float) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(r.size.x, h, r.size.y)
	cs.shape = shape
	cs.position = Vector3(r.get_center().x, h * 0.5, r.get_center().y)
	body.add_child(cs)
