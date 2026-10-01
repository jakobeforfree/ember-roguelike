class_name RunController
extends Node3D
## Owns a single run: builds rooms, moves the player between them, offers upgrades,
## drops loot, and reports the result. Death discards the run but loot stays banked.

signal run_finished

const ROOM_LOOT_CHANCE := 0.35
const CAM_OFFSET := Vector3(0, 21.0, 9.0)    # tilted top-down view (~67 degrees)
const CAM_FOV := 44.0

var run: RunState
var room: Room
var player: Player
var camera: Camera3D
var ui: CanvasLayer
var hud: Hud
var upgrade_panel: UpgradePanel
var modal: MessagePanel
var input_enabled := true   # false = something else (tests, replays, autoplay) drives the player
var _ending := false
var _trauma := 0.0
var _ui_root: Control
var _env: Node3D
var _env_world := ""


func start(seed_value: int = -1) -> void:
	run = RunState.new(seed_value)
	run.character_id = Profile.character_id
	Engine.time_scale = 1.0

	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.current = true
	add_child(camera)

	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.theme()
	ui.add_child(root)
	_ui_root = root
	hud = Hud.new()
	hud.camera = camera
	root.add_child(hud)
	hud.dodge.pressed.connect(_on_dodge_pressed)
	hud.burst.pressed.connect(_on_ability_pressed)
	hud.pause_pressed.connect(_open_pause)
	upgrade_panel = UpgradePanel.new()
	upgrade_panel.visible = false
	upgrade_panel.chosen.connect(_on_upgrade_chosen)
	root.add_child(upgrade_panel)
	modal = MessagePanel.new()
	modal.visible = false
	modal.action.connect(_on_modal_action)
	root.add_child(modal)

	player = Player.new()
	player.setup(_build_stats(), StatBuilder.weapon_id_for(run.character_id, Profile.equipped_items()))
	player.hp_changed.connect(hud.set_hp)
	player.died.connect(_on_player_died)
	player.dodged.connect(func(perfect): if perfect: hud.flash_perfect())
	hud.set_hp(player.hp, player.max_hp)
	_load_room()
	# Every run starts with one free pick so builds diverge immediately.
	_offer_upgrade("Choose a Starting Boon", "Your first blessing for this descent")


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
	var world := run.world()
	_apply_world_env(world)
	room.build(run.rng, run.difficulty(), run.is_boss_room(), run.room_index, world)
	add_child(room)
	player.room = room
	player.position = room.player_spawn()
	player.velocity = Vector3.ZERO
	player.facing = Vector3.FORWARD
	room.entities.add_child(player)
	room.cleared.connect(_on_room_cleared)
	room.exit_reached.connect(_on_exit_reached)
	_update_camera(1.0)
	_update_room_label()
	hud.set_world(world, run.ascension())
	if run.is_boss_room():
		hud.show_message(world["boss"]["name"], 2.0, "Guardian of %s" % world["name"], Color(world["boss"]["color"]).lightened(0.3))
	elif run.room_index == 0:
		var asc := run.ascension()
		hud.show_message(String(world["name"]).to_upper(), 2.6, ("Ascension %d · " % asc if asc > 0 else "") + world["tagline"], Color(world["color"]).lightened(0.25))
		_unlock_page(world["id"], 0)
	else:
		hud.show_message("ROOM %d" % (run.room_index + 1), 1.0, world["name"])


## Lighting, fog and sun color follow the world; rebuilt only when the world changes.
func _apply_world_env(world: Dictionary) -> void:
	if _env and _env_world == world["id"]:
		return
	if _env:
		_env.queue_free()
	_env = Node3D.new()
	_env.name = "Environment"
	add_child(_env)
	WorldKit.setup(_env, world["ambient"], world["bg"], world["sun"])
	_env_world = world["id"]


func _unlock_page(world_id: String, page: int) -> void:
	var id := WorldDB.page_id(world_id, page)
	if Profile.unlock_lore(id):
		hud.notify("menu_book", "JOURNAL PAGE FOUND", WorldDB.page(world_id, page)[0], Color("ffcf7a"))


func _start_room_combat() -> void:
	room.start()
	if room.boss:
		hud.set_boss(room.boss)


