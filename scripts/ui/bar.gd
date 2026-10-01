class_name Bar
extends Control
## Rounded progress bar with a lagging "damage ghost" segment.

var value := 1.0
var max_value := 1.0
var fill := Color("f43f5e")
var text := ""
var text_size := 14
var _ghost := 1.0


func set_values(v: float, m: float, t: String = "") -> void:
	value = v
	max_value = maxf(m, 0.001)
	text = t
	queue_redraw()


func _process(delta: float) -> void:
	var target := clampf(value / max_value, 0, 1)
	if _ghost < target:
		_ghost = target
	elif _ghost > target:
		_ghost = move_toward(_ghost, target, delta * 0.6)
		queue_redraw()


func _draw() -> void:
	var r := int(size.y * 0.5)
	draw_style_box(UiKit.box(Color(0, 0, 0, 0.45), r, Color(1, 1, 1, 0.1), 1, 0), Rect2(Vector2.ZERO, size))
	var ratio := clampf(value / max_value, 0, 1)
	var inner := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	if _ghost > ratio:
		draw_style_box(UiKit.box(Color(1, 1, 1, 0.55), r, Color.TRANSPARENT, 0, 0), Rect2(inner.position, Vector2(inner.size.x * _ghost, inner.size.y)))
	if ratio > 0.0:
		var w := maxf(inner.size.x * ratio, inner.size.y)
		draw_style_box(UiKit.box(fill, r, Color.TRANSPARENT, 0, 0), Rect2(inner.position, Vector2(w, inner.size.y)))
		draw_style_box(UiKit.box(Color(1, 1, 1, 0.18), r, Color.TRANSPARENT, 0, 0), Rect2(inner.position, Vector2(w, inner.size.y * 0.45)))
	if text != "":
		var f := UiKit.font(700)
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		var pos := Vector2((size.x - tw) * 0.5, size.y * 0.5 + text_size * 0.36)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, 3, Color(0, 0, 0, 0.6))
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, Color.WHITE)
