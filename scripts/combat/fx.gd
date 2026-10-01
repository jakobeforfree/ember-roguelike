class_name Fx
extends Node2D
## Tiny self-freeing placeholder effects (rings, bursts, lightning, floating text).

enum Kind { RING, BURST, BOLT, TEXT }

var kind := Kind.RING
var color := Color.WHITE
var radius := 40.0
var life := 0.35
var age := 0.0
var points := PackedVector2Array()
var text := ""
var font_size := 22


static func spawn(parent: Node, k: int, pos: Vector2, c: Color, r: float = 40.0, t: float = 0.35) -> Fx:
	var f := Fx.new()
	f.kind = k
	f.position = pos
	f.color = c
	f.radius = r
	f.life = t
	f.z_index = 20
	parent.add_child(f)
	return f


static func bolt(parent: Node, from: Vector2, to: Vector2, c: Color) -> void:
	var f := spawn(parent, Kind.BOLT, Vector2.ZERO, c, 0.0, 0.22)
	var seg := 7
	for i in seg + 1:
		var p := from.lerp(to, float(i) / seg)
		if i > 0 and i < seg:
			p += (to - from).orthogonal().normalized() * randf_range(-14.0, 14.0)
		f.points.append(p)


static func float_text(parent: Node, pos: Vector2, s: String, c: Color, size: int = 22) -> void:
	var f := spawn(parent, Kind.TEXT, pos + Vector2(randf_range(-10, 10), -20), c, 0.0, 0.7)
	f.text = s
	f.font_size = size
	f.z_index = 50


func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	if kind == Kind.TEXT:
		position.y -= 60.0 * delta
	queue_redraw()


func _draw() -> void:
	var t := age / life
	var c := Color(color, 1.0 - t)
	match kind:
		Kind.RING:
			draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * t), 0, TAU, 32, c, 4.0 * (1.0 - t) + 1.0)
		Kind.BURST:
			draw_circle(Vector2.ZERO, radius * (0.5 + 0.5 * t), Color(color, 0.5 * (1.0 - t)))
			draw_arc(Vector2.ZERO, radius * (0.5 + 0.5 * t), 0, TAU, 32, c, 3.0)
		Kind.BOLT:
			if points.size() > 1:
				draw_polyline(points, c, 3.0)
				draw_polyline(points, Color(1, 1, 1, 1.0 - t), 1.0)
		Kind.TEXT:
			var font := ThemeDB.fallback_font
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
			draw_string_outline(font, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, c.a))
			draw_string(font, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, c)
