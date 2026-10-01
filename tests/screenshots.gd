extends Node
## Renders reference screenshots (needs a display; use xvfb-run). Not part of CI tests.

var out_dir := OS.get_environment("SHOT_DIR")


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.save_path = "user://shot_profile.json"
	Profile.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for r in [Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY, Rarity.MYTHIC, Rarity.COMMON, Rarity.RARE]:
		Profile.add_item(LootGenerator.generate(rng, 3, r))
	Profile.equip(Profile.inventory[4].uid)
	for wid in ["sword", "tome", "crossbow"]:
		var w := LootGenerator.generate(rng, 3, Rarity.EPIC, "weapon")
		w.weapon_id = wid
		w.name = WeaponDB.get_def(wid)["item_names"][0]
		Profile.add_item(w)
	var main = load("res://scripts/main.gd").new()
	add_child(main)
	await get_tree().create_timer(0.8).timeout
	await shot("01_camp")
	main.menu._set_hover("fire")
	await get_tree().create_timer(0.4).timeout
	await shot("01b_camp_hover_fire")
	main.menu._set_hover("")
	var inv: InventoryScreen = main.menu.open_inventory()
	inv._select(Profile.inventory[Profile.inventory.size() - 2])
	await get_tree().create_timer(0.6).timeout
	await shot("01c_backpack")
	inv.close()
	await get_tree().create_timer(0.3).timeout
	# Hero close-up
	main.camp.camera.position = Vector3(-0.1, 1.6, 3.2)
	main.camp.camera.look_at(Vector3(-0.1, 1.1, 0.6))
	main.camp.set_process(false)
	main.menu.visible = false
	await get_tree().create_timer(0.3).timeout
	await shot("01d_wizard_closeup")
	main.menu.visible = true
	main.camp.set_process(true)

	var run: RunController = main.start_run(3)
	run.input_enabled = false
	await get_tree().create_timer(0.3).timeout
	await shot("02_upgrade_pick")
	# Staged shot: one of each enemy mid-windup around the player.
	run.upgrade_panel.pick(run.upgrade_panel.choices[0])
	for e in run.room.alive.duplicate():
		e.die()
	var pp := run.player.global_position + Vector3(0, 0, -7)
	run.player.global_position = pp
	run.player.stats.set_base("attack_range", 0.0)
	var g := run.room.spawn_enemy("grunt", pp + Vector3(-2.0, 0, -1.0))
	var s1 := run.room.spawn_enemy("spitter", pp + Vector3(9.0, 0, -4.5))
	var c := run.room.spawn_enemy("charger", pp + Vector3(-10.0, 0, -3.5))
	for i in 60 * 3:
		await get_tree().physics_frame
		if g.state == "windup" and s1.state == "aim" and c.state == "windup":
			break
	for i in 12:
		await get_tree().physics_frame
	await shot("03b_telegraphs_staged")
	run.player.stats.set_base("attack_range", 13.0)
	var bot := SimBot.new(run)
	var took_combat := false
	var took_boss := false
	for i in 60 * 400:
		bot.step()
		run.player.hp = run.player.max_hp
		await get_tree().physics_frame
		var tgs := run.room.ground.get_child_count()
		var near := run.room.alive.filter(func(e): return is_instance_valid(e) and e.is_targetable() and Flat.dist(e.global_position, run.player.global_position) < 11.0).size()
		if not took_combat and run.run.room_index >= 1 and tgs >= 2 and near >= 3:
			took_combat = true
			await shot("03_combat_telegraphs")
		if not took_boss and run.room.is_boss_room and run.room.boss and run.room.boss.enraged() and tgs >= 2:
			took_boss = true
			await shot("04_boss")
			break
	run._open_pause()
	await get_tree().create_timer(0.5, true, false, true).timeout
	await shot("05_pause")
	run._on_modal_action("settings")
	await get_tree().create_timer(0.5, true, false, true).timeout
	await shot("06_settings")
	get_tree().paused = false
	main.queue_free()
	await get_tree().create_timer(0.3).timeout
	# One staged scene per world
	for i in WorldDB.count():
		var w: Dictionary = WorldDB.WORLDS[i]
		var stage := Node3D.new()
		add_child(stage)
		WorldKit.setup(stage, w["ambient"], w["bg"], w["sun"])
		var room := Room.new()
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 3 + i
		room.build(rng2, 1.0, false, 1 + i, w)
		stage.add_child(room)
		var hero := Player.new()
		hero.setup(StatBuilder.build("wanderer", [], {}), "staff")
		hero.room = room
		hero.position = Vector3(room.bounds.size.x * 0.5, 0, room.bounds.size.y * 0.62)
		hero.stats.set_base("attack_range", 0.0)
		room.player = hero
		room.entities.add_child(hero)
		var ids := ["grunt", "spitter", "charger", "grunt"]
		for k in ids.size():
			var en := room.spawn_enemy(ids[k], hero.position + Vector3(-6 + k * 4, 0, -5 - (k % 2) * 2))
			en.speed = 0.0
		var cam := Camera3D.new()
		cam.fov = 44.0
		stage.add_child(cam)
		cam.position = hero.position + Vector3(0, 21, 9) + Vector3(0, 0, -3)
		cam.look_at(cam.position - Vector3(0, 21, 9))
		cam.current = true
		await get_tree().create_timer(1.6).timeout
		await shot("07_world_%d_%s" % [i + 1, w["id"]])
		stage.queue_free()
		await get_tree().create_timer(0.2).timeout
	# Journal with a few pages
	for id in ["ashen_woods:0", "ashen_woods:1", "ashen_woods:2", "frostfell:0"]:
		Profile.unlock_lore(id)
	var main2 = load("res://scripts/main.gd").new()
	add_child(main2)
	await get_tree().create_timer(0.8).timeout
	main2.menu._set_hover("journal")
	await get_tree().create_timer(0.4).timeout
	await shot("08_camp_journal_hover")
	main2.menu._set_hover("")
	var j: JournalScreen = main2.menu.open_journal()
	j._selected = 0
	j._refresh()
	await get_tree().create_timer(0.6).timeout
	await shot("09_journal")
	get_tree().quit()
