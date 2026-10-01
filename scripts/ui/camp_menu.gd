class_name CampMenu
extends Control
## The main screen, with no conventional buttons: the camp itself is the menu.
## Click the campfire (or press Enter) to set out; click the backpack (or press B)
## to manage gear. Prompts float above the objects and brighten on hover.

signal start_run

var camp: CampScene
var _prompts := {}
var _hover := ""
var _busy := false
var _fade: ColorRect
var _best: Label
var _gold: Label
var _chrome: Array = []
var _chrome_on := true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()

	var logo := HBoxContainer.new()
	logo.position = Vector2(30, 24)
	logo.add_theme_constant_override("separation", 10)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	_chrome.append(logo)
	logo.add_child(UiKit.icon("local_fire_department", 40, UiKit.ACCENT))
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", -6)
	logo.add_child(t)
	t.add_child(UiKit.label("EMBER", 32, Color.WHITE, 800, 7))
	t.add_child(UiKit.label("A WANDERER'S CAMP", 11, UiKit.MUTED, 700, 4))

	var info := HBoxContainer.new()
	info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	info.offset_left = -420
	info.offset_right = -28
	info.offset_top = 28
	info.alignment = BoxContainer.ALIGNMENT_END
	info.add_theme_constant_override("separation", 10)
	add_child(info)
	_chrome.append(info)
	var best := UiKit.chip("", Color("a78bfa"), "emoji_events", 15)
	_best = UiKit.chip_label(best)
	_best.visible = true
	info.add_child(best)
	var gold := UiKit.chip("", UiKit.GOLD, "toll", 15)
	_gold = UiKit.chip_label(gold)
	_gold.visible = true
	info.add_child(gold)
	var gear := UiKit.button("", "ghost", 18, Vector2(36, 36), "settings")
	gear.tooltip_text = "Settings"
	gear.pressed.connect(open_settings)
	info.add_child(gear)

	_prompts["fire"] = _make_prompt("BEGIN JOURNEY", "ENTER", "local_fire_department", UiKit.ACCENT)
	_prompts["pack"] = _make_prompt("BACKPACK", "B", "backpack", Color("e7c9a0"))

	var foot := UiKit.hint_row([["ENTER", "Set out"], ["B", "Backpack"], ["ESC", "Settings"]])
	foot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	foot.offset_left = -220
	foot.offset_right = 220
	foot.offset_top = -50
	foot.offset_bottom = -24
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.modulate.a = 0.75
	foot.name = "Footer"
	add_child(foot)
	_chrome.append(foot)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.025, 0.04, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	Profile.changed.connect(refresh)
	Controls.mode_changed.connect(func(_t): refresh())
	refresh()


func _make_prompt(title: String, key: String, icon_name: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiKit.icon(icon_name, 22, color))
	var l := UiKit.label(title, 20, Color.WHITE, 800, 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 6)
	row.add_child(l)
	v.add_child(row)
	var hint := UiKit.hint_row([[key, "or click"]], 12)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.name = "Hint"
	v.add_child(hint)
	v.size = Vector2(260, 60)
	v.modulate.a = 0.55
	add_child(v)
	_chrome.append(v)
	return v


func refresh() -> void:
	if not is_inside_tree():
		return
	_best.text = "Best: —" if Profile.best_stage == 0 else "Best: Stage %d" % Profile.best_stage
	_gold.text = str(Profile.gold)
	for id in _prompts:
		var hint: Control = _prompts[id].get_node("Hint")
		hint.visible = not Controls.touch_mode
	get_node("Footer").visible = _chrome_on and not Controls.touch_mode


func _process(_delta: float) -> void:
	if camp == null or not is_instance_valid(camp) or not is_visible_in_tree():
		return
	var mouse := get_viewport().get_mouse_position()
	var hovered := ""
	if not _busy and not _modal_open():
		for id in _prompts:
			var circle := camp.screen_circle(id)
			if mouse.distance_to(circle[0]) < maxf(circle[1] * 1.4, 70.0):
				hovered = id
	_set_hover(hovered)
	for id in _prompts:
		var circle := camp.screen_circle(id)
		var p: Control = _prompts[id]
		p.position = circle[0] - Vector2(p.size.x * 0.5, circle[1] * 1.3 + 74.0)


func _set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	camp.set_hover(id)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if id != "" else Input.CURSOR_ARROW)
	for k in _prompts:
		var p: Control = _prompts[k]
		p.pivot_offset = p.size * 0.5
		var tw := p.create_tween().set_parallel()
		tw.tween_property(p, "modulate:a", 1.0 if k == id else 0.55, 0.15)
		tw.tween_property(p, "scale", Vector2.ONE * (1.08 if k == id else 1.0), 0.15)


func _modal_open() -> bool:
	return get_children().any(func(c): return c is SettingsPanel or c is InventoryScreen)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _busy or _modal_open():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _hover != "":
		get_viewport().set_input_as_handled()
		activate(_hover)
	elif event is InputEventScreenTouch and event.pressed:
		for id in _prompts:
			var circle := camp.screen_circle(id)
			if event.position.distance_to(circle[0]) < maxf(circle[1] * 1.6, 80.0):
				activate(id)
	elif event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		activate("fire")
	elif event.is_action_pressed("backpack"):
		get_viewport().set_input_as_handled()
		activate("pack")
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open_settings()


func activate(id: String) -> void:
	match id:
		"fire":
			_busy = true
			_set_hover("")
			var tw := create_tween()
			tw.tween_property(_fade, "color:a", 1.0, 0.45)
			tw.tween_callback(func():
				_busy = false
				start_run.emit())
		"pack":
			open_inventory()


func open_inventory() -> InventoryScreen:
	_set_hover("")
	var inv := InventoryScreen.new()
	inv.closed.connect(_set_chrome.bind(true))
	_set_chrome(false)
	add_child(inv)
	return inv


func open_settings() -> void:
	if not _modal_open():
		var s := SettingsPanel.new()
		s.closed.connect(_set_chrome.bind(true))
		_set_chrome(false)
		add_child(s)


## Hides the camp's own labels while a full-screen panel is open.
func _set_chrome(on: bool) -> void:
	_chrome_on = on
	for c in _chrome:
		c.visible = on
	if on:
		refresh()


## Called when returning from a run.
func fade_in() -> void:
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, 0.5)
	refresh()
