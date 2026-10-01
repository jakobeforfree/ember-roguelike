extends WeaponBehavior
## Sword: a wide melee sweep that hits everything in the arc. Multishot widens the
## arc; side shots add a back-swing. Short range means you must dive in - pair it
## with dodges and defensive upgrades.

const BASE_HALF_ARC := 1.15  # radians (~130 degree sweep)


func attack(target) -> void:
	var dir := dir_to(target)
	var half := BASE_HALF_ARC + 0.18 * stats().geti("multishot")
	var reach := stats().get_stat("attack_range") + 0.4
	_swing(dir, reach, half)
	if stats().geti("side_shots") > 0:
		_swing(-dir, reach * 0.85, 0.9)


func _swing(dir: Vector3, reach: float, half: float) -> void:
	var origin: Vector3 = player.global_position
	Fx.slash(player.get_parent(), origin, dir, reach, half, def.get("color", Color.WHITE))
	for e in player.get_tree().get_nodes_in_group("enemies"):
		if not e.is_targetable():
			continue
		var to: Vector3 = e.global_position - origin
		to.y = 0.0
		if to.length() > reach + e.radius:
			continue
		if to.length() > e.radius and absf(Vector2(dir.x, dir.z).angle_to(Vector2(to.x, to.z))) > half:
			continue
		var roll := Combat.roll_damage(player)
		Combat.player_hits_enemy(player, e, roll[0], roll[1], true)
