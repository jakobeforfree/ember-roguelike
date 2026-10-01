class_name InventoryScreen
extends Control
## The Backpack: loadout (left), inventory + item details (right). Opened from the
## camp by clicking the backpack; the wizard stays visible between the panels.

signal closed

const INV_COLUMNS := 4

var _slots_box: VBoxContainer
var _stats_grid: GridContainer
var _grid: GridContainer
var _detail: VBoxContainer
var _gold: Label
var _inv_title: Label
var _selected: GearItem


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()

	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.06, 0.55)
	add_child(shade)

	_build_top_bar()
	_build_left()
	_build_right()
	Profile.changed.connect(refresh)
	refresh()
	UiKit.pop_in(self, 0.0)


func _build_top_bar() -> void:
	var head := HBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = 28
	head.offset_right = -28
	head.offset_top = 24
	head.offset_bottom = 72
	head.add_theme_constant_override("separation", 12)
	add_child(head)
	head.add_child(UiKit.icon("backpack", 34, UiKit.ACCENT))
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", -6)
	head.add_child(t)
	t.add_child(UiKit.label("BACKPACK", 28, Color.WHITE, 800, 5))
	t.add_child(UiKit.label("THE WANDERER'S GEAR", 11, UiKit.MUTED, 700, 3))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var gold := UiKit.chip("", UiKit.GOLD, "toll", 16)
	_gold = UiKit.chip_label(gold)
	_gold.visible = true
	gold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gold)
	var dev := UiKit.button("Dev: +gear", "ghost", 12, Vector2(0, 40))
	dev.pressed.connect(_dev_grant)
	head.add_child(dev)
	if not Controls.touch_mode:
		var hint := UiKit.hint_row([["ESC", "Close"]])
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(hint)
	var x := UiKit.button("", "secondary", 18, Vector2(44, 44), "close")
	x.pressed.connect(close)
	head.add_child(x)


func _build_left() -> void:
	var p := UiKit.panel()
	p.anchor_top = 0.0
	p.anchor_bottom = 1.0
	p.offset_left = 24
	p.offset_right = 24 + 300
	p.offset_top = 92
	p.offset_bottom = -24
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(_section_title("LOADOUT", "person"))
	_slots_box = VBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 4)
	v.add_child(_slots_box)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	_stats_grid = GridContainer.new()
	_stats_grid.columns = 2
	_stats_grid.add_theme_constant_override("h_separation", 6)
	_stats_grid.add_theme_constant_override("v_separation", 6)
	v.add_child(_stats_grid)


func _build_right() -> void:
	var p := UiKit.panel()
	p.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	p.offset_left = -24 - 372
	p.offset_right = -24
	p.offset_top = 92
	p.offset_bottom = -24
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := _section_title("INVENTORY", "inventory_2")
	_inv_title = head.get_child(2)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = INV_COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	var dp := UiKit.panel(Color(1, 1, 1, 0.035), UiKit.BORDER, 1, 16, 14)
	dp.custom_minimum_size.y = 236
	v.add_child(dp)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 4)
	dp.add_child(_detail)


func _section_title(text: String, icon_name: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(UiKit.icon(icon_name, 18, UiKit.ACCENT))
	h.add_child(UiKit.label(text, 14, UiKit.MUTED, 800, 3))
	var extra := UiKit.label("", 13, UiKit.MUTED, 600)
	extra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(extra)
	return h


func refresh() -> void:
	if not is_inside_tree():
		return
	_gold.text = str(Profile.gold)

	for c in _slots_box.get_children():
		c.queue_free()
	for slot in GearDB.SLOTS:
		_slots_box.add_child(_slot_row(slot, Profile.get_equipped(slot)))

	for c in _stats_grid.get_children():
		c.queue_free()
	var s := Profile.build_stats()
	for st in [["favorite", "%d" % s.get_stat("max_hp"), "HP"], ["trending_up", "%.0f" % s.get_stat("damage"), "DMG"],
			["speed", "%.2f" % s.get_stat("attack_speed"), "ATK/S"], ["gps_fixed", "%d%%" % roundi(s.get_stat("crit_chance") * 100), "CRIT"],
			["shield", "%d%%" % roundi(s.get_stat("damage_reduction") * 100), "ARMOR"], ["double_arrow", "%.2fs" % s.get_stat("dodge_cooldown"), "DODGE"]]:
		_stats_grid.add_child(_stat_cell(st[0], st[1], st[2]))

	for c in _grid.get_children():
		c.queue_free()
	var items := Profile.inventory.duplicate()
	items.sort_custom(func(a, b): return a.power() > b.power())
	for it in items:
		_grid.add_child(_item_tile(it))
	_inv_title.text = "%d / %d" % [Profile.inventory.size(), Profile.MAX_INVENTORY]
	if _selected and Profile.find_item(_selected.uid) == null:
		_selected = null
	if _selected == null and not items.is_empty():
		_selected = items[0]
	_show_detail(_selected)


func _slot_row(slot: String, it: GearItem) -> Button:
	var col := Rarity.color_of(it.rarity) if it else Color(1, 1, 1, 0.25)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 50)
	b.focus_mode = Control.FOCUS_NONE
	var sel := it != null and _selected != null and it.uid == _selected.uid
	b.add_theme_stylebox_override("normal", UiKit.box(Color(1, 1, 1, 0.07) if sel else Color(1, 1, 1, 0.025), 12, Color(1, 1, 1, 0.12) if sel else Color.TRANSPARENT, 1, 6))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(1, 1, 1, 0.06), 12, Color.TRANSPARENT, 0, 6))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(1, 1, 1, 0.1), 12, Color.TRANSPARENT, 0, 6))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var tile := UiKit.panel(Color(col, 0.14), Color(col, 0.5), 1, 10, 0)
	tile.custom_minimum_size = Vector2(38, 38)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(UiKit.icon(_icon_for(it) if it else GearDB.SLOT_INFO[slot]["icon"], 22, col))
	h.add_child(tile)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UiKit.label(GearDB.SLOT_INFO[slot]["label"].to_upper(), 11, UiKit.MUTED, 700, 2))
	v.add_child(UiKit.label(it.name if it else "Empty", 16, col if it else Color(1, 1, 1, 0.3), 600))
	if it:
		b.pressed.connect(func(): _select(it))
	UiKit.press_feedback(b)
	return b


