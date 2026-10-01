class_name UpgradePanel
extends Control
## Pauses the game and offers three upgrade cards. Big touch targets, animated.

signal chosen(id: String)

var choices: Array = []
var _cards: Array = []
var _locked := false


func open(p_choices: Array, taken: Dictionary, title: String = "Choose a Boon", subtitle: String = "") -> void:
	choices = p_choices
	_locked = false
	_cards.clear()
	for c in get_children():
		c.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := UiKit.dim_overlay(0.0)
	add_child(dim)
	dim.create_tween().tween_property(dim, "color:a", 0.8, 0.25)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var t := UiKit.label(title.to_upper(), 34, Color.WHITE, 800, 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st := UiKit.label(subtitle, 16, UiKit.MUTED, 500, 1)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 22
	v.add_child(spacer)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	v.add_child(row)
	for i in choices.size():
		var card := _card(choices[i], taken.get(choices[i], 0))
		row.add_child(card)
		_cards.append(card)
		UiKit.pop_in(card, 0.08 + i * 0.07, 40.0)
	visible = true


func _card(id: String, stacks: int) -> Button:
	var def := UpgradeDB.get_def(id)
	var col: Color = UpgradeDB.CATEGORY_COLORS[def["cat"]]
	var b := Button.new()
	b.custom_minimum_size = Vector2(264, 340)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.box(UiKit.SURFACE_2, 24, Color(col, 0.35), 2))
	b.add_theme_stylebox_override("hover", UiKit.box(UiKit.SURFACE_2.lightened(0.05), 24, Color(col, 0.8), 2))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(col, 0.2), 24, col, 3))
	b.pressed.connect(func(): pick(id))
	UiKit.press_feedback(b)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 22
	v.offset_right = -22
	v.offset_top = 28
	v.offset_bottom = -22
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 12)
	b.add_child(v)

	var ic_wrap := CenterContainer.new()
	ic_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(ic_wrap)
	ic_wrap.add_child(Badge.make(def["icon"], col, 88))

	var chip_wrap := CenterContainer.new()
	chip_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_wrap.add_child(UiKit.chip(String(def["cat"]).to_upper(), col, "", 12))
	v.add_child(chip_wrap)

	var name_l := UiKit.label(def["name"], 25, Color.WHITE, 700)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_l)
	var desc := UiKit.label(def["desc"], 17, UiKit.MUTED, 500)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)

	var maxs: int = def["max"]
	if maxs <= 10:
		var pips := HBoxContainer.new()
		pips.alignment = BoxContainer.ALIGNMENT_CENTER
		pips.add_theme_constant_override("separation", 6)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in maxs:
			var dot := Panel.new()
			dot.custom_minimum_size = Vector2(22, 6)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var c := col if i < stacks else (Color(col, 0.55) if i == stacks else Color(1, 1, 1, 0.1))
			dot.add_theme_stylebox_override("panel", UiKit.box(c, 3, Color.TRANSPARENT, 0, 0))
			pips.add_child(dot)
		v.add_child(pips)
	return b


func pick(id: String) -> void:
	if _locked:
		return
	_locked = true
	var i := choices.find(id)
	for j in _cards.size():
		var card: Control = _cards[j]
		var tw := card.create_tween()
		if j == i:
			tw.tween_property(card, "scale", Vector2.ONE * 1.06, 0.1)
		else:
			tw.tween_property(card, "modulate:a", 0.2, 0.1)
	visible = false
	chosen.emit(id)
