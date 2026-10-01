extends Enemy
## Charger: paws the ground while a long lane telegraphs its path, then rushes
## along it. After the charge it is dazed for a moment - your opening to punish.

const CHARGE_TRIGGER := 560.0
const WINDUP := 0.85
const DASH_SPEED := 950.0
const DAZE := 1.0

var _cooldown := 1.5
var _dir := Vector2.ZERO
var _dash_len := 0.0
var _dashed := 0.0
var _hit_player := false


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
				_dash_len = minf(to.length() + 220.0, 720.0)
				var tg := add_telegraph(Telegraph.lane(global_position, _dir, _dash_len, radius * 2.0 + 18.0, WINDUP / slow_mult()))
				tg.finished.connect(func(_t): _begin_dash())
			else:
				steer_to(player.global_position, 0.8)
		"windup":
			pass
		"dash":
			var step := DASH_SPEED * delta
			velocity = _dir * DASH_SPEED
			_dashed += step
			if not _hit_player and player_alive() and global_position.distance_to(player.global_position) < radius + player.radius:
				_hit_player = true
				player.take_damage(damage, self)
			if _dashed >= _dash_len or get_slide_collision_count() > 0:
				set_state("dazed")
				collision_mask = 1 | 4
				Fx.spawn(get_parent(), Fx.Kind.RING, global_position, Color(1, 0.8, 0.4), 40.0, 0.3)
		"dazed":
			if state_time > DAZE:
				set_state("chase")
				_cooldown = randf_range(1.6, 2.4)


func _begin_dash() -> void:
	if dead:
		return
	set_state("dash")
	_dashed = 0.0
	_hit_player = false
	collision_mask = 1   # pass through other enemies


func _draw_body(body: Color) -> void:
	var d := _dir if _dir != Vector2.ZERO else Vector2.DOWN
	var pts := PackedVector2Array([d * radius * 1.3, d.rotated(2.3) * radius, d.rotated(-2.3) * radius])
	draw_circle(Vector2.ZERO, radius * 0.85, body)
	draw_colored_polygon(pts, body.darkened(0.2))
	if state == "dazed":
		for i in 3:
			var a := state_time * 6.0 + i * TAU / 3.0
			draw_circle(Vector2.from_angle(a) * radius * 0.9 + Vector2(0, -radius), 3.0, Color.YELLOW)
