class_name Combat
extends RefCounted
## Central damage pipeline. Keeping hit logic here (instead of inside weapons)
## means every weapon automatically supports crits, lifesteal and elemental procs.

const CHAIN_RANGE := 6.5
const EXPLODE_RADIUS := 2.8


## Rolls outgoing damage for a player attack. Returns [amount, is_crit].
static func roll_damage(player, scale: float = 1.0) -> Array:
	var stats: Stats = player.stats
	var crit: bool = player.consume_forced_crit() or randf() < stats.get_stat("crit_chance")
	var amount := stats.get_stat("damage") * scale * randf_range(0.92, 1.08)
	if crit:
		amount *= stats.get_stat("crit_mult")
	return [amount, crit]


## Applies a player hit to an enemy, including on-hit procs when `procs` is true.
static func player_hits_enemy(player, enemy, amount: float, crit: bool, procs: bool) -> void:
	if enemy == null or not is_instance_valid(enemy) or not enemy.is_targetable():
		return
	enemy.take_damage(amount, crit)
	if player == null or not is_instance_valid(player):
		return
	var stats: Stats = player.stats
	var ls := stats.get_stat("lifesteal")
	if ls > 0.0:
		player.heal(amount * ls, false)
	if not procs:
		return
	var poison := stats.get_stat("poison_dps")
	if poison > 0.0:
		enemy.add_poison(poison, 3.0)
	if randf() < stats.get_stat("burn_chance"):
		enemy.ignite(stats.get_stat("damage") * 0.35, 3.0)
	if randf() < stats.get_stat("slow_chance"):
		enemy.apply_slow(0.5, 2.0)
	if randf() < stats.get_stat("chain_chance"):
		chain_lightning(player, enemy, stats.get_stat("damage") * 0.6, stats.geti("chain_count"))
	if randf() < stats.get_stat("explode_chance"):
		explode(player, enemy.global_position, stats.get_stat("damage") * 0.7)


static func chain_lightning(player, from_enemy, amount: float, jumps: int) -> void:
	var hit := {from_enemy: true}
	var current = from_enemy
	var tree: SceneTree = player.get_tree()
	for i in jumps:
		var best = null
		var best_d := CHAIN_RANGE
		for e in tree.get_nodes_in_group("enemies"):
			if hit.has(e) or not e.is_targetable():
				continue
			var d := Flat.dist(current.global_position, e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			return
		Fx.bolt(current.get_parent(), current.global_position, best.global_position, Color("7dd3fc"))
		hit[best] = true
		player_hits_enemy(player, best, amount, false, false)
		current = best


static func explode(player, pos: Vector3, amount: float) -> void:
	var tree: SceneTree = player.get_tree()
	Events.screen_shake.emit(0.12)
	Fx.ring(player.get_parent(), pos, Color("ff9f43"), EXPLODE_RADIUS, 0.3)
	Fx.burst(player.get_parent(), pos, Color("ffb347"), 1.0, 14)
	for e in tree.get_nodes_in_group("enemies"):
		if e.is_targetable() and Flat.dist(e.global_position, pos) <= EXPLODE_RADIUS + e.radius:
			player_hits_enemy(player, e, amount, false, false)