func _stat_cell(icon_name: String, value: String, label: String) -> Control:
	var p := UiKit.panel(Color(1, 1, 1, 0.035), Color.TRANSPARENT, 0, 10, 8)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	h.add_child(UiKit.icon(icon_name, 16, UiKit.MUTED))
	h.add_child(UiKit.label(value, 15, Color.WHITE, 700))
	var l := UiKit.label(label, 11, UiKit.MUTED, 700, 1)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(l)
	return p


func _item_tile(it: GearItem) -> Button:
	var col := Rarity.color_of(it.rarity)
	var sel := _selected != null and it.uid == _selected.uid
	var b := Button.new()
	b.custom_minimum_size = Vector2(76, 76)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiKit.box(Color(col, 0.13), 14, Color.WHITE if sel else Color(col, 0.55), 2 if sel else 1, 0))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(col, 0.2), 14, col, 1, 0))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(col, 0.3), 14, col, 2, 0))
	var ic := UiKit.icon(_icon_for(it), 34, col)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(ic)
	if it.specials.size() > 0:
		var star := UiKit.icon("auto_awesome", 14, UiKit.GOLD)
		star.position = Vector2(6, 4)
		b.add_child(star)
	if Profile.is_equipped(it):
		var badge := UiKit.icon("check", 14, Color("06201d"))
		var dot := UiKit.panel(UiKit.TEAL, Color.TRANSPARENT, 0, 9, 0)
		dot.custom_minimum_size = Vector2(18, 18)
		dot.position = Vector2(53, 5)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(badge)
		b.add_child(dot)
	var lv := UiKit.label("Lv%d" % it.level, 11, Color(1, 1, 1, 0.6), 700)
	lv.position = Vector2(8, 56)
	b.add_child(lv)
	b.pressed.connect(func(): _select(it))
	UiKit.press_feedback(b)
	return b


func _icon_for(it: GearItem) -> String:
	if it.slot == "weapon" and it.weapon_id != "":
		return WeaponDB.get_def(it.weapon_id)["icon"]
	return GearDB.SLOT_INFO[it.slot]["icon"]


func _select(it: GearItem) -> void:
	_selected = it
	refresh()


func _show_detail(it: GearItem) -> void:
	for c in _detail.get_children():
		c.queue_free()
	if it == null:
		_detail.add_child(UiKit.label("Find gear in runs. It's kept even if you fall.", 15, UiKit.MUTED))
		return
	var col := Rarity.color_of(it.rarity)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_detail.add_child(head)
	var tile := UiKit.panel(Color(col, 0.15), Color(col, 0.6), 1, 12, 0)
	tile.custom_minimum_size = Vector2(46, 46)
	tile.add_child(UiKit.icon(_icon_for(it), 26, col))
	head.add_child(tile)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", -2)
	head.add_child(hv)
	hv.add_child(UiKit.label(it.name, 19, col, 700))
	hv.add_child(UiKit.label("%s · %s · Lv %d" % [Rarity.name_of(it.rarity), GearDB.SLOT_INFO[it.slot]["label"], it.level], 13, UiKit.MUTED, 600))
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(lines)
	if it.slot == "weapon":
		var wd := WeaponDB.get_def(it.weapon_id)
		var wl := UiKit.label("%s — %s" % [wd["name"], wd["desc"]], 13, Color(wd["color"]).lightened(0.2), 600)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.add_child(wl)
	for line in it.describe_lines():
		var special := line.begins_with("★")
		var l := UiKit.label(line.trim_prefix("★ "), 14, UiKit.GOLD if special else UiKit.TEXT, 600 if special else 500)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_detail.add_child(row)
	if Profile.is_equipped(it):
		if it.slot != "weapon":
			var u := UiKit.button("Unequip", "secondary", 16, Vector2(0, 44))
			u.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			u.pressed.connect(func(): Profile.unequip(it.slot); Profile.save_profile())
			row.add_child(u)
		else:
			row.add_child(UiKit.label("Equipped", 14, UiKit.TEAL, 700))
	else:
		var e := UiKit.button("Equip", "primary", 16, Vector2(0, 44), "check")
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.pressed.connect(func(): Profile.equip(it.uid); Profile.save_profile())
		row.add_child(e)
		var sv := UiKit.button("+%d" % Profile.salvage_value(it), "gold", 16, Vector2(110, 44), "toll")
		sv.pressed.connect(func(): Profile.salvage(it.uid); Profile.save_profile())
		row.add_child(sv)


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("backpack"):
		get_viewport().set_input_as_handled()
		close()


func _dev_grant() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var it := LootGenerator.generate(rng, 1 + Profile.best_stage * 2, Rarity.roll(rng, 1.5))
	Profile.add_item(it)
	_selected = it
	Profile.save_profile()
	refresh()
