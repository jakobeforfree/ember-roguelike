class_name UpgradePanel
extends Control
## Pauses the game and offers three upgrade cards. Big touch targets.

signal chosen(id: String)

var choices: Array = []


func open(p_choices: Array, taken: Dictionary, title: String = "Choose an Upgrade") -> void:
	choices = p_choices
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.dim_overlay())

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 28)
	add_child(v)
	var t := UiKit.label(title, 40, UiKit.ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	v.add_child(row)
	for id in choices:
		row.add_child(_card(id, taken.get(id, 0)))
	visible = true


func _card(id: String, stacks: int) -> Control:
	var def := UpgradeDB.get_def(id)
	var col: Color = UpgradeDB.CATEGORY_COLORS[def["cat"]]
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 330)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.box(UiKit.PANEL, 18, col, 4))
	b.add_theme_stylebox_override("hover", UiKit.box(UiKit.PANEL.lightened(0.08), 18, col, 6))
	b.add_theme_stylebox_override("pressed", UiKit.box(col.darkened(0.6), 18, col, 6))
	b.pressed.connect(func(): pick(id))

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 24
	v.offset_bottom = -20
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 14)
	b.add_child(v)
	var cat := UiKit.label(String(def["cat"]).to_upper(), 18, col)
	cat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cat)
	var title_l := UiKit.label(def["name"], 30)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title_l)
	var desc := UiKit.label(def["desc"], 22, UiKit.MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var maxs: int = def["max"]
	var lvl := UiKit.label("" if maxs > 10 else "Lv %d → %d / %d" % [stacks, stacks + 1, maxs], 20, col)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lvl)
	for c in v.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func pick(id: String) -> void:
	visible = false
	chosen.emit(id)
