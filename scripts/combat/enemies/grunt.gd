extends Enemy
## Melee bruiser: walks up to you, winds up a wide swipe (red arc), then strikes.
## Dodge out of the arc or roll through it during the windup.

const ATTACK_RANGE := 2.3
const SWIPE_RADIUS := 3.0
const WINDUP := 0.6


func _build_model() -> Node3D:
	return Models.grunt(color)


func _think(_delta: float) -> void:
	match state:
		"chase":
			if not player_alive():
				return
			var to := to_player()
			if to.length() <= ATTACK_RANGE:
				set_state("windup")
				face_player()
				var tg := add_telegraph(Telegraph.arc(global_position, to, SWIPE_RADIUS, 0.95, WINDUP / slow_mult()))
				tg.finished.connect(_on_swipe)
			else:
				steer_to(player.global_position)
		"windup":
			if telegraphs.is_empty():
				set_state("recover")
		"recover":
			if state_time > 0.55:
				set_state("chase")


func _on_swipe(tg: Telegraph) -> void:
	if dead:
		return
	resolve_hit(tg, damage)
	Fx.ring(get_parent(), global_position + tg.direction * 1.4, Color(1, 0.55, 0.45), 1.6, 0.2)