func _update_room_label() -> void:
	var wave_text := ""
	if room and room.is_boss_room and not room.is_cleared():
		wave_text = "BOSS"
	elif room and room.waves.size() > 0 and not room.is_cleared():
		wave_text = "WAVE %d / %d" % [clampi(room.wave_index + 1, 1, room.waves.size()), room.waves.size()]
	elif room and room.is_cleared():
		wave_text = "CLEARED"
	hud.set_room(run.stage, run.room_index + 1, RunState.ROOMS_PER_STAGE, wave_text)
	hud.set_gold(run.gold)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if input_enabled:
		player.move_input = _read_move_input()
		player.aim_dir = Vector3.ZERO if Controls.touch_mode else _mouse_aim()
	hud.set_dodge_cooldown(player.dodge_cooldown_ratio(), player.dodge_cd_left)
	hud.set_ability_cooldown(player.ability_cooldown_ratio(), player.ability_cd_left)
	_trauma = maxf(0.0, _trauma - delta * 1.8)
	if room and room.boss and is_instance_valid(room.boss):
		hud.set_boss(room.boss)
	_update_camera(0.12)
	_update_room_label()


func _read_move_input() -> Vector2:
	if hud.joystick.is_active():
		return hud.joystick.output
	return Controls.move_vector()


## Ground-plane direction from the player to the mouse cursor.
func _mouse_aim() -> Vector3:
	var mp := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mp)
	var dir := camera.project_ray_normal(mp)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var hit := from + dir * (-from.y / dir.y)
	var v := hit - player.global_position
	v.y = 0.0
	return v.normalized() if v.length() > 0.5 else Vector3.ZERO


func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge"):
		_on_dodge_pressed()
	elif event.is_action_pressed("ability"):
		_on_ability_pressed()
	elif event.is_action_pressed("pause"):
		_open_pause()


