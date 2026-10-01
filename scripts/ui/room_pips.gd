class_name RoomPips
extends Control
## Run progress: one pip per room, the last one is the boss.

var total := 5
var current := 0


func _draw() -> void:
	var gap := 30.0
	var start := size.x * 0.5 - gap * (total - 1) * 0.5
	var y := size.y * 0.5
	draw_line(Vector2(start, y), Vector2(start + gap * (total - 1), y), Color(1, 1, 1, 0.15), 2.0, true)
	for i in total:
		var p := Vector2(start + gap * i, y)
		var boss := i == total - 1
		if i < current:
			draw_circle(p, 6.0, UiKit.ACCENT)
		elif i == current:
			draw_circle(p, 9.0, Color(UiKit.ACCENT, 0.25))
			draw_circle(p, 6.0, Color.WHITE)
		else:
			draw_circle(p, 5.0, Color(0.1, 0.11, 0.16))
			draw_arc(p, 5.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 1.5, true)
		if boss:
			var f := UiKit.icon_font()
			var g := Icons.glyph("dangerous")
			draw_string(f, p + Vector2(-9, -12), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.DANGER)
