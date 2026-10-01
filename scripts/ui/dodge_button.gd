class_name DodgeButton
extends Control
## Big round dodge button for the right thumb with a radial cooldown ring.

signal pressed

var cooldown_ratio := 0.0    # 0 = ready, 1 = just used
var cooldown_left := 0.0     # seconds, for the countdown label
var _press := 0.0
var _perfect := 0.0
var _touch := -1
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash_perfect() -> void:
	_perfect = 0.6


func _process(delta: float) -> void:
	_t += delta
	_press = maxf(0.0, _press - delta)
	_perfect = maxf(0.0, _perfect - delta)
	queue_redraw()


func _radius() -> float:
	return minf(size.x, size.y) * 0.5 - 8.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var c := global_position + size * 0.5
		if event.pressed and event.position.distance_to(c) <= _radius() * 1.3:
			_touch = event.index
			_press = 0.12
			pressed.emit()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch:
			_touch = -1


func _draw() -> void:
	var c := size * 0.5
	var r := _radius() * (0.94 if _press > 0.0 else 1.0)
	var is_ready := cooldown_ratio <= 0.0
	draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.25))
	draw_circle(c, r, Color(UiKit.TEAL, 0.9) if is_ready else Color(0.06, 0.07, 0.11, 0.7))
	draw_arc(c, r, 0, TAU, 72, Color(1, 1, 1, 0.25 if is_ready else 0.12), 2.0, true)
	if not is_ready:
		var p := 1.0 - cooldown_ratio
		draw_arc(c, r - 5.0, -PI * 0.5, -PI * 0.5 + TAU * p, 72, UiKit.TEAL, 6.0, true)
	else:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_arc(c, r + 6.0, 0, TAU, 72, Color(UiKit.TEAL, 0.25 + 0.2 * pulse), 3.0, true)
	if _perfect > 0.0:
		var k := 1.0 - _perfect / 0.6
		draw_arc(c, r + 10.0 + k * 40.0, 0, TAU, 72, Color(UiKit.TEAL, 1.0 - k), 5.0, true)
	var fg := Color("06201d") if is_ready else Color(1, 1, 1, 0.55)
	var icon_font := UiKit.icon_font()
	var glyph := Icons.glyph("double_arrow")
	var isz := 52
	var gw := icon_font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, isz).x
	draw_string(icon_font, c + Vector2(-gw * 0.5, 12), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, fg)
	var f := UiKit.font(800, 2)
	var txt := "DODGE" if is_ready else "%.1f" % cooldown_left
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(f, c + Vector2(-tw * 0.5, r * 0.62), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, fg)
