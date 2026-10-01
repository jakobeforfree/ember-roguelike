extends Node
## Input layer for PC (keyboard/mouse), gamepad and touch. Actions are registered
## in code so they're readable here and can be rebound from a settings screen later.
## Also tracks whether the player is currently using touch, so the HUD can swap
## between the PC action bar and on-screen thumb controls.

signal mode_changed(touch: bool)

var touch_mode := false


func _enter_tree() -> void:
	_bind("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _btn(JOY_BUTTON_DPAD_LEFT)])
	_bind("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _btn(JOY_BUTTON_DPAD_RIGHT)])
	_bind("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _btn(JOY_BUTTON_DPAD_UP)])
	_bind("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _btn(JOY_BUTTON_DPAD_DOWN)])
	_bind("dodge", [_key(KEY_SPACE), _key(KEY_SHIFT), _btn(JOY_BUTTON_A), _btn(JOY_BUTTON_RIGHT_SHOULDER)])
	_bind("ability", [_key(KEY_Q), _key(KEY_E), _btn(JOY_BUTTON_X), _btn(JOY_BUTTON_LEFT_SHOULDER)])
	_bind("pause", [_key(KEY_ESCAPE), _key(KEY_P), _btn(JOY_BUTTON_START)])
	_bind("journal", [_key(KEY_J)])
	_bind("backpack", [_key(KEY_B), _key(KEY_I), _key(KEY_TAB), _btn(JOY_BUTTON_Y)])
	_bind("confirm", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _btn(JOY_BUTTON_A)])
	_bind("nav_left", [_key(KEY_LEFT), _key(KEY_A), _btn(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_bind("nav_right", [_key(KEY_RIGHT), _key(KEY_D), _btn(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	for i in 3:
		_bind("pick_%d" % (i + 1), [_key(KEY_1 + i), _key(KEY_KP_1 + i)])
	touch_mode = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## Movement from keyboard or gamepad (x = right, y = down the screen).
func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)


## Short label for the first keyboard key bound to an action, e.g. "SPACE".
func key_label(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode).to_upper()
	return "?"


func _input(event: InputEvent) -> void:
	var touch := touch_mode
	if event is InputEventScreenTouch and event.pressed:
		touch = true
	elif event is InputEventKey or event is InputEventJoypadButton:
		touch = false
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and event.relative.length() > 2.0:
		touch = false
	if touch != touch_mode:
		touch_mode = touch
		mode_changed.emit(touch)


func _bind(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
