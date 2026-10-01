extends WeaponBehavior
## Crossbow: slow, heavy bolts with built-in +2 pierce.

const PARALLEL_GAP := 0.4


func attack(target) -> void:
	var origin: Vector3 = player.global_position
	var dir := dir_to(target)
	var side := dir.cross(Vector3.UP)
	var count := 1 + stats().geti("multishot")
	for i in count:
		shoot(origin + side * PARALLEL_GAP * (i - (count - 1) * 0.5), dir, {"visual": "bolt", "size": 0.25, "pierce_bonus": 2})
	for i in stats().geti("side_shots"):
		for s in [-1.0, 1.0]:
			shoot(origin, dir.rotated(Vector3.UP, s * 0.5), {"visual": "bolt", "size": 0.25, "pierce_bonus": 2})
	Events.screen_shake.emit(0.05)
