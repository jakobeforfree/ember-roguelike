class_name Flat
extends RefCounted
## The game is played on the XZ ground plane. Gameplay math (navigation, hit tests)
## uses Vector2(x, z); these helpers convert between the two.


static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func v3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)


## Distance on the ground plane, ignoring height.
static func dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Y rotation that makes a -Z-facing model look along `dir`.
static func yaw(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)
