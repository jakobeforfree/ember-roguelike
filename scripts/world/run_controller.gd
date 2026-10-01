class_name RunController
extends Node2D
## Owns a single run: builds rooms, moves the player between them, offers upgrades,
## drops loot, and reports the result. Death discards the run but loot stays banked.

signal run_finished

const CAMERA_ZOOM := 0.9
const ROOM_LOOT_CHANCE := 0.35

var run: RunState
var room: Room
var player: Player
var camera: Camera2D
var ui: CanvasLayer
var hud: Hud
var upgrade_panel: UpgradePanel
var modal: MessagePanel
var _ending := false
var input_enabled := true   # false = something else (tests, replays, autoplay) drives the player


func start(seed_value: int = -1) -> void:
	run = RunState.new(seed_value)
	run.character_id = Profile.character_id
	Engine.time_scale = 1.0

	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	add_child(camera)

	ui = CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	hud.dodge.pressed.connect(_on_dodge_pressed)
	hud.pause_pressed.connect(_open_pause)
	upgrade_panel = UpgradePanel.new()
	upgrade_panel.visible = false
	upgrade_panel.chosen.connect(_on_upgrade_chosen)
	ui.add_child(upgrade_panel)
	modal = MessagePanel.new()
	modal.visible = false
	modal.action.connect(_on_modal_action)
	ui.add_child(modal)

	player = Player.new()
	player.setup(_build_stats(), StatBuilder.weapon_id_for(run.character_id, Profile.equipped_items()))
	player.hp_changed.connect(hud.set_hp)
	player.died.connect(_on_player_died)
	player.dodged.connect(func(perfect): if perfect: hud.dodge.flash_perfect())
	hud.set_hp(player.hp, player.max_hp)
	_load_room()
	# Every run starts with one free pick so builds diverge immediately.
	_offer_upgrade("Choose a Starting Boon")


func _build_stats() -> Stats:
	return StatBuilder.build(run.character_id, Profile.equipped_items(), run.upgrades)


func _load_room() -> void:
	if room:
		if player.get_parent():
			player.get_parent().remove_child(player)
		room.queue_free()
	room = Room.new()
	room.name = "Room"
	room.player = player
	room.build(run.rng, run.difficulty(), run.is_boss_room(), run.room_index)
	add_child(room)
	move_child(room, 0)
	player.room = room
	player.position = room.player_spawn()
	player.velocity = Vector2.ZERO
	room.entities.add_child(player)
	room.cleared.connect(_on_room_cleared)
	room.exit_reached.connect(_on_exit_reached)
	camera.position = player.position
	camera.reset_smoothing()
	_update_room_label()
	if run.is_boss_room():
		hud.show_message("BOSS: CINDER GOLEM", 2.0)
	else:
		hud.show_message("Room %d" % (run.room_index + 1), 1.0)


func _start_room_combat() -> void:
	room.start()
	if room.boss:
		hud.set_boss(room.boss)


func _update_room_label() -> void:
	var wave_text := ""
	if room and not room.is_boss_room and room.waves.size() > 0 and not room.is_cleared():
		wave_text = "  ·  Wave %d/%d" % [clampi(room.wave_index + 1, 1, room.waves.size()), room.waves.size()]
	hud.set_room(run.stage, run.room_index + 1, RunState.ROOMS_PER_STAGE, wave_text)
	hud.set_gold(run.gold)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	if input_enabled:
		player.move_input = _read_move_input()
	hud.dodge.cooldown_ratio = player.dodge_cooldown_ratio()
	if room and room.boss and is_instance_valid(room.boss):
		hud.set_boss(room.boss)
	_update_camera()
	_update_room_label()


func _read_move_input() -> Vector2:
	var v := hud.joystick.output
	var k := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if k != Vector2.ZERO:
		v = k.normalized()
	return v


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_SHIFT, KEY_K]:
			_on_dodge_pressed()
		elif event.physical_keycode == KEY_ESCAPE:
			_open_pause()


func _update_camera() -> void:
	var view := get_viewport_rect().size / camera.zoom
	var target := player.global_position
	var b := room.bounds.grow(60.0)
	for axis in 2:
		if b.size[axis] <= view[axis]:
			target[axis] = b.get_center()[axis]
		else:
			target[axis] = clampf(target[axis], b.position[axis] + view[axis] * 0.5, b.end[axis] - view[axis] * 0.5)
	camera.position = camera.position.lerp(target, 0.15)


func _on_dodge_pressed() -> void:
	if player and not get_tree().paused:
		player.try_dodge()


# --- Room flow -------------------------------------------------------------

func _on_room_cleared() -> void:
	if player.dead:
		return
	var heal := player.stats.get_stat("heal_on_clear")
	if heal > 0.0:
		player.heal(player.max_hp * heal)
	_drop_loot()
	if run.is_boss_room():
		hud.set_boss(null)
		hud.show_message("STAGE %d CLEARED!" % run.stage, 2.5)
	else:
		hud.show_message("ROOM CLEARED", 1.2)
	get_tree().create_timer(0.9, false).timeout.connect(func():
		if not player.dead:
			_offer_upgrade())


