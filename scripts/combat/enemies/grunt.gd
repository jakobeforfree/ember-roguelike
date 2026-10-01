extends Enemy
## Melee bruiser: walks up to you, winds up a wide swipe (red arc), then strikes.
## Dodge out of the arc or roll through it during the windup.

const ATTACK_RANGE := 95.0
const SWIPE_RADIUS := 120.0
const WINDUP := 0.6


func _think(_delta: float) -> void:
	match state:
		"chase":
			if not player_alive():
				return
			var to := to_player()
			if to.length() <= ATTACK_RANGE:
				set_state("windup")
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
	Fx.spawn(get_parent(), Fx.Kind.RING, global_position + tg.direction * 50.0, Color(1, 0.6, 0.5), 50.0, 0.2)


func _draw_body(body: Color) -> void:
	draw_circle(Vector2.ZERO, radius, body)
	var d := to_player().normalized() if player_alive() else Vector2.DOWN
	draw_circle(d * radius * 0.55, 5.0, Color(1, 1, 1, 0.9))
