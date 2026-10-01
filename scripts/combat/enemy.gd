class_name Enemy
extends CharacterBody2D
## Base enemy: health, status effects, spawn-in warning and telegraph ownership.
## Subclasses implement `_think(delta)` as a small state machine that sets velocity.

signal died(enemy: Enemy)

var enemy_id := ""
var def: Dictionary
var room: Room
var player: Player
var difficulty := 0.0
var max_hp := 50.0
var hp := 50.0
var damage := 10.0
var speed := 120.0
var radius := 20.0
var color := Color.RED
var dead := false
var is_boss := false

var state := "chase"
var state_time := 0.0
var spawn_left := 0.8
var telegraphs: Array = []

var poison_dps := 0.0
var poison_left := 0.0
var burn_dps := 0.0
var burn_left := 0.0
var slow_left := 0.0
var _status_tick := 0.0
var _waypoint := Vector2.ZERO
var _repath := 0.0
var _flash := 0.0


func setup(id: String, diff: float, p_room: Room, p_player: Player) -> void:
	enemy_id = id
	def = EnemyDB.get_def(id)
	difficulty = diff
	room = p_room
	player = p_player
	max_hp = def["hp"] * EnemyDB.hp_scale(diff)
	hp = max_hp
	damage = def["damage"] * EnemyDB.damage_scale(diff)
	speed = def["speed"] * (1.0 + 0.03 * diff)
	radius = def["radius"]
	color = def["color"]


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	_on_ready()


func _on_ready() -> void:
	pass


func is_targetable() -> bool:
	return not dead and spawn_left <= 0.0


func player_alive() -> bool:
	return player != null and is_instance_valid(player) and not player.dead


func to_player() -> Vector2:
	return player.global_position - global_position if player_alive() else Vector2.ZERO


func slow_mult() -> float:
	return 0.5 if slow_left > 0.0 else 1.0


func set_state(s: String) -> void:
	state = s
	state_time = 0.0


func has_los() -> bool:
	return player_alive() and not room.segment_blocked(global_position, player.global_position)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if spawn_left > 0.0:
		spawn_left -= delta
		return
	_tick_status(delta)
	if dead:
		return
	state_time += delta
	velocity = Vector2.ZERO
	_think(delta)
	move_and_slide()


func _think(_delta: float) -> void:
	pass


## Moves toward a direction with simple obstacle sliding.
func steer(dir: Vector2, mult: float = 1.0) -> void:
	velocity = dir.normalized() * speed * mult * slow_mult()


## Walks toward a world point, pathing around obstacles when needed.
func steer_to(target: Vector2, mult: float = 1.0) -> void:
	_repath -= get_physics_process_delta_time()
	if _repath <= 0.0 or global_position.distance_to(_waypoint) < 12.0:
		_repath = 0.25
		_waypoint = room.next_waypoint(global_position, target, radius * 0.8)
	steer(_waypoint - global_position, mult)


func _tick_status(delta: float) -> void:
	slow_left = maxf(0.0, slow_left - delta)
	poison_left = maxf(0.0, poison_left - delta)
	burn_left = maxf(0.0, burn_left - delta)
	if poison_left <= 0.0:
		poison_dps = 0.0
	_status_tick += delta
	if _status_tick >= 0.5:
		_status_tick -= 0.5
		var dot := 0.0
		if poison_left > 0.0:
			dot += poison_dps * 0.5
		if burn_left > 0.0:
			dot += burn_dps * 0.5
		if dot > 0.0:
			take_damage(dot, false, Color("a6e05a") if poison_left > 0.0 else Color("ff9f43"))


func add_poison(dps: float, duration: float) -> void:
	# Poison stacks intensity (capped) and refreshes duration.
	poison_dps = minf(poison_dps + dps, dps * 5.0)
	poison_left = duration


func ignite(dps: float, duration: float) -> void:
	burn_dps = maxf(burn_dps, dps)
	burn_left = duration


func apply_slow(_amount: float, duration: float) -> void:
	slow_left = maxf(slow_left, duration)


func take_damage(amount: float, crit: bool = false, text_color: Color = Color.WHITE) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.08
	var c := Color("ffd23f") if crit else text_color
	Fx.float_text(get_parent(), global_position + Vector2(0, -radius), str(roundi(amount)) + ("!" if crit else ""), c, 30 if crit else 20)
	if hp <= 0.0:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	clear_telegraphs()
	remove_from_group("enemies")
	Fx.spawn(get_parent(), Fx.Kind.BURST, global_position, color, radius * 1.8, 0.35)
	Events.enemy_killed.emit(enemy_id, global_position)
	died.emit(self)
	queue_free()


func add_telegraph(tg: Telegraph) -> Telegraph:
	room.add_telegraph(tg)
	telegraphs.append(tg)
	tg.tree_exited.connect(func(): telegraphs.erase(tg))
	return tg


func clear_telegraphs() -> void:
	for tg in telegraphs.duplicate():
		if is_instance_valid(tg):
			tg.queue_free()
	telegraphs.clear()


## Damages the player if they stand in the telegraph when it resolves.
func resolve_hit(tg: Telegraph, dmg: float) -> void:
	if dead or not player_alive():
		return
	if tg.contains(player.global_position, player.radius * 0.6):
		player.take_damage(dmg, self)


## Runs `cb` after `sec` seconds. The timer is a child, so it dies with the enemy.
func after(sec: float, cb: Callable) -> void:
	if sec <= 0.0:
		cb.call()
		return
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = sec
	t.timeout.connect(cb)
	t.timeout.connect(t.queue_free)
	add_child(t)
	t.start()


func fire_projectile(dir: Vector2, proj_speed: float, dmg: float, size: float = 9.0) -> void:
	var p := Projectile.new()
	p.team = Projectile.Team.ENEMY
	p.global_position = global_position + dir * (radius + 6.0)
	p.velocity = dir.normalized() * proj_speed
	p.damage = dmg
	p.radius = size
	p.max_distance = 1400.0
	p.color = color.lightened(0.3)
	p.room = room
	get_parent().add_child(p)


func _draw() -> void:
	if spawn_left > 0.0:
		var t := 1.0 - spawn_left / 0.8
		draw_arc(Vector2.ZERO, radius * 1.6, 0, TAU, 32, Color(color, 0.8), 3.0)
		draw_circle(Vector2.ZERO, radius * t, Color(color, 0.5))
		return
	var body := Color.WHITE if _flash > 0.0 else color
	if slow_left > 0.0:
		body = body.lerp(Color("8fd3ff"), 0.4)
	draw_circle(Vector2(0, radius * 0.3), radius, Color(0, 0, 0, 0.3))
	_draw_body(body)
	if poison_left > 0.0:
		draw_arc(Vector2.ZERO, radius + 4.0, 0, TAU, 20, Color("a6e05a"), 2.0)
	if burn_left > 0.0:
		draw_arc(Vector2.ZERO, radius + 7.0, 0, TAU, 20, Color("ff9f43"), 2.0)
	if not is_boss and hp < max_hp:
		var w := radius * 2.0
		draw_rect(Rect2(-w * 0.5, -radius - 12.0, w, 5.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w * 0.5, -radius - 12.0, w * hp / max_hp, 5.0), Color("ff5a5a"))


func _draw_body(body: Color) -> void:
	draw_circle(Vector2.ZERO, radius, body)