func _drop_loot() -> void:
	var luck := 0.15 * (run.stage - 1)
	var drops := []
	if run.is_boss_room():
		drops.append(LootGenerator.generate(run.rng, run.item_level(), Rarity.roll(run.rng, luck + 0.5, Rarity.RARE)))
		drops.append(LootGenerator.generate(run.rng, run.item_level(), Rarity.roll(run.rng, luck)))
	elif run.rng.randf() < ROOM_LOOT_CHANCE:
		drops.append(LootGenerator.generate(run.rng, run.item_level(), Rarity.roll(run.rng, luck)))
	var center := Vector2(room.bounds.size.x * 0.5, room.bounds.size.y * 0.5)
	for i in drops.size():
		var pickup := LootPickup.new()
		pickup.item = drops[i]
		pickup.player = player
		pickup.position = center + Vector2((i - (drops.size() - 1) * 0.5) * 90.0, 0)
		while room.is_blocked(pickup.position, 30.0):
			pickup.position.y += 40.0
		pickup.collected.connect(_on_loot_collected)
		room.entities.add_child(pickup)


func _on_loot_collected(item: GearItem) -> void:
	run.loot.append(item)
	Profile.add_item(item)
	Profile.save_profile()  # banked immediately: survives death and app kills
	Events.loot_found.emit(item)


func _offer_upgrade(title: String = "Choose an Upgrade") -> void:
	var choices := UpgradeDB.roll_choices(run.rng, run.upgrades)
	if choices.is_empty():
		_after_upgrade()
		return
	get_tree().paused = true
	upgrade_panel.open(choices, run.upgrades, title)


func _on_upgrade_chosen(id: String) -> void:
	get_tree().paused = false
	apply_upgrade(id)
	_after_upgrade()


## Public so tests (and later: shrines, events) can grant upgrades directly.
func apply_upgrade(id: String) -> void:
	run.add_upgrade(id)
	player.refresh_stats(_build_stats())
	var heal: float = UpgradeDB.get_def(id).get("heal", 0.0)
	if heal > 0.0:
		player.heal(player.max_hp * heal)


func _after_upgrade() -> void:
	if room.is_cleared():
		room.open_door()
		hud.show_message("Door open ▲", 1.2)
	else:
		_start_room_combat()


func _on_exit_reached() -> void:
	run.advance_room()
	_load_room()
	_start_room_combat()


func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(id: String, _pos: Vector2) -> void:
	run.kills += 1
	var base: int = EnemyDB.get_def(id)["gold"]
	run.gold += int(ceil(base * (1.0 + 0.2 * (run.stage - 1)) * (1.0 + player.stats.get_stat("gold_find"))))


# --- End of run ------------------------------------------------------------

func _on_player_died() -> void:
	hud.show_message("YOU FELL", 2.0)
	get_tree().create_timer(1.2, false).timeout.connect(_show_game_over)


func _show_game_over() -> void:
	_finish_run()
	var lines := PackedStringArray([
		"Reached Stage %d, Room %d" % [run.stage, run.room_index + 1],
		"Enemies defeated: %d" % run.kills,
		"Gold earned: %d" % run.gold,
	])
	_append_loot_lines(lines)
	get_tree().paused = true
	modal.open("DEFEATED", Color("ff5a5a"), lines, [["camp", "Return to Camp"]])


func _append_loot_lines(lines: PackedStringArray) -> void:
	if run.loot.is_empty():
		lines.append("No gear found this run")
		return
	lines.append("Gear kept:")
	for it in run.loot:
		lines.append("#%s|%s" % [Rarity.color_of(it.rarity).to_html(false), it.display_name()])


func _open_pause() -> void:
	if get_tree().paused or player.dead:
		return
	get_tree().paused = true
	var lines := PackedStringArray(["Stage %d · Room %d" % [run.stage, run.room_index + 1], "Upgrades:"])
	var ups := []
	for id in run.upgrades:
		ups.append("%s x%d" % [UpgradeDB.get_def(id)["name"], run.upgrades[id]])
	lines.append(", ".join(ups) if ups.size() > 0 else "none yet")
	modal.open("PAUSED", UiKit.ACCENT, lines, [["resume", "Resume"], ["retreat", "Retreat to Camp (keep loot & gold)", Color("6b5a73")]])


func _finish_run() -> void:
	if _ending:
		return
	_ending = true
	Engine.time_scale = 1.0
	Profile.record_run(run)


func _on_modal_action(id: String) -> void:
	match id:
		"resume":
			modal.visible = false
			get_tree().paused = false
		"retreat":
			_finish_run()
			_exit_to_camp()
		"camp":
			_exit_to_camp()


func _exit_to_camp() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	run_finished.emit()
