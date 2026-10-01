extends WeaponBehavior
## Bow: fast arrows. Multishot adds parallel arrows, side shots add diagonal pairs.

const PARALLEL_GAP := 0.35
const SIDE_ANGLES := [0.45, 0.8]


func attack(target) -> void:
	var origin: Vector3 = player.global_position
	var dir := dir_to(target)
	var side := dir.cross(Vector3.UP)
	var forward := 1 + stats().geti("multishot")
	for i in forward:
		shoot(origin + side * PARALLEL_GAP * (i - (forward - 1) * 0.5), dir)
	for i in mini(stats().geti("side_shots"), SIDE_ANGLES.size()):
		shoot(origin, dir.rotated(Vector3.UP, SIDE_ANGLES[i]))
		shoot(origin, dir.rotated(Vector3.UP, -SIDE_ANGLES[i]))
