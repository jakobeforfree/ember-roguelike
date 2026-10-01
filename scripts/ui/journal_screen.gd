class_name JournalScreen
extends Control
## The Wanderer's journal: the worlds he has crossed and the pages he has found.

signal closed

const HOW_TO_FIND := ["Reach this world to recover this page.", "Hidden somewhere in this world. Clear rooms to find it.", "Defeat this world's guardian."]

var _list: VBoxContainer
var _body: VBoxContainer
var _selected := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.06, 0.72)
	add_child(shade)

	var head := HBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = 28
	head.offset_right = -28
	head.offset_top = 24
	head.offset_bottom = 72
	head.add_theme_constant_override("separation", 12)
	add_child(head)
	head.add_child(UiKit.icon("menu_book", 34, Color("ffcf7a")))
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", -6)
	head.add_child(t)
	t.add_child(UiKit.label("JOURNAL", 28, Color.WHITE, 800, 5))
	t.add_child(UiKit.label("THE WANDERER'S ACCOUNT", 11, UiKit.MUTED, 700, 3))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var total := WorldDB.count() * 3
	var found := Profile.lore.size()
	var chip := UiKit.chip("%d / %d pages" % [found, total], Color("ffcf7a"), "menu_book", 15)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(chip)
	if not Controls.touch_mode:
		var hint := UiKit.hint_row([["ESC", "Close"]])
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(hint)
	var x := UiKit.button("", "secondary", 18, Vector2(44, 44), "close")
	x.pressed.connect(close)
	head.add_child(x)

	var left := UiKit.panel()
	left.anchor_bottom = 1.0
	left.offset_left = 24
	left.offset_right = 24 + 330
	left.offset_top = 92
	left.offset_bottom = -24
	add_child(left)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	left.add_child(_list)

	var right := UiKit.panel()
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = 24 + 330 + 16
	right.offset_right = -24
	right.offset_top = 92
	right.offset_bottom = -24
	add_child(right)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	scroll.add_child(_body)

	# Open on the furthest world reached
	for i in WorldDB.count():
		if _reached(i):
			_selected = i
	_refresh()
	UiKit.pop_in(self, 0.0)


func _reached(i: int) -> bool:
	return Profile.has_lore(WorldDB.page_id(WorldDB.WORLDS[i]["id"], 0))


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(UiKit.label("WORLDS", 13, UiKit.MUTED, 800, 3))
	for i in WorldDB.count():
		_list.add_child(_world_row(i))
	for c in _body.get_children():
		c.queue_free()
	var w: Dictionary = WorldDB.WORLDS[_selected]
	var col: Color = w["color"]
	if not _reached(_selected):
		_body.add_child(UiKit.label("Uncharted", 30, UiKit.MUTED, 800))
		var l := UiKit.label("The Wanderer has not reached this world yet. Keep descending.", 17, UiKit.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(l)
		return
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 12)
	title.add_child(Badge.make(w["icon"], col, 52))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.add_child(UiKit.label(w["name"], 30, col.lightened(0.2), 800))
	tv.add_child(UiKit.label(w["tagline"], 16, UiKit.MUTED, 500))
	title.add_child(tv)
	_body.add_child(title)
	for p in 3:
		_body.add_child(_page_card(w, p))


func _world_row(i: int) -> Button:
	var w: Dictionary = WorldDB.WORLDS[i]
	var reached := _reached(i)
	var col: Color = w["color"] if reached else Color(1, 1, 1, 0.3)
	var sel := i == _selected
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.box(Color(1, 1, 1, 0.07) if sel else Color(1, 1, 1, 0.02), 14, Color(col, 0.6) if sel else Color.TRANSPARENT, 1, 8))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(1, 1, 1, 0.06), 14, Color.TRANSPARENT, 0, 8))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(1, 1, 1, 0.1), 14, Color.TRANSPARENT, 0, 8))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var badge := Badge.make(w["icon"] if reached else "lock", col, 42)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UiKit.label("WORLD %d" % (i + 1), 11, UiKit.MUTED, 800, 2))
	v.add_child(UiKit.label(w["name"] if reached else "Uncharted", 17, Color.WHITE if reached else UiKit.MUTED, 700))
	var n := 0
	for p in 3:
		if Profile.has_lore(WorldDB.page_id(w["id"], p)):
			n += 1
	var cnt := UiKit.label("%d/3" % n, 14, Color("ffcf7a") if n == 3 else UiKit.MUTED, 700)
	cnt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(cnt)
	var pad := Control.new()
	pad.custom_minimum_size.x = 6
	h.add_child(pad)
	b.pressed.connect(func(): _selected = i; _refresh())
	UiKit.press_feedback(b)
	return b


func _page_card(w: Dictionary, p: int) -> Control:
	var unlocked := Profile.has_lore(WorldDB.page_id(w["id"], p))
	var card := UiKit.panel(Color(1, 1, 1, 0.035) if unlocked else Color(1, 1, 1, 0.015), Color(1, 1, 1, 0.06), 1, 16, 18)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	if unlocked:
		var page: Array = WorldDB.page(w["id"], p)
		v.add_child(UiKit.label(page[0], 20, Color("ffcf7a"), 700))
		var body := UiKit.label(page[1], 17, Color("e5e1d8"), 500)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(body)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(UiKit.icon("lock", 18, UiKit.MUTED))
		row.add_child(UiKit.label("Missing page", 18, UiKit.MUTED, 700))
		v.add_child(row)
		v.add_child(UiKit.label(HOW_TO_FIND[p], 15, Color(1, 1, 1, 0.35), 500))
	return card


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		close()
