class_name DodgeButton
extends Control
## Big round dodge button for the right thumb, with a cooldown sweep.

signal pressed

var cooldown_ratio := 0.0    # 0 = ready, 1 = just used
var _flash := 0.0
var _perfect_flash := 0.0
var _touch := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash_perfect() -> void:
	_perfect_flash = 0.5


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_perfect_flash = maxf(0.0, _perfect_flash - delta)
	queue_redraw()


func _radius() -> float:
	return minf(size.x, size.y) * 0.5


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var c := global_position + size * 0.5
		# Generous hit area: 1.25x the visible circle.
		if event.pressed and event.position.distance_to(c) <= _radius() * 1.25:
			_touch = event.index
			_flash = 0.15
			pressed.emit()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch:
			_touch = -1


func _draw() -> void:
	var c := size * 0.5
	var r := _radius()
	var is_ready := cooldown_ratio <= 0.0
	var base := Color("4ab0ff") if is_ready else Color("2b4a66")
	if _flash > 0.0:
		base = base.lightened(0.4)
	draw_circle(c, r, Color(base, 0.55))
	if not is_ready:
		var pts := PackedVector2Array([c])
		var a0 := -PI * 0.5
		var steps := 32
		for i in steps + 1:
			pts.append(c + Vector2.from_angle(a0 + TAU * cooldown_ratio * i / steps) * r)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.45))
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.85 if is_ready else 0.4), 4.0)
	if _perfect_flash > 0.0:
		draw_arc(c, r + 8.0 + (0.5 - _perfect_flash) * 30.0, 0, TAU, 48, Color(0.5, 0.9, 1.0, _perfect_flash * 2.0), 5.0)
	var font := ThemeDB.fallback_font
	var txt := "DODGE"
	var fs := 26
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w * 0.5, 9), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95 if is_ready else 0.5))
