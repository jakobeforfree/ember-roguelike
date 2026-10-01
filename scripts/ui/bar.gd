class_name Bar
extends Control
## Minimal health bar with text.

var value := 1.0
var max_value := 1.0
var fill := Color("e8483f")
var text := ""


func set_values(v: float, m: float, t: String = "") -> void:
	value = v
	max_value = maxf(m, 0.001)
	text = t
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(Vector2(2, 2), Vector2((size.x - 4) * clampf(value / max_value, 0, 1), size.y - 4)), fill)
	draw_rect(r, Color(1, 1, 1, 0.5), false, 2.0)
	if text != "":
		var font := ThemeDB.fallback_font
		var fs := int(size.y * 0.7)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2((size.x - w) * 0.5, size.y * 0.5 + fs * 0.35)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
