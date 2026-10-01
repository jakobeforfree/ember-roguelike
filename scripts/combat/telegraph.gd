class_name Telegraph
extends Node2D
## Visual warning for an incoming enemy attack. The danger zone outline appears
## immediately and fills up; the hit resolves exactly when it is full, using the
## same shape that was drawn - what you see is what hits you.

signal finished(tg: Telegraph)

enum Shape { CIRCLE, LANE, ARC, RING }

var shape := Shape.CIRCLE
var radius := 80.0            # CIRCLE / ARC / RING outer radius
var inner_radius := 0.0       # RING
var direction := Vector2.RIGHT
var length := 300.0           # LANE
var width := 60.0             # LANE
var half_angle := 0.8         # ARC (radians)
var duration := 0.8
var elapsed := 0.0
var color := Color(1.0, 0.2, 0.15)


static func circle(pos: Vector2, r: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.position = pos
	t.radius = r
	t.duration = time
	return t


static func lane(origin: Vector2, dir: Vector2, lane_len: float, w: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.shape = Shape.LANE
	t.position = origin
	t.direction = dir.normalized()
	t.length = lane_len
	t.width = w
	t.duration = time
	return t


static func arc(pos: Vector2, dir: Vector2, r: float, half: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.shape = Shape.ARC
	t.position = pos
	t.direction = dir.normalized()
	t.radius = r
	t.half_angle = half
	t.duration = time
	return t


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		set_process(false)
		finished.emit(self)
		queue_free()


## True if a circle (target_pos, target_radius) overlaps the danger zone.
func contains(target_pos: Vector2, target_radius: float = 0.0) -> bool:
	var local := target_pos - global_position
	match shape:
		Shape.CIRCLE:
			return local.length() <= radius + target_radius
		Shape.RING:
			var d := local.length()
			return d <= radius + target_radius and d >= inner_radius - target_radius
		Shape.ARC:
			if local.length() > radius + target_radius:
				return false
			if local.length() < target_radius:
				return true
			return absf(direction.angle_to(local)) <= half_angle
		Shape.LANE:
			var along := local.dot(direction)
			var across := absf(local.dot(direction.orthogonal()))
			return along >= -target_radius and along <= length + target_radius and across <= width * 0.5 + target_radius
	return false


func _draw() -> void:
	var p := progress()
	var edge := Color(color, 0.95)
	var fill_bg := Color(color, 0.2)
	var fill := Color(color, 0.3 + 0.3 * p)
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, fill_bg)
			draw_circle(Vector2.ZERO, radius * p, fill)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, edge, 3.0)
		Shape.RING:
			draw_arc(Vector2.ZERO, (radius + inner_radius) * 0.5, 0, TAU, 64, fill_bg, radius - inner_radius)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, edge, 3.0)
			draw_arc(Vector2.ZERO, lerpf(inner_radius, radius, p), 0, TAU, 64, edge, 2.0)
		Shape.ARC:
			var a := direction.angle()
			_draw_sector(radius, a, fill_bg)
			_draw_sector(radius * p, a, fill)
			draw_arc(Vector2.ZERO, radius, a - half_angle, a + half_angle, 24, edge, 3.0)
		Shape.LANE:
			var side := direction.orthogonal() * width * 0.5
			var end := direction * length
			draw_colored_polygon(PackedVector2Array([side, end + side, end - side, -side]), fill_bg)
			var pend := direction * length * p
			draw_colored_polygon(PackedVector2Array([side, pend + side, pend - side, -side]), fill)
			draw_polyline(PackedVector2Array([side, end + side, end - side, -side, side]), edge, 3.0)


func _draw_sector(r: float, a: float, c: Color) -> void:
	if r <= 1.0:
		return
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 17:
		pts.append(Vector2.from_angle(a - half_angle + 2.0 * half_angle * i / 16.0) * r)
	draw_colored_polygon(pts, c)
