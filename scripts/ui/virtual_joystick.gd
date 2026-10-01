class_name VirtualJoystick
extends Control
## Floating joystick: touch anywhere in this area and the stick appears under
## your thumb. Supports multi-touch so the dodge button works at the same time.

@export var max_radius := 95.0
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
			# Drag the base along so the stick never "runs out".
			_center += off - off.limit_length(max_radius)
			off = off.limit_length(max_radius)
		_knob = _center + off
		var v := off / max_radius
		output = Vector2.ZERO if v.length() < deadzone else v
		get_viewport().set_input_as_handled()
		queue_redraw()


func _draw() -> void:
	var base: Vector2
	var knob: Vector2
	var alpha := 0.9
	if _touch == -1:
		base = Vector2(170.0, size.y - 170.0)
		knob = base
		alpha = 0.35
	else:
		base = _center - global_position
		knob = _knob - global_position
	draw_circle(base, max_radius, Color(1, 1, 1, 0.08 * alpha))
	draw_arc(base, max_radius, 0, TAU, 48, Color(1, 1, 1, 0.35 * alpha), 3.0)
	draw_circle(knob, 42.0, Color(1, 1, 1, 0.45 * alpha))
	draw_arc(knob, 42.0, 0, TAU, 32, Color(1, 1, 1, 0.7 * alpha), 2.0)
