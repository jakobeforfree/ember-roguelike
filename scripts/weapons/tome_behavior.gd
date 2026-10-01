extends WeaponBehavior
## Tome: calls a frost nova at the target that damages and slows everything
## caught in it. Multishot adds a nova on another enemy; side shots grow the radius.

const RADIUS := 2.2


func attack(target) -> void:
	var targets := [target]
	var extra := stats().geti("multishot")
	if extra > 0:
		var others: Array = player.get_tree().get_nodes_in_group("enemies").filter(func(e): return e != target and e.is_targetable() and Flat.dist(e.global_position, player.global_position) < stats().get_stat("attack_range"))
		others.shuffle()
		targets.append_array(others.slice(0, extra))
	var r := RADIUS * (1.0 + 0.25 * stats().geti("side_shots"))
	var color: Color = def.get("color", Color.WHITE)
	for t in targets:
		var pos: Vector3 = t.global_position
		Fx.ring(player.get_parent(), pos, color, r, 0.35)
		Fx.burst(player.get_parent(), pos, color, 0.8, 12)
		for e in player.get_tree().get_nodes_in_group("enemies"):
			if e.is_targetable() and Flat.dist(e.global_position, pos) <= r + e.radius:
				var roll := Combat.roll_damage(player)
				Combat.player_hits_enemy(player, e, roll[0], roll[1], true)
				if is_instance_valid(e) and not e.dead:
					e.apply_slow(0.5, 1.5)
