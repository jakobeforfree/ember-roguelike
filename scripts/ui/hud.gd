class_name Hud
extends Control
## In-run HUD: health, upgrades, room progress, gold, boss bar, enemy bars,
## toasts and the touch controls. Layout keeps both thumbs' zones clear.

signal pause_pressed

var camera: Camera3D
var joystick: VirtualJoystick
var dodge: DodgeButton
var hp_bar: Bar
var boss_bar: Bar
var boss_box: VBoxContainer
var boss_chip: Control
var pips: RoomPips
var wave_label: Label
var gold_label: Label
var upgrade_row: HBoxContainer
var toast: Label
var toast_sub: Label
var _toast_box: VBoxContainer
var _bars: Control
var _toast_tw: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bars = Control.new()
	_bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_enemy_bars)
	add_child(_bars)

	joystick = VirtualJoystick.new()
	joystick.anchor_right = 0.5
	joystick.anchor_top = 0.2
	joystick.anchor_bottom = 1.0
	add_child(joystick)

	dodge = DodgeButton.new()
	dodge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dodge.offset_left = -236
	dodge.offset_top = -236
	dodge.offset_right = -44
	dodge.offset_bottom = -44
	add_child(dodge)

	# Top-left: portrait + health + upgrades
	var tl := HBoxContainer.new()
	tl.position = Vector2(24, 20)
	tl.add_theme_constant_override("separation", 12)
	add_child(tl)
	tl.add_child(Badge.make("local_fire_department", UiKit.ACCENT, 56, 0.2))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	tl.add_child(col)
	hp_bar = Bar.new()
	hp_bar.custom_minimum_size = Vector2(260, 22)
	hp_bar.fill = Color("f43f5e")
	col.add_child(hp_bar)
	upgrade_row = HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation", 6)
	col.add_child(upgrade_row)

	# Top-center: room progress
	var tc := VBoxContainer.new()
	tc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tc.offset_left = -160
	tc.offset_right = 160
	tc.offset_top = 18
	tc.add_theme_constant_override("separation", 2)
	add_child(tc)
	pips = RoomPips.new()
	pips.custom_minimum_size = Vector2(320, 34)
	tc.add_child(pips)
	wave_label = UiKit.label("", 14, UiKit.MUTED, 700, 2)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(wave_label)

	# Boss bar
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.offset_left = -230
	boss_box.offset_right = 230
	boss_box.offset_top = -78
	boss_box.offset_bottom = -30
	boss_box.add_theme_constant_override("separation", 6)
	boss_box.visible = false
	add_child(boss_box)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 10)
	boss_box.add_child(bh)
	bh.add_child(UiKit.label("CINDER GOLEM", 16, Color("fdba74"), 800, 3))
	boss_chip = UiKit.chip("ENRAGED", UiKit.DANGER, "", 12)
	boss_chip.visible = false
	bh.add_child(boss_chip)
	boss_bar = Bar.new()
	boss_bar.custom_minimum_size = Vector2(460, 14)
	boss_bar.fill = Color("ff7a2f")
	boss_box.add_child(boss_bar)

	# Top-right: gold + pause
	var tr := HBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.offset_left = -260
	tr.offset_right = -24
	tr.offset_top = 22
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 10)
	add_child(tr)
	var gold := UiKit.chip("0", UiKit.GOLD, "toll", 18)
	gold_label = UiKit.chip_label(gold)
	gold_label.visible = true
	tr.add_child(gold)
	var pause := UiKit.button("", "secondary", 20, Vector2(52, 52), "pause")
	pause.pressed.connect(func(): pause_pressed.emit())
	tr.add_child(pause)

	# Center toast
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER)
	_toast_box.offset_left = -400
	_toast_box.offset_right = 400
	_toast_box.offset_top = -190
	_toast_box.offset_bottom = -100
	_toast_box.modulate.a = 0.0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)
	toast = UiKit.label("", 44, Color.WHITE, 800, 4)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	toast.add_theme_constant_override("outline_size", 8)
	_toast_box.add_child(toast)
	toast_sub = UiKit.label("", 18, UiKit.MUTED, 600, 2)
	toast_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_box.add_child(toast_sub)


func hide_message() -> void:
	if _toast_tw:
		_toast_tw.kill()
	_toast_box.modulate.a = 0.0


func show_message(text: String, time: float = 1.6, sub: String = "", color: Color = Color.WHITE) -> void:
	toast.text = text
	toast.add_theme_color_override("font_color", color)
	toast_sub.text = sub
	_toast_box.pivot_offset = _toast_box.size * 0.5
	if _toast_tw:
		_toast_tw.kill()
	var tw := _toast_box.create_tween()
	_toast_tw = tw
	_toast_box.scale = Vector2.ONE * 0.85
	tw.tween_property(_toast_box, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_toast_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(time)
	tw.tween_property(_toast_box, "modulate:a", 0.0, 0.35)


func set_hp(hp: float, max_hp: float) -> void:
	hp_bar.set_values(hp, max_hp, "%d / %d" % [ceili(hp), ceili(max_hp)])


func set_room(_stage: int, room: int, total: int, wave_text: String) -> void:
	pips.total = total
	pips.current = room - 1
	pips.queue_redraw()
	wave_label.text = wave_text


func set_gold(g: int) -> void:
	gold_label.text = str(g)


func set_upgrades(upgrades: Dictionary) -> void:
	for c in upgrade_row.get_children():
		c.queue_free()
	for id in upgrades:
		var def := UpgradeDB.get_def(id)
		var col: Color = UpgradeDB.CATEGORY_COLORS[def["cat"]]
		var n: int = upgrades[id]
		upgrade_row.add_child(UiKit.chip(str(n) if n > 1 else "", col, def["icon"], 13))


func set_boss(enemy) -> void:
	var show: bool = enemy != null and is_instance_valid(enemy) and not enemy.dead
	boss_box.visible = show
	if show:
		boss_bar.set_values(enemy.hp, enemy.max_hp)
		boss_chip.visible = enemy.hp < enemy.max_hp * 0.5


func _process(_delta: float) -> void:
	_bars.queue_redraw()


func _draw_enemy_bars() -> void:
	if camera == null or not is_instance_valid(camera):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss or e.hp >= e.max_hp or not e.is_targetable():
			continue
		var world: Vector3 = e.global_position + Vector3(0, e.bar_height, 0)
		if camera.is_position_behind(world):
			continue
		var p := camera.unproject_position(world)
		var w := 46.0
		var r := Rect2(p - Vector2(w * 0.5, 0), Vector2(w, 6))
		_bars.draw_style_box(UiKit.box(Color(0, 0, 0, 0.55), 3, Color.TRANSPARENT, 0, 0), r.grow(1.5))
		_bars.draw_style_box(UiKit.box(Color("f43f5e"), 3, Color.TRANSPARENT, 0, 0), Rect2(r.position, Vector2(maxf(w * e.hp / e.max_hp, 4.0), 6)))
