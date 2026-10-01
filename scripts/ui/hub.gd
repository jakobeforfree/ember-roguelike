class_name Hub
extends Control
## Camp screen between runs: equipment slots, character stats, inventory,
## item details (equip / salvage) and the Start Run button.

signal start_run

var _equip_box: VBoxContainer
var _stats_label: Label
var _grid: GridContainer
var _detail: VBoxContainer
var _header: Label
var _selected: GearItem


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := UiKit.label("EMBER  ·  Camp", 36, UiKit.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_header = UiKit.label("", 22, Color("ffd166"))
	top.add_child(_header)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 16)
	root.add_child(cols)

	# Left: equipped gear + stats
	var left := UiKit.panel()
	left.custom_minimum_size = Vector2(310, 0)
	cols.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	left.add_child(lv)
	lv.add_child(UiKit.label("Equipped", 24, UiKit.ACCENT))
	_equip_box = VBoxContainer.new()
	_equip_box.add_theme_constant_override("separation", 4)
	lv.add_child(_equip_box)
	_stats_label = UiKit.label("", 17, UiKit.MUTED)
	lv.add_child(_stats_label)

	# Middle: inventory
	var mid := UiKit.panel()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(mid)
	var mv := VBoxContainer.new()
	mid.add_child(mv)
	mv.add_child(UiKit.label("Inventory", 24, UiKit.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mv.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)

	# Right: details + start
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)
	var dpanel := UiKit.panel()
	dpanel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dpanel)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	dpanel.add_child(_detail)
	var start := UiKit.button("START RUN", 34, UiKit.ACCENT, Vector2(0, 96))
	start.pressed.connect(func(): start_run.emit())
	right.add_child(start)
	var dev := UiKit.button("Dev: grant random gear", 16, Color("3a3340"), Vector2(0, 40))
	dev.pressed.connect(_dev_grant)
	right.add_child(dev)

	Profile.changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_inside_tree():
		return
	var best := "—" if Profile.best_stage == 0 else "Stage %d" % Profile.best_stage
	_header.text = "%d gold   ·   Best: %s   ·   Runs: %d" % [Profile.gold, best, Profile.total_runs]

	for c in _equip_box.get_children():
		c.queue_free()
	for slot in GearDB.SLOTS:
		var it := Profile.get_equipped(slot)
		var label: String = GearDB.SLOT_INFO[slot]["label"]
		var b := _item_button("%s: %s" % [label, it.name if it else "—"], it, Vector2(0, 40), 17)
		_equip_box.add_child(b)

	var s := Profile.build_stats()
	_stats_label.text = "HP %d   DMG %.0f   ATK/s %.2f\nCrit %d%% x%.1f   Armor %d%%\nMove %d   Dodge CD %.2fs" % [
		s.get_stat("max_hp"), s.get_stat("damage"), s.get_stat("attack_speed"),
		roundi(s.get_stat("crit_chance") * 100), s.get_stat("crit_mult"), roundi(s.get_stat("damage_reduction") * 100),
		s.get_stat("move_speed"), s.get_stat("dodge_cooldown")]

	for c in _grid.get_children():
		c.queue_free()
	var items := Profile.inventory.duplicate()
	items.sort_custom(func(a, b): return a.power() > b.power())
	for it in items:
		var txt: String = ("[E] " if Profile.is_equipped(it) else "") + "%s\n%s" % [GearDB.SLOT_INFO[it.slot]["label"], it.name]
		_grid.add_child(_item_button(txt, it, Vector2(138, 72), 15))
	if _selected and Profile.find_item(_selected.uid) == null:
		_selected = null
	_show_detail(_selected)


func _item_button(text: String, it: GearItem, min_size: Vector2, fs: int) -> Button:
	var col := Rarity.color_of(it.rarity) if it else Color("555")
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", col.lightened(0.3))
	var sel := it != null and _selected != null and it.uid == _selected.uid
	b.add_theme_stylebox_override("normal", UiKit.box(Color("221d27"), 10, col, 4 if sel else 2))
	b.add_theme_stylebox_override("hover", UiKit.box(Color("2c2633"), 10, col, 3))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color("151118"), 10, col, 3))
	if it:
		b.pressed.connect(func(): _selected = it; refresh())
	return b


func _show_detail(it: GearItem) -> void:
	for c in _detail.get_children():
		c.queue_free()
	if it == null:
		_detail.add_child(UiKit.label("Tap an item to inspect it.", 20, UiKit.MUTED))
		return
	var col := Rarity.color_of(it.rarity)
	var t := UiKit.label(it.name, 26, col)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(t)
	_detail.add_child(UiKit.label("%s %s  ·  Lv %d" % [Rarity.name_of(it.rarity), GearDB.SLOT_INFO[it.slot]["label"], it.level], 18, UiKit.MUTED))
	for line in it.describe_lines():
		var l := UiKit.label(line, 18, Color("ffd166") if line.begins_with("★") else UiKit.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(l)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(spacer)
	if Profile.is_equipped(it):
		if it.slot != "weapon":
			var u := UiKit.button("Unequip", 22, Color("6b5a73"))
			u.pressed.connect(func(): Profile.unequip(it.slot); Profile.save_profile())
			_detail.add_child(u)
	else:
		var e := UiKit.button("Equip", 24)
		e.pressed.connect(func(): Profile.equip(it.uid); Profile.save_profile())
		_detail.add_child(e)
		var sv := UiKit.button("Salvage (+%d gold)" % Profile.salvage_value(it), 20, Color("6b5a73"))
		sv.pressed.connect(func(): Profile.salvage(it.uid); Profile.save_profile())
		_detail.add_child(sv)


func _dev_grant() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Profile.add_item(LootGenerator.generate(rng, 1 + Profile.best_stage * 2, Rarity.roll(rng, 1.5)))
	Profile.save_profile()
