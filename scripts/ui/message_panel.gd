class_name MessagePanel
extends Control
## Generic modal card: icon, title, body lines and buttons. Used for pause,
## defeat and stage-clear screens.

signal action(id: String)

var _ids: Array = []


## lines: Array of String or [text, color]. buttons: [[id, text, kind, icon], ...]
func open(title: String, color: Color, icon_name: String, lines: Array, buttons: Array) -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.dim_overlay(0.75))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UiKit.panel(UiKit.SURFACE_2, Color(color, 0.35), 1, 28, 32)
	p.custom_minimum_size = Vector2(500, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var ic_wrap := CenterContainer.new()
	ic_wrap.add_child(Badge.make(icon_name, color, 72))
	v.add_child(ic_wrap)
	var t := UiKit.label(title, 36, Color.WHITE, 800, 3)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for line in lines:
		var txt: String = line[0] if line is Array else line
		var col: Color = line[1] if line is Array else UiKit.MUTED
		var l := UiKit.label(txt, 18, col, 600 if line is Array else 500)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size.y = 10
	v.add_child(gap)
	_ids.clear()
	for b in buttons:
		_ids.append(b[0])
		var btn := UiKit.button(b[1], b[2] if b.size() > 2 else "primary", 20, Vector2(0, 60), b[3] if b.size() > 3 else "")
		var id: String = b[0]
		btn.pressed.connect(func(): action.emit(id))
		v.add_child(btn)
	if not Controls.touch_mode and _ids.size() > 0:
		var hint := UiKit.hint_row([["ENTER", "Confirm"]] + ([["ESC", "Resume"]] if "resume" in _ids else []))
		hint.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(hint)
	visible = true
	UiKit.pop_in(p, 0.0, 24.0)


func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree() or get_child_count() > 0 and get_children().any(func(c): return c is SettingsPanel):
		return
	if event.is_action_pressed("pause") and "resume" in _ids:
		get_viewport().set_input_as_handled()
		action.emit("resume")
	elif event.is_action_pressed("confirm") and _ids.size() > 0:
		get_viewport().set_input_as_handled()
		action.emit(_ids[0])
