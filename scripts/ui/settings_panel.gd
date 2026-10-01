class_name SettingsPanel
extends Control
## Modal settings screen (fullscreen, screen shake, damage numbers) + controls reference.

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.dim_overlay(0.7))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UiKit.panel(UiKit.SURFACE_2, Color(1, 1, 1, 0.12), 1, 24, 28)
	p.custom_minimum_size = Vector2(520, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiKit.icon("settings", 24, UiKit.ACCENT))
	var t := UiKit.label("  SETTINGS", 22, Color.WHITE, 800, 3)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := UiKit.button("", "ghost", 18, Vector2(44, 44), "close")
	x.pressed.connect(close)
	head.add_child(x)
	v.add_child(head)
	v.add_child(_toggle("Fullscreen", "fullscreen", "open_in_full"))
	v.add_child(_toggle("Screen shake", "screen_shake", "blur_on"))
	v.add_child(_toggle("Damage numbers", "damage_numbers", "military_tech"))
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UiKit.box(Color(1, 1, 1, 0.08), 0, Color.TRANSPARENT, 0, 0))
	v.add_child(sep)
	v.add_child(UiKit.label("CONTROLS", 13, UiKit.MUTED, 800, 3))
	for row in [[["WASD", "Move"], ["SPACE", "Dodge"], ["ESC", "Pause"]], [["1 2 3", "Pick upgrade"], ["ENTER", "Start run"]]]:
		v.add_child(UiKit.hint_row(row, 14))
	v.add_child(UiKit.label("Gamepad: left stick to move, A / RB to dodge, Start to pause. Attacks are automatic.", 13, UiKit.MUTED, 500))
	var done := UiKit.button("Done", "primary", 18, Vector2(0, 52))
	done.pressed.connect(close)
	v.add_child(done)
	UiKit.pop_in(p)


func _toggle(text: String, key: String, icon_name: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UiKit.icon(icon_name, 22, UiKit.MUTED))
	var l := UiKit.label(text, 18, UiKit.TEXT, 600)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var sw := CheckButton.new()
	sw.focus_mode = Control.FOCUS_NONE
	sw.button_pressed = Settings.get(key)
	sw.toggled.connect(func(on): Settings.set_value(key, on))
	row.add_child(sw)
	return row


func close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
