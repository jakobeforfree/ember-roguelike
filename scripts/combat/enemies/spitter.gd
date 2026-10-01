extends Enemy
## Ranged caster: keeps its distance, locks an aim line (thin red lane), then fires
## a slow orb along it. At higher difficulty it fires a 3-way spread.

const PREFERRED_MIN := 7.0
const PREFERRED_MAX := 11.5
const AIM_TIME := 0.75
const SHOT_SPEED := 10.5

var _cooldown := 1.2
var _strafe := 1.0


func _build_model() -> Node3D:
	bar_height = 2.0
	return Models.spitter(color)


func _on_ready() -> void:
	_cooldown = randf_range(0.8, 1.8)
	_strafe = 1.0 if randf() < 0.5 else -1.0


func _spread() -> Array:
	return [0.0, -0.28, 0.28] if difficulty >= 3.0 else [0.0]


func _think(delta: float) -> void:
	var hover := model.get_node_or_null("Hover")
	if hover:
		hover.position.y = 1.0 + sin(_t * 3.0) * 0.12
	match state:
		"chase":
			if not player_alive():
				return
			var to := to_player()
			var d := to.length()
			if not has_los() or d > PREFERRED_MAX:
				steer_to(player.global_position)
			elif d < PREFERRED_MIN:
				steer(-to)
			else:
				steer(to.cross(Vector3.UP) * _strafe, 0.5)
			face_player()
			_cooldown -= delta
			if _cooldown <= 0.0 and d < PREFERRED_MAX + 3.5 and has_los():
				set_state("aim")
				var dir := to.normalized()
				var first := true
				for a in _spread():
					var tg := add_telegraph(Telegraph.lane(global_position, dir.rotated(Vector3.UP, a), 19.0, 0.6, AIM_TIME / slow_mult()))
					if first:
						tg.finished.connect(func(_t): _shoot(dir))
						first = false
		"aim":
			if telegraphs.is_empty():
				set_state("chase")
				_cooldown = randf_range(1.8, 2.6)
				_strafe = -_strafe


func _shoot(dir: Vector3) -> void:
	if dead:
		return
	for a in _spread():
		fire_projectile(dir.rotated(Vector3.UP, a), SHOT_SPEED, damage)
