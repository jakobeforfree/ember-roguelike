extends WeaponBehavior
## Daggers: a quick fan of three short-range knives. Multishot adds a knife,
## side shots widen the fan with two more.


func attack(target) -> void:
	var origin: Vector3 = player.global_position
	var dir := dir_to(target)
	var count := 3 + stats().geti("multishot") + stats().geti("side_shots") * 2
	var fan := 0.22 + 0.06 * count
	for i in count:
		var a := lerpf(-fan * 0.5, fan * 0.5, float(i) / maxf(count - 1, 1))
		shoot(origin, dir.rotated(Vector3.UP, a), {"visual": "dagger", "size": 0.18, "range_mult": 1.2})
