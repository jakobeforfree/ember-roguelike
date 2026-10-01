class_name MessagePanel
extends Control
## Generic modal: title, body lines and a list of buttons. Used for pause,
## game over and stage-clear screens.

signal action(id: String)


func open(title: String, title_color: Color, lines: PackedStringArray, buttons: Array) -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.dim_overlay())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UiKit.panel(UiKit.PANEL, title_color, 3)
	p.custom_minimum_size = Vector2(560, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var t := UiKit.label(title, 44, title_color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for line in lines:
		var l := UiKit.label(line, 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if line.begins_with("#"):
			# "#rrggbb|text" lets callers color a line (e.g. rarity-colored loot).
			var parts := line.split("|", true, 1)
			l.text = parts[1]
			l.add_theme_color_override("font_color", Color(parts[0]))
		v.add_child(l)
	v.add_child(Control.new())
	for b in buttons:
		var btn := UiKit.button(b[1], 26, b[2] if b.size() > 2 else UiKit.ACCENT, Vector2(0, 70))
		var id: String = b[0]
		btn.pressed.connect(func(): action.emit(id))
		v.add_child(btn)
	visible = true
