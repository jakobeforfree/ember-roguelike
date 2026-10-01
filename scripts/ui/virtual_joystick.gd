class_name VirtualJoystick
extends Control
## Floating joystick: touch anywhere in this area and the stick appears under
## your thumb. Supports multi-touch so the dodge button works at the same time.

@export var max_radius := 80.0
@export var deadzone := 0.12

var output := Vector2.ZERO
var _touch := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_active() -> bool:
	return _touch != -1


func release() -> void:
	_touch = -1
	output = Vector2.ZERO
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_VISIBILITY_CHANGED:
		release()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and get_global_rect().has_point(event.position):
			_touch = event.index
			_center = event.position
			_knob = _center
			output = Vector2.ZERO
			get_viewport().set_input_as_handled()
			queue_redraw()
		elif not event.pressed and event.index == _touch:
			release()
	elif event is InputEventScreenDrag and event.index == _touch:
		var off: Vector2 = event.position - _center
		if off.length() > max_radius:
			_center += off - off.limit_length(max_radius)   # base follows the thumb
			off = off.limit_length(max_radius)
		_knob = _center + off
		var v := off / max_radius
		output = Vector2.ZERO if v.length() < deadzone else v
		get_viewport().set_input_as_handled()
		queue_redraw()


func _draw() -> void:
	var active := _touch != -1
	var base := (_center - global_position) if active else Vector2(150.0, size.y - 150.0)
	var knob := (_knob - global_position) if active else base
	var a := 1.0 if active else 0.45
	draw_circle(base, max_radius, Color(0.05, 0.06, 0.1, 0.35 * a))
	draw_arc(base, max_radius, 0, TAU, 64, Color(1, 1, 1, 0.22 * a), 2.0, true)
	if output.length() > 0.0:
		var ang := output.angle()
		draw_arc(base, max_radius, ang - 0.5, ang + 0.5, 24, Color(UiKit.TEAL, 0.9), 4.0, true)
	draw_circle(knob + Vector2(0, 3), 34.0, Color(0, 0, 0, 0.25 * a))
	draw_circle(knob, 34.0, Color(1, 1, 1, 0.85 * a))
	draw_arc(knob, 34.0, 0, TAU, 48, Color(1, 1, 1, a), 1.5, true)
