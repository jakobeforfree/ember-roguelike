class_name SimBot
extends RefCounted
## Automated player used by tests: dodges out of telegraphs, kites enemies,
## collects loot and walks to the door. Gives a rough read on difficulty.

var run: RunController
var dodges := 0
var perfect := 0
var damage_taken := 0.0
var rooms_seen := 0


func _init(p_run: RunController) -> void:
	run = p_run
	run.player.dodged.connect(func(p): dodges += 1; perfect += int(p))
	Events.player_damaged.connect(func(a): damage_taken += a)


func step() -> void:
	if run.upgrade_panel.visible:
		run.upgrade_panel.pick(_best_choice(run.upgrade_panel.choices))
		return
	var p := run.player
	if p == null or p.dead or run.room == null:
		return
	var room := run.room
	var move := Vector2.ZERO
	# 1. Danger: if standing in a telegraph, dodge away from it.
	for tg in room.ground.get_children():
		if tg is Telegraph and tg.contains(p.global_position, p.radius) and tg.progress() > 0.45:
			var away: Vector2 = p.global_position - tg.global_position
			if tg.shape == Telegraph.Shape.LANE:
				away = tg.direction.orthogonal() * signf(away.dot(tg.direction.orthogonal()) + 0.001)
			p.move_input = away.normalized()
			if p.try_dodge():
				return
			move += away.normalized() * 2.0
	# 2. Loot, then the door.
	var loot := room.entities.get_children().filter(func(n): return n is LootPickup)
	if not loot.is_empty():
		move += (room.next_waypoint(p.global_position, loot[0].global_position, p.radius) - p.global_position).normalized()
	elif room.door_open:
		move += (room.next_waypoint(p.global_position, room.door_rect.get_center(), p.radius) - p.global_position).normalized()
	else:
		# 3. Kite: keep ~260px from the closest enemy, drift toward room center.
		var closest = null
		var cd := INF
		for e in room.alive:
			if is_instance_valid(e) and not e.dead:
				var d := p.global_position.distance_to(e.global_position)
				if d < cd:
					cd = d
					closest = e
		if closest and cd < 260.0:
			move += (p.global_position - closest.global_position).normalized()
		move += (room.bounds.get_center() - p.global_position) / 800.0
	p.move_input = move.limit_length(1.0)


func _best_choice(choices: Array) -> String:
	var prefer := ["power", "haste", "multishot", "vitality", "heal", "crit", "pierce", "armor"]
	for id in prefer:
		if id in choices:
			return id
	return choices[0]
