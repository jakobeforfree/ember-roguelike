extends WeaponBehavior
## Wand: instant lightning to the target that leaps to nearby enemies.
## Multishot strikes extra targets; side shots add more leaps.

const BASE_JUMPS := 2


func attack(target) -> void:
	var targets := [target]
	var extra := stats().geti("multishot")
	if extra > 0:
		var others: Array = player.get_tree().get_nodes_in_group("enemies").filter(func(e): return e != target and e.is_targetable() and Flat.dist(e.global_position, player.global_position) < stats().get_stat("attack_range"))
		others.sort_custom(func(a, b): return Flat.dist(a.global_position, player.global_position) < Flat.dist(b.global_position, player.global_position))
		targets.append_array(others.slice(0, extra))
	var color: Color = def.get("color", Color.WHITE)
	for t in targets:
		var roll := Combat.roll_damage(player)
		Fx.bolt(player.get_parent(), player.global_position + Vector3(0, 0.3, 0), t.global_position, color)
		Combat.player_hits_enemy(player, t, roll[0], roll[1], true)
		if is_instance_valid(t):
			Combat.chain_lightning(player, t, roll[0] * 0.7, BASE_JUMPS + stats().geti("side_shots"))
