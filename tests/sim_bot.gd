class_name SimBot
extends RefCounted
## Automated player used by tests: dodges out of telegraphs, kites enemies,
## collects loot and walks to the gate. Gives a rough read on difficulty.

var run: RunController
var dodges := 0
var perfect := 0
var damage_taken := 0.0
var _wp := Vector2.ZERO
var _wp_goal := Vector2(INF, INF)
var _wp_hold := 0


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
	var here := Flat.xz(p.global_position)
	var move := Vector2.ZERO
	# 1. Danger: if standing in a telegraph, dodge away from it.
	for tg in room.ground.get_children():
		if tg is Telegraph and tg.contains(p.global_position, p.radius) and tg.progress() > 0.45:
			var away := here - Flat.xz(tg.global_position)
			if tg.shape == Telegraph.Shape.LANE:
				var side := Vector2(tg.direction.x, tg.direction.z).orthogonal()
				away = side * signf(away.dot(side) + 0.001)
			p.move_input = away.normalized()
			if p.try_dodge():
				return
			move += away.normalized() * 2.0
	# 2. Loot, then the gate.
	var loot := room.entities.get_children().filter(func(n): return n is LootPickup)
	if not loot.is_empty():
		move += (_waypoint(room, here, Flat.xz(loot[0].global_position), p.radius) - here).normalized()
	elif room.door_open:
		move += (_waypoint(room, here, room.door_rect.get_center(), p.radius) - here).normalized()
	else:
		# 3. Kite: keep ~6.5m from the closest enemy, drift toward room center.
		var closest = null
		var cd := INF
		for e in room.alive:
			if is_instance_valid(e) and not e.dead:
				var d := Flat.dist(p.global_position, e.global_position)
				if d < cd:
					cd = d
					closest = e
		if closest and cd < 6.5:
			move += (here - Flat.xz(closest.global_position)).normalized()
		move += (room.bounds.get_center() - here) / 20.0
	p.move_input = move.limit_length(1.0)


## Commits to a waypoint for a moment (like enemies do) so equal-length routes don't flip-flop.
func _waypoint(room: Room, here: Vector2, goal: Vector2, pad: float) -> Vector2:
	_wp_hold -= 1
	if _wp_hold <= 0 or here.distance_to(_wp) < 0.3 or goal.distance_to(_wp_goal) > 0.5:
		_wp = room.next_waypoint(here, goal, pad)
		_wp_goal = goal
		_wp_hold = 15
	return _wp


func _best_choice(choices: Array) -> String:
	var prefer := ["power", "haste", "multishot", "vitality", "heal", "crit", "pierce", "armor"]
	for id in prefer:
		if id in choices:
			return id
	return choices[0]
