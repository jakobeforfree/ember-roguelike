class_name Hud
extends Control
## In-run HUD: health, room/stage, gold, boss bar, messages and the touch controls.

signal pause_pressed

var joystick: VirtualJoystick
var dodge: DodgeButton
var hp_bar: Bar
var boss_bar: Bar
var boss_label: Label
var room_label: Label
var gold_label: Label
var message: Label
var _msg_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	joystick = VirtualJoystick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_right = 0.5
	joystick.anchor_top = 0.18
	joystick.anchor_bottom = 1.0
	add_child(joystick)

	dodge = DodgeButton.new()
	dodge.anchor_left = 1.0
	dodge.anchor_right = 1.0
	dodge.anchor_top = 1.0
	dodge.anchor_bottom = 1.0
	dodge.offset_left = -250
	dodge.offset_top = -250
	dodge.offset_right = -60
	dodge.offset_bottom = -60
	add_child(dodge)

	hp_bar = Bar.new()
	hp_bar.position = Vector2(110, 22)
	hp_bar.size = Vector2(320, 34)
	add_child(hp_bar)

	var pause := UiKit.button("II", 26, Color("3a3340"), Vector2(70, 60))
	pause.position = Vector2(24, 16)
	pause.pressed.connect(func(): pause_pressed.emit())
	add_child(pause)

	room_label = UiKit.label("", 24)
	room_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.offset_left = -250
	room_label.offset_right = 250
	room_label.offset_top = 18
	add_child(room_label)

	gold_label = UiKit.label("", 26, Color("ffd166"))
	gold_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.offset_left = -260
	gold_label.offset_right = -30
	gold_label.offset_top = 20
	add_child(gold_label)

	boss_bar = Bar.new()
	boss_bar.anchor_left = 0.25
	boss_bar.anchor_right = 0.75
	boss_bar.offset_top = 86
	boss_bar.offset_bottom = 110
	boss_bar.fill = Color("ff7a2f")
	boss_bar.visible = false
	add_child(boss_bar)
	boss_label = UiKit.label("CINDER GOLEM", 20, Color("ffb347"))
	boss_label.anchor_left = 0.25
	boss_label.anchor_right = 0.75
	boss_label.offset_top = 56
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.visible = false
	add_child(boss_label)

	message = UiKit.label("", 44, Color("ffe8c2"))
	message.set_anchors_preset(Control.PRESET_CENTER)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.offset_left = -400
	message.offset_right = 400
	message.offset_top = -160
	message.offset_bottom = -100
	add_child(message)


func show_message(text: String, time: float = 1.6) -> void:
	message.text = text
	message.modulate.a = 1.0
	_msg_time = time


func set_hp(hp: float, max_hp: float) -> void:
	hp_bar.set_values(hp, max_hp, "%d / %d" % [ceili(hp), ceili(max_hp)])


func set_room(stage: int, room: int, total: int, wave_text: String) -> void:
	room_label.text = "Stage %d  ·  Room %d/%d%s" % [stage, room, total, wave_text]


func set_gold(g: int) -> void:
	gold_label.text = "%d gold" % g


func set_boss(enemy) -> void:
	boss_bar.visible = enemy != null and is_instance_valid(enemy) and not enemy.dead
	boss_label.visible = boss_bar.visible
	if boss_bar.visible:
		boss_bar.set_values(enemy.hp, enemy.max_hp, "ENRAGED" if enemy.hp < enemy.max_hp * 0.5 else "")


func _process(delta: float) -> void:
	if _msg_time > 0.0:
		_msg_time -= delta
		message.modulate.a = clampf(_msg_time / 0.4, 0.0, 1.0)