## Follows the player, kept inside the arena so walls frame the view.
func _update_camera(weight: float) -> void:
	var b := room.bounds
	var target := Flat.xz(player.global_position)
	var margin := Vector2(9.0, 6.0)
	for axis in 2:
		var lo := b.position[axis] + margin[axis]
		var hi := b.end[axis] - margin[axis] * (0.6 if axis == 1 else 1.0)
		target[axis] = b.get_center()[axis] if lo > hi else clampf(target[axis], lo, hi)
	var desired := Flat.v3(target) + CAM_OFFSET
	camera.position = camera.position.lerp(desired, weight)
	camera.look_at(camera.position - CAM_OFFSET, Vector3.UP)
	if _trauma > 0.0 and Settings.screen_shake:
		var k := _trauma * _trauma * 0.45
		camera.h_offset = randf_range(-1.0, 1.0) * k
		camera.v_offset = randf_range(-1.0, 1.0) * k
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func _on_ability_pressed() -> void:
	if player and not get_tree().paused:
		player.try_ability()


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
	var world := run.world()
	if run.is_boss_room():
		hud.set_boss(null)
		hud.show_message("%s FREED" % String(world["boss"]["name"]), 2.5, "The guardian of %s is at rest" % world["name"], UiKit.GOLD)
		_unlock_page(world["id"], 2)
	elif not Profile.has_lore(WorldDB.page_id(world["id"], 1)) and run.rng.randf() < 0.35:
		_drop_page(WorldDB.page_id(world["id"], 1))
	else:
		hud.show_message("CLEARED", 1.2, "", UiKit.TEAL)
	get_tree().create_timer(1.0, false).timeout.connect(func():
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
	var center := room.bounds.get_center()
	for i in drops.size():
		var pickup := LootPickup.new()
		pickup.item = drops[i]
		pickup.player = player
		var p := center + Vector2((i - (drops.size() - 1) * 0.5) * 2.2, 0)
		while room.is_blocked(p, 0.8):
			p.y += 1.0
		pickup.position = Flat.v3(p)
		pickup.collected.connect(_on_loot_collected)
		room.entities.add_child(pickup)


func _drop_page(id: String) -> void:
	var p := LorePickup.new()
	p.page_id = id
	p.player = player
	var pos := room.bounds.get_center() + Vector2(0, 2.5)
	while room.is_blocked(pos, 0.8):
		pos.y += 1.0
	p.position = Flat.v3(pos)
	p.collected.connect(func(pid):
		var parts: PackedStringArray = pid.split(":")
		_unlock_page(parts[0], int(parts[1])))
	room.entities.add_child(p)


func _on_loot_collected(item: GearItem) -> void:
	run.loot.append(item)
	Profile.add_item(item)
	Profile.save_profile()  # banked immediately: survives death and app kills
	Events.loot_found.emit(item)


func _offer_upgrade(title: String = "Choose a Boon", subtitle: String = "") -> void:
	var choices := UpgradeDB.roll_choices(run.rng, run.upgrades)
	if choices.is_empty():
		_after_upgrade()
		return
	if subtitle == "":
		subtitle = "Stage %d · Room %d of %d" % [run.stage, run.room_index + 1, RunState.ROOMS_PER_STAGE]
	get_tree().paused = true
	hud.hide_message()
	upgrade_panel.open(choices, run.upgrades, title, subtitle)


func _on_upgrade_chosen(id: String) -> void:
	get_tree().paused = false
	apply_upgrade(id)
	_after_upgrade()


## Public so tests (and later: shrines, events) can grant upgrades directly.
func apply_upgrade(id: String) -> void:
	run.add_upgrade(id)
	player.refresh_stats(_build_stats())
	hud.set_upgrades(run.upgrades)
	var heal: float = UpgradeDB.get_def(id).get("heal", 0.0)
	if heal > 0.0:
		player.heal(player.max_hp * heal)


func _after_upgrade() -> void:
	if room.is_cleared():
		room.open_door()
		hud.show_message("GATE OPEN", 1.2, "Head north to continue", UiKit.ACCENT)
	else:
		_start_room_combat()


func _on_exit_reached() -> void:
	run.advance_room()
	_load_room()
	_start_room_combat()


func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.screen_shake.connect(shake)
	Events.player_damaged.connect(func(_a): shake(0.45))


func _on_enemy_killed(id: String, _pos: Vector3) -> void:
	if run == null or player == null:
		return
	run.kills += 1
	var base: int = EnemyDB.get_def(id)["gold"]
	run.gold += int(ceil(base * (1.0 + 0.2 * (run.stage - 1)) * (1.0 + player.stats.get_stat("gold_find"))))


# --- End of run ------------------------------------------------------------

func _on_player_died() -> void:
	hud.show_message("YOU FELL", 2.0, "", UiKit.DANGER)
	get_tree().create_timer(1.4, false).timeout.connect(_show_game_over)


func _show_game_over() -> void:
	_finish_run()
	var lines := [
		"Reached Stage %d · Room %d" % [run.stage, run.room_index + 1],
		"%d enemies defeated · %d gold earned" % [run.kills, run.gold],
	]
	_append_loot_lines(lines)
	get_tree().paused = true
	modal.open("DEFEATED", UiKit.DANGER, "dangerous", lines, [["camp", "Return to Camp", "primary", "home"]])


func _append_loot_lines(lines: Array) -> void:
	if run.loot.is_empty():
		lines.append("No gear found this run")
		return
	lines.append("Gear kept:")
	for it in run.loot:
		lines.append([it.display_name(), Rarity.color_of(it.rarity)])


func _open_pause() -> void:
	if get_tree().paused or player.dead:
		return
	get_tree().paused = true
	var ups := []
	for id in run.upgrades:
		ups.append("%s ×%d" % [UpgradeDB.get_def(id)["name"], run.upgrades[id]])
	var lines := ["Stage %d · Room %d" % [run.stage, run.room_index + 1], ", ".join(ups) if ups.size() > 0 else "No boons yet"]
	modal.open("PAUSED", UiKit.ACCENT, "pause", lines, [["resume", "Resume", "primary", "play_arrow"], ["settings", "Settings", "secondary", "settings"], ["retreat", "Retreat to Camp", "secondary", "home"]])


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
		"settings":
			modal.add_child(SettingsPanel.new())
		"retreat":
			_finish_run()
			_exit_to_camp()
		"camp":
			_exit_to_camp()


func _exit_to_camp() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	run_finished.emit()
