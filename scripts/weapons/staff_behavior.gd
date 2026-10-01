extends WeaponBehavior
## Staff: slow ember orbs that home in on the target and burst on impact,
## splashing 50% damage to enemies around it.

const SPLASH := 1.8


func attack(target) -> void:
	var origin: Vector3 = player.global_position
	var dir := dir_to(target)
	var count := 1 + stats().geti("multishot")
	for i in count:
		var spread := (i - (count - 1) * 0.5) * 0.35
		shoot(origin, dir.rotated(Vector3.UP, spread), {"visual": "orb", "size": 0.3, "homing": target, "explode": SPLASH})
	for i in stats().geti("side_shots"):
		for s in [-1.0, 1.0]:
			shoot(origin, dir.rotated(Vector3.UP, s * (0.9 + i * 0.4)), {"visual": "orb", "size": 0.3, "homing": target, "explode": SPLASH})
