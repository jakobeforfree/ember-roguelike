class_name Player
extends CharacterBody2D
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
var radius := 18.0
var hp := 100.0
var max_hp := 100.0
var move_input := Vector2.ZERO      # set by controls each frame (0..1 length)
var facing := Vector2.UP
var dodge_cd_left := 0.0
var invuln_left := 0.0             # post-hit grace period
var iframe_left := 0.0             # dodge invincibility
var dash_left := 0.0
var dash_dir := Vector2.ZERO
var dash_hit := {}
var perfect_this_dash := false
var forced_crits := 0
var attack_cd := 0.0
var dead := false
var _flash := 0.0
var _color := Color("ff8c42")


func setup(p_stats: Stats, weapon_id: String, keep_hp_ratio: float = 1.0) -> void:
	stats = p_stats
	max_hp = stats.get_stat("max_hp")
	hp = max_hp * keep_hp_ratio
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
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	_color = CharacterDB.get_def(Profile.character_id)["color"]


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
	dash_dir = move_input.normalized() if move_input.length() > 0.1 else facing
	dash_left = DASH_TIME
	iframe_left = stats.get_stat("iframe_time")
	dodge_cd_left = stats.get_stat("dodge_cooldown")
	dash_hit.clear()
	perfect_this_dash = false
	dodged.emit(false)
	Fx.spawn(get_parent(), Fx.Kind.RING, global_position, Color(0.7, 0.9, 1.0), 30.0, 0.25)
	return true


func _physics_process(delta: float) -> void:
	if dead or stats == null:
		return
	dodge_cd_left = maxf(0.0, dodge_cd_left - delta)
	invuln_left = maxf(0.0, invuln_left - delta)
	iframe_left = maxf(0.0, iframe_left - delta)
	_flash = maxf(0.0, _flash - delta)
	var regen := stats.get_stat("hp_regen")
	if regen > 0.0:
		heal(regen * delta, false)

	if is_dashing():
		dash_left -= delta
		velocity = dash_dir * stats.get_stat("dodge_distance") / DASH_TIME
		_dash_damage()
	else:
		velocity = move_input.limit_length(1.0) * stats.get_stat("move_speed")
		if move_input.length() > 0.1:
			facing = move_input.normalized()
	move_and_slide()

	attack_cd = maxf(0.0, attack_cd - delta)
	weapon.update(delta)
	if attack_cd <= 0.0 and not is_dashing():
		var target = find_target()
		if target:
			facing = (target.global_position - global_position).normalized()
			weapon.attack(target)
			attack_cd = 1.0 / stats.get_stat("attack_speed")
	queue_redraw()


## Nearest visible enemy within attack range.
func find_target():
	var best = null
	var best_d := stats.get_stat("attack_range")
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_targetable():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d and (room == null or not room.segment_blocked(global_position, e.global_position)):
			best_d = d
			best = e
	return best


func _dash_damage() -> void:
	var dmg := stats.get_stat("dash_damage")
	if dmg <= 0.0:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not dash_hit.has(e) and e.is_targetable() and global_position.distance_to(e.global_position) < radius + e.radius + 10.0:
			dash_hit[e] = true
			Combat.player_hits_enemy(self, e, dmg, false, false)


func consume_forced_crit() -> bool:
	if forced_crits > 0:
		forced_crits -= 1
		return true
	return false


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
	Fx.float_text(get_parent(), global_position, str(roundi(amount)), Color("ff4d4d"), 26)
	Events.player_damaged.emit(amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		velocity = Vector2.ZERO
		died.emit()


func _perfect_dodge() -> void:
	if perfect_this_dash:
		return
	perfect_this_dash = true
	forced_crits = PERFECT_CRITS
	dodge_cd_left *= 0.5
	Fx.float_text(get_parent(), global_position + Vector2(0, -30), "PERFECT!", Color("7fe3ff"), 30)
	Fx.spawn(get_parent(), Fx.Kind.RING, global_position, Color("7fe3ff"), 90.0, 0.4)
	dodged.emit(true)
	Events.player_dodged.emit(true)
	Engine.time_scale = 0.35
	get_tree().create_timer(0.3, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func heal(amount: float, show: bool = true) -> void:
	if dead or amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	if show and amount >= 1.0:
		Fx.float_text(get_parent(), global_position, "+%d" % roundi(amount), Color("6be36b"), 24)
	hp_changed.emit(hp, max_hp)


func is_invulnerable() -> bool:
	return iframe_left > 0.0 or invuln_left > 0.0


func _draw() -> void:
	var body := _color
	if _flash > 0.0:
		body = Color.WHITE
	elif is_invulnerable() and int(Time.get_ticks_msec() / 70) % 2 == 0:
		body = Color(body, 0.4)
	if is_dashing():
		for i in 3:
			draw_circle(-dash_dir * (14.0 + i * 14.0), radius * (0.8 - i * 0.2), Color(0.7, 0.9, 1.0, 0.35 - i * 0.1))
	draw_circle(Vector2(0, 6), radius, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, radius, body)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(1, 1, 1, 0.8), 2.0)
	var tip := facing * (radius + 10.0)
	draw_colored_polygon(PackedVector2Array([tip, facing.rotated(2.5) * radius * 0.7, facing.rotated(-2.5) * radius * 0.7]), Color(1, 1, 1, 0.9))
	if forced_crits > 0:
		draw_arc(Vector2.ZERO, radius + 6.0, 0, TAU, 24, Color("7fe3ff"), 2.0)
