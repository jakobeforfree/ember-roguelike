extends Enemy
## Charger: paws the ground while a long lane telegraphs its path, then rushes
## along it. After the charge it is dazed for a moment - your opening to punish.

const CHARGE_TRIGGER := 14.0
const WINDUP := 0.85
const DASH_SPEED := 24.0
const DAZE := 1.0

var _cooldown := 1.5
var _dir := Vector3.FORWARD
var _dash_len := 0.0
var _dashed := 0.0
var _hit_player := false


func _build_model() -> Node3D:
	return Models.charger(color)


func _think(delta: float) -> void:
	match state:
		"chase":
			if not player_alive():
				return
			var to := to_player()
			_cooldown -= delta
			if _cooldown <= 0.0 and to.length() < CHARGE_TRIGGER and has_los():
				set_state("windup")
				_dir = to.normalized()
				facing = _dir
				_dash_len = minf(to.length() + 5.5, 18.0)
				var tg := add_telegraph(Telegraph.lane(global_position, _dir, _dash_len, radius * 2.0 + 0.5, WINDUP / slow_mult()))
				tg.finished.connect(func(_t): _begin_dash())
			else:
				steer_to(player.global_position, 0.8)
		"dash":
			velocity = _dir * DASH_SPEED
			_dashed += DASH_SPEED * delta
			if not _hit_player and player_alive() and Flat.dist(global_position, player.global_position) < radius + player.radius:
				_hit_player = true
				player.take_damage(damage, self)
			if _dashed >= _dash_len or get_slide_collision_count() > 0:
				set_state("dazed")
				collision_mask = 1 | 4
				Fx.ring(get_parent(), global_position, Color(1, 0.8, 0.4), 1.5, 0.3)
				Fx.burst(get_parent(), global_position, Color("a8a29e"), 0.7, 10)
		"dazed":
			model.rotation.z = sin(state_time * 18.0) * 0.12
			if state_time > DAZE:
				model.rotation.z = 0.0
				set_state("chase")
				_cooldown = randf_range(1.6, 2.4)


func _begin_dash() -> void:
	if dead:
		return
	set_state("dash")
	_dashed = 0.0
	_hit_player = false
	collision_mask = 1   # pass through other enemies
