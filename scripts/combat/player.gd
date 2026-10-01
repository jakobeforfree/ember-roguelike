class_name Player
extends CharacterBody3D
## The player: manual movement, automatic attacks, and a dodge with i-frames.
## A "perfect dodge" (an attack would have hit you during i-frames) briefly slows
## time and empowers your next shots, rewarding good timing.

signal hp_changed(hp: float, max_hp: float)
signal died
signal dodged(perfect: bool)

const DASH_TIME := 0.16
const HURT_GRACE := 0.45
const PERFECT_CRITS := 3

var stats: Stats
var weapon: WeaponBehavior
var room: Room
var radius := 0.45
var hp := 100.0
var max_hp := 100.0
var move_input := Vector2.ZERO     # set by controls each frame (x = right, y = down screen)
var facing := Vector3.FORWARD
var aim_dir := Vector3.ZERO        # mouse direction on PC; idle dodges go this way
var dodge_cd_left := 0.0
var invuln_left := 0.0             # post-hit grace period
var iframe_left := 0.0             # dodge invincibility
var dash_left := 0.0
var dash_dir := Vector3.ZERO
var dash_hit := {}
var perfect_this_dash := false
var forced_crits := 0
var attack_cd := 0.0
var dead := false
var model: Node3D
var _meshes: Array = []
var _flash := 0.0
var _t := 0.0


func setup(p_stats: Stats, weapon_id: String) -> void:
	stats = p_stats
	max_hp = stats.get_stat("max_hp")
	hp = max_hp
	var wdef := WeaponDB.get_def(weapon_id)
	weapon = load(wdef["behavior"]).new()
	weapon.setup(self, wdef)
	hp_changed.emit(hp, max_hp)


## Re-applies stats after an upgrade, keeping the current HP ratio.
func refresh_stats(new_stats: Stats) -> void:
	var ratio := hp / max_hp
	stats = new_stats
	max_hp = stats.get_stat("max_hp")
	hp = clampf(max_hp * ratio, 1.0, max_hp)
	hp_changed.emit(hp, max_hp)


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius * 0.9
	cyl.height = 1.6
	shape.shape = cyl
	shape.position.y = 0.8
	add_child(shape)
	model = Models.player()
	model.scale = Vector3.ONE * 1.15
	add_child(model)
	_meshes = model.find_children("*", "MeshInstance3D", true, false)


func input_dir() -> Vector3:
	return Vector3(move_input.x, 0, move_input.y)


func is_dashing() -> bool:
	return dash_left > 0.0


func dodge_ready() -> bool:
	return dodge_cd_left <= 0.0 and not dead


func dodge_cooldown_ratio() -> float:
	var total := stats.get_stat("dodge_cooldown") if stats else 1.0
	return clampf(dodge_cd_left / total, 0.0, 1.0)


func try_dodge() -> bool:
	if not dodge_ready():
		return false
	if move_input.length() > 0.1:
		dash_dir = input_dir().normalized()
	elif aim_dir.length() > 0.1:
		dash_dir = aim_dir
	else:
		dash_dir = facing
	dash_left = DASH_TIME
	iframe_left = stats.get_stat("iframe_time")
	dodge_cd_left = stats.get_stat("dodge_cooldown")
	dash_hit.clear()
	perfect_this_dash = false
	facing = dash_dir
	dodged.emit(false)
	Fx.ring(get_parent(), global_position, Color("5eead4"), 1.2, 0.3)
	return true


func _physics_process(delta: float) -> void:
	if dead or stats == null:
		return
	_t += delta
	dodge_cd_left = maxf(0.0, dodge_cd_left - delta)
	invuln_left = maxf(0.0, invuln_left - delta)
	iframe_left = maxf(0.0, iframe_left - delta)
	_flash = maxf(0.0, _flash - delta)
	var regen := stats.get_stat("hp_regen")
	if regen > 0.0:
		heal(regen * delta, false)

	var moving := move_input.length() > 0.1
	if is_dashing():
		dash_left -= delta
		velocity = dash_dir * stats.get_stat("dodge_distance") / DASH_TIME
		_dash_damage()
	else:
		velocity = input_dir().limit_length(1.0) * stats.get_stat("move_speed")
		if moving:
			facing = input_dir().normalized()
	move_and_slide()
	position.y = 0.0

	attack_cd = maxf(0.0, attack_cd - delta)
	weapon.update(delta)
	if attack_cd <= 0.0 and not is_dashing():
		var target = find_target()
		if target:
			var to: Vector3 = target.global_position - global_position
			to.y = 0.0
			facing = to.normalized()
			weapon.attack(target)
			attack_cd = 1.0 / stats.get_stat("attack_speed")
	_animate(delta, moving)


