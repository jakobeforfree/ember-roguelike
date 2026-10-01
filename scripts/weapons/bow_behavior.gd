extends WeaponBehavior
## Bow: fast projectiles. Multishot adds parallel arrows, side shots add diagonal pairs.

const PARALLEL_GAP := 0.35
const SIDE_ANGLES := [0.45, 0.8]


func attack(target) -> void:
	var stats: Stats = player.stats
	var origin: Vector3 = player.global_position
	var dir: Vector3 = target.global_position - origin
	dir.y = 0.0
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP)
	var forward := 1 + stats.geti("multishot")
	for i in forward:
		_fire(origin + side * PARALLEL_GAP * (i - (forward - 1) * 0.5), dir)
	for i in mini(stats.geti("side_shots"), SIDE_ANGLES.size()):
		_fire(origin, dir.rotated(Vector3.UP, SIDE_ANGLES[i]))
		_fire(origin, dir.rotated(Vector3.UP, -SIDE_ANGLES[i]))


func _fire(pos: Vector3, dir: Vector3) -> void:
	var stats: Stats = player.stats
	var roll := Combat.roll_damage(player)
	var p := Projectile.new()
	p.team = Projectile.Team.PLAYER
	p.position = pos + dir * 0.6
	p.velocity = dir * stats.get_stat("projectile_speed")
	p.damage = roll[0]
	p.crit = roll[1]
	p.pierce = stats.geti("pierce")
	p.max_distance = stats.get_stat("attack_range") * 1.6
	p.color = def.get("color", Color.WHITE)
	p.room = player.room
	p.source = player
	player.get_parent().add_child(p)
