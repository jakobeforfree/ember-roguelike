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


func build(p_rng: RandomNumberGenerator, p_difficulty: float, boss_room: bool, room_index: int) -> void:
	rng = p_rng
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
	e.position = pos
	e.died.connect(_on_enemy_died)
	alive.append(e)
	entities.add_child(e)
	enemy_spawned.emit(e)
	return e


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
	var best := path[1]
	for i in range(2, mini(path.size(), 6)):
		if segment_blocked(from, path[i], pad):
			break
		best = path[i]
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
	if is_boss_room:
		fm.set_shader_parameter("base_color", Color(0.27, 0.19, 0.17))
	floor_mi.material_override = fm
	add_child(floor_mi)
	# Outer darkness so the arena floats in the void
	var outer := MeshInstance3D.new()
	var op := PlaneMesh.new()
	op.size = Vector2(w + 80.0, d + 80.0)
	outer.mesh = op
	outer.position = Vector3(w * 0.5, -0.05, d * 0.5)
	outer.material_override = Mats.solid(Color("07080c"), 1.0)
	add_child(outer)

	var stone := Mats.solid(Color("2b2733"), 0.9)
	var cap := Mats.solid(Color("3d3846"), 0.8)
	for o in obstacles:
		var r: Rect2 = o
		var h := 2.2
		Models.part(self, Models.box(Vector3(r.size.x, h, r.size.y)), stone, Vector3(r.get_center().x, h * 0.5, r.get_center().y))
		Models.part(self, Models.box(Vector3(r.size.x + 0.2, 0.25, r.size.y + 0.2)), cap, Vector3(r.get_center().x, h + 0.12, r.get_center().y))
		if r.size.x <= 2.0 and r.size.y <= 2.0 and _lights.size() < 6:
			_lights.append(Models.brazier(self, Vector3(r.get_center().x, h + 0.25, r.get_center().y)))
	for c in [Vector2(1.2, 1.2), Vector2(w - 1.2, 1.2), Vector2(1.2, d - 1.2), Vector2(w - 1.2, d - 1.2)]:
		Models.part(self, Models.box(Vector3(1.0, 1.4, 1.0)), stone, Vector3(c.x, 0.7, c.y))
		_lights.append(Models.brazier(self, Vector3(c.x, 1.4, c.y)))

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
	var wall_mat := Mats.solid(Color("221f29"), 0.95)
	var trim := Mats.solid(Color("3d3846"), 0.8)
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


func _add_box(body: StaticBody3D, r: Rect2, h: float) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(r.size.x, h, r.size.y)
	cs.shape = shape
	cs.position = Vector3(r.get_center().x, h * 0.5, r.get_center().y)
	body.add_child(cs)