func _animate(delta: float, moving: bool) -> void:
	model.rotation.y = lerp_angle(model.rotation.y, Flat.yaw(facing), 1.0 - exp(-18.0 * delta))
	var bob := absf(sin(_t * 11.0)) * 0.08 if moving else sin(_t * 2.5) * 0.02
	model.position.y = bob
	if is_dashing():
		model.scale = Vector3(1.0, 0.9, 1.45)
	else:
		model.scale = model.scale.lerp(Vector3.ONE * 1.15, 1.0 - exp(-14.0 * delta))
	var ov: Material = null
	if _flash > 0.0:
		ov = Mats.overlay(Color(1, 0.2, 0.2, 0.7))
	elif iframe_left > 0.0:
		ov = Mats.overlay(Color(0.4, 1.0, 0.95, 0.45))
	elif invuln_left > 0.0 and int(_t * 14.0) % 2 == 0:
		ov = Mats.overlay(Color(1, 1, 1, 0.35))
	for m in _meshes:
		m.material_overlay = ov


## Nearest visible enemy within attack range.
func find_target():
	var best = null
	var best_d := stats.get_stat("attack_range")
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_targetable():
			continue
		var d := Flat.dist(global_position, e.global_position)
		if d < best_d and (room == null or not room.segment_blocked(Flat.xz(global_position), Flat.xz(e.global_position))):
			best_d = d
			best = e
	return best


func _dash_damage() -> void:
	var dmg := stats.get_stat("dash_damage")
	if dmg <= 0.0:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not dash_hit.has(e) and e.is_targetable() and Flat.dist(global_position, e.global_position) < radius + e.radius + 0.3:
			dash_hit[e] = true
			Combat.player_hits_enemy(self, e, dmg, false, false)


func consume_forced_crit() -> bool:
	if forced_crits > 0:
		forced_crits -= 1
		return true
	return false


func is_invulnerable() -> bool:
	return iframe_left > 0.0 or invuln_left > 0.0


func take_damage(amount: float, _source = null) -> void:
	if dead:
		return
	if iframe_left > 0.0:
		_perfect_dodge()
		return
	if invuln_left > 0.0:
		return
	amount *= 1.0 - stats.get_stat("damage_reduction")
	hp -= amount
	invuln_left = HURT_GRACE
	_flash = 0.15
	Fx.text(get_parent(), global_position, str(roundi(amount)), Color("ff5d5d"), 56)
	Events.player_damaged.emit(amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		velocity = Vector3.ZERO
		Fx.burst(get_parent(), global_position, Color("ff7a3d"), 1.3, 30)
		model.visible = false
		Events.screen_shake.emit(0.8)
		died.emit()


func _perfect_dodge() -> void:
	if perfect_this_dash:
		return
	perfect_this_dash = true
	forced_crits = PERFECT_CRITS
	dodge_cd_left *= 0.5
	Fx.text(get_parent(), global_position + Vector3(0, 0.6, 0), "PERFECT", Color("5eead4"), 64)
	Fx.ring(get_parent(), global_position, Color("5eead4"), 3.0, 0.45)
	dodged.emit(true)
	Events.player_dodged.emit(true)
	Engine.time_scale = 0.35
	get_tree().create_timer(0.3, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func heal(amount: float, show: bool = true) -> void:
	if dead or amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	if show and amount >= 1.0:
		Fx.text(get_parent(), global_position, "+%d" % roundi(amount), Color("4ade80"), 52)
	hp_changed.emit(hp, max_hp)
