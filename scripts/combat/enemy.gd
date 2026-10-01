class_name Enemy
extends CharacterBody3D
## Base enemy: health, status effects, spawn-in, telegraph ownership and animation.
## Subclasses build a model and implement `_think(delta)` as a small state machine.

signal died(enemy: Enemy)

const SPAWN_TIME := 0.8
const TELL_STATES := ["windup", "aim", "busy"]

var enemy_id := ""
var def: Dictionary
var room: Room
var player: Player
var difficulty := 0.0
var max_hp := 50.0
var hp := 50.0
var damage := 10.0
var speed := 3.0
var radius := 0.5
var bar_height := 1.7
var color := Color.RED
var dead := false
var is_boss := false
var display_name := ""

var state := "chase"
var state_time := 0.0
var spawn_left := SPAWN_TIME
var telegraphs: Array = []
var facing := Vector3.BACK
var model: Node3D
var _meshes: Array = []

var poison_dps := 0.0
var poison_left := 0.0
var burn_dps := 0.0
var burn_left := 0.0
var slow_left := 0.0
var _status_tick := 0.0
var _flash := 0.0
var _waypoint := Vector2.ZERO
var _repath := 0.0
var _t := 0.0
var _knock := Vector3.ZERO


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
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1 | 4
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.6
	shape.shape = cyl
	shape.position.y = 0.8
	add_child(shape)
	model = _build_model()
	add_child(model)
	_meshes = model.find_children("*", "MeshInstance3D", true, false)
	model.scale = Vector3.ONE * 0.01
	Fx.ring(get_parent(), global_position, color, radius * 2.5, SPAWN_TIME)
	if player_alive():
		facing = to_player().normalized()
	_on_ready()


func _build_model() -> Node3D:
	return Models.grunt(color)


func _on_ready() -> void:
	pass


func is_targetable() -> bool:
	return not dead and spawn_left <= 0.0


func player_alive() -> bool:
	return player != null and is_instance_valid(player) and not player.dead


func to_player() -> Vector3:
	if not player_alive():
		return Vector3.ZERO
	var v := player.global_position - global_position
	v.y = 0.0
	return v


func slow_mult() -> float:
	return 0.5 if slow_left > 0.0 else 1.0


func set_state(s: String) -> void:
	state = s
	state_time = 0.0


func has_los() -> bool:
	return player_alive() and not room.segment_blocked(Flat.xz(global_position), Flat.xz(player.global_position))


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	if spawn_left > 0.0:
		spawn_left -= delta
		var k := 1.0 - maxf(spawn_left, 0.0) / SPAWN_TIME
		model.scale = Vector3.ONE * maxf(0.01, ease(k, 0.4))
		return
	_tick_status(delta)
	if dead:
		return
	state_time += delta
	velocity = Vector3.ZERO
	_think(delta)
	if _knock.length() > 0.05:
		velocity += _knock
		_knock = _knock.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	move_and_slide()
	position.y = 0.0
	_animate(delta)


func _think(_delta: float) -> void:
	pass


func _animate(delta: float) -> void:
	var v := Vector3(velocity.x, 0, velocity.z)
	if v.length() > 0.2 and state == "chase":
		facing = v.normalized()
	model.rotation.y = lerp_angle(model.rotation.y, Flat.yaw(facing), 1.0 - exp(-10.0 * delta))
	var telling := state in TELL_STATES
	var target_scale := Vector3.ONE
	if telling:
		# Wind-up "tell": crouch and tremble so the attack reads even off-telegraph.
		target_scale = Vector3(1.12, 0.88, 1.12)
		model.position.x = randf_range(-0.03, 0.03)
	else:
		model.position.x = 0.0
	model.scale = model.scale.lerp(target_scale, 1.0 - exp(-12.0 * delta))
	model.position.y = absf(sin(_t * 9.0)) * 0.06 if v.length() > 0.2 else 0.0
	var ov: Material = null
	if _flash > 0.0:
		ov = Mats.overlay(Color(1, 1, 1, 0.75))
	elif slow_left > 0.0:
		ov = Mats.overlay(Color(0.5, 0.85, 1.0, 0.35))
	elif poison_left > 0.0:
		ov = Mats.overlay(Color(0.55, 0.95, 0.3, 0.3))
	elif burn_left > 0.0:
		ov = Mats.overlay(Color(1.0, 0.55, 0.15, 0.3))
	elif telling:
		ov = Mats.overlay(Color(1.0, 0.3, 0.2, 0.18 + 0.12 * sin(_t * 30.0)))
	for m in _meshes:
		m.material_overlay = ov


func steer(dir: Vector3, mult: float = 1.0) -> void:
	dir.y = 0.0
	velocity = dir.normalized() * speed * mult * slow_mult()


## Walks toward a world point, pathing around obstacles when needed.
func steer_to(target: Vector3, mult: float = 1.0) -> void:
	_repath -= get_physics_process_delta_time()
	var here := Flat.xz(global_position)
	if _repath <= 0.0 or here.distance_to(_waypoint) < 0.3:
		_repath = 0.25
		_waypoint = room.next_waypoint(here, Flat.xz(target), radius * 0.8)
	steer(Flat.v3(_waypoint - here), mult)


func face_player() -> void:
	if player_alive():
		facing = to_player().normalized()


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
			take_damage(dot, false, Color("a3e635") if poison_left > 0.0 else Color("fb923c"))


## Shoves the enemy (bosses barely budge).
func knockback(impulse: Vector3) -> void:
	impulse.y = 0.0
	_knock += impulse * (0.15 if is_boss else 1.0)


func add_poison(dps: float, duration: float) -> void:
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
	var c := Color("fde047") if crit else text_color
	if Settings.damage_numbers:
		Fx.text(get_parent(), global_position + Vector3(0, bar_height - 1.6, 0), str(roundi(amount)) + ("!" if crit else ""), c, 64 if crit else 44)
	if hp <= 0.0:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	clear_telegraphs()
	remove_from_group("enemies")
	Fx.burst(get_parent(), global_position, color, 1.0 + radius, 18 if not is_boss else 60)
	Fx.ring(get_parent(), global_position, color, radius * 3.0, 0.4)
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


func fire_projectile(dir: Vector3, proj_speed: float, dmg: float, size: float = 0.25) -> void:
	dir.y = 0.0
	var p := Projectile.new()
	p.team = Projectile.Team.ENEMY
	p.position = global_position + dir.normalized() * (radius + 0.2)
	p.velocity = dir.normalized() * proj_speed
	p.damage = dmg
	p.radius = size
	p.max_distance = 35.0
	p.color = color.lightened(0.1)
	p.room = room
	get_parent().add_child(p)
