class_name Room
extends Node2D
## One arena: floor, walls, obstacles, enemy waves and an exit door.
## Layout is generated from templates + RNG; later this can be swapped for
## a full procedural map generator without changing the run flow.

signal cleared
signal exit_reached
signal enemy_spawned(enemy: Enemy)

const NAV_CELL := 40.0

const LAYOUTS := {
	"open": [],
	"pillars": [[0.28, 0.35, 70, 70], [0.72, 0.35, 70, 70], [0.28, 0.68, 70, 70], [0.72, 0.68, 70, 70]],
	"bar": [[0.5, 0.45, 300, 60]],
	"gates": [[0.2, 0.5, 60, 260], [0.8, 0.5, 60, 260]],
	"cross": [[0.5, 0.42, 60, 180], [0.3, 0.6, 140, 50], [0.7, 0.6, 140, 50]],
}

var bounds := Rect2(0, 0, 1400, 1000)
var obstacles: Array = []        # Array[Rect2]
var door_rect := Rect2()
var door_open := false
var layout_name := "open"
var is_boss_room := false
var difficulty := 0.0
var waves: Array = []            # Array of Array[String]
var wave_index := -1
var player: Player
var rng: RandomNumberGenerator
var ground: Node2D               # telegraphs, below entities
var entities: Node2D             # player, enemies, projectiles
var alive: Array = []
var boss: Enemy
var astar: AStarGrid2D
var _exited := false
var _cleared := false


func build(p_rng: RandomNumberGenerator, p_difficulty: float, boss_room: bool, room_index: int) -> void:
	rng = p_rng
	difficulty = p_difficulty
	is_boss_room = boss_room
	if boss_room:
		bounds = Rect2(0, 0, 1500, 1150)
		layout_name = "open"
	else:
		bounds = Rect2(0, 0, rng.randi_range(1250, 1500), rng.randi_range(950, 1150))
		var names := LAYOUTS.keys()
		layout_name = "open" if room_index == 0 else names[rng.randi() % names.size()]
	for o in LAYOUTS[layout_name]:
		var c := Vector2(bounds.size.x * o[0], bounds.size.y * o[1])
		obstacles.append(Rect2(c - Vector2(o[2], o[3]) * 0.5, Vector2(o[2], o[3])))
	door_rect = Rect2(bounds.size.x * 0.5 - 80.0, 0.0, 160.0, 60.0)
	waves = [] if boss_room else _plan_waves(room_index)

	ground = Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	_build_walls()
	_build_nav()


func player_spawn() -> Vector2:
	return Vector2(bounds.size.x * 0.5, bounds.size.y - 110.0)


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
		boss = spawn_enemy("boss", Vector2(bounds.size.x * 0.5, bounds.size.y * 0.3))
		boss.connect("summon_requested", _on_boss_summon)
	else:
		_next_wave()


func _next_wave() -> void:
	wave_index += 1
	if wave_index >= waves.size():
		_on_cleared()
		return
	for id in waves[wave_index]:
		spawn_enemy(id, random_spawn_point(340.0))


func _on_boss_summon(ids: Array, near: Vector2) -> void:
	for id in ids:
		var p := near + Vector2.from_angle(rng.randf() * TAU) * 140.0
		spawn_enemy(id, clamp_point(p, 40.0))


func spawn_enemy(id: String, pos: Vector2) -> Enemy:
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
	door_open = true
	queue_redraw()


func add_telegraph(tg: Telegraph) -> void:
	ground.add_child(tg)


func random_spawn_point(min_player_dist: float) -> Vector2:
	var margin := 70.0
	for attempt in 40:
		var p := Vector2(rng.randf_range(margin, bounds.size.x - margin), rng.randf_range(margin + 60.0, bounds.size.y - margin))
		if is_blocked(p, 35.0):
			continue
		if player and p.distance_to(player.global_position) < min_player_dist:
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
	var steps := int(a.distance_to(b) / 16.0) + 1
	for o in obstacles:
		var r: Rect2 = o.grow(pad)
		for i in steps + 1:
			if r.has_point(a.lerp(b, float(i) / steps)):
				return true
	return false


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
			var c := Vector2((x + 0.5) * NAV_CELL, (y + 0.5) * NAV_CELL)
			if is_blocked(c, 26.0):
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
	# Skip ahead to the furthest directly reachable waypoint for smoother movement.
	var best := path[1]
	for i in range(2, mini(path.size(), 6)):
		if segment_blocked(from, path[i], pad):
			break
		best = path[i]
	return best


func _physics_process(_delta: float) -> void:
	if door_open and not _exited and player and not player.dead:
		if door_rect.grow(10.0).has_point(player.global_position):
			_exited = true
			exit_reached.emit()


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var t := 200.0
	var b := bounds
	var rects := [
		Rect2(b.position.x - t, b.position.y - t, b.size.x + 2 * t, t),
		Rect2(b.position.x - t, b.end.y, b.size.x + 2 * t, t),
		Rect2(b.position.x - t, b.position.y, t, b.size.y),
		Rect2(b.end.x, b.position.y, t, b.size.y),
	]
	rects.append_array(obstacles)
	for r in rects:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.get_center()
		body.add_child(cs)


func _draw() -> void:
	draw_rect(bounds.grow(40.0), Color("2a2430"))
	draw_rect(bounds, Color("3b3440") if not is_boss_room else Color("43302c"))
	var tile := 100.0
	var grid := Color(1, 1, 1, 0.035)
	var x := tile
	while x < bounds.size.x:
		draw_line(Vector2(x, 0), Vector2(x, bounds.size.y), grid, 2.0)
		x += tile
	var y := tile
	while y < bounds.size.y:
		draw_line(Vector2(0, y), Vector2(bounds.size.x, y), grid, 2.0)
		y += tile
	draw_rect(bounds, Color("17131b"), false, 8.0)
	for o in obstacles:
		draw_rect(Rect2(o.position + Vector2(0, 10), o.size), Color(0, 0, 0, 0.35))
		draw_rect(o, Color("5a4f63"))
		draw_rect(o, Color("1d1922"), false, 4.0)
	var door_col := Color("ffb347") if door_open else Color("6b2f2f")
	draw_rect(door_rect, door_col)
	if door_open:
		draw_rect(door_rect.grow(8.0), Color(1, 0.7, 0.3, 0.35), false, 6.0)
		draw_string(ThemeDB.fallback_font, door_rect.position + Vector2(18, 40), "NEXT ▲", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("2a1a10"))
