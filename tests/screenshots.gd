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
	var main = load("res://scripts/main.gd").new()
	add_child(main)
	main.hub._selected = Profile.inventory[5]
	main.hub.refresh()
	await get_tree().create_timer(0.3).timeout
	await shot("01_hub")

	var run: RunController = main.start_run(3)
	run.input_enabled = false
	await get_tree().create_timer(0.3).timeout
	await shot("02_upgrade_pick")
	# Staged shot: one of each enemy mid-windup around the player.
	run.upgrade_panel.pick(run.upgrade_panel.choices[0])
	for e in run.room.alive.duplicate():
		e.die()
	var pp := run.player.global_position + Vector2(0, -260)
	run.player.global_position = pp
	run.camera.position = pp
	run.player.stats.set_base("attack_range", 0.0)
	var g := run.room.spawn_enemy("grunt", pp + Vector2(-80, -40))
	var s1 := run.room.spawn_enemy("spitter", pp + Vector2(380, -180))
	var c := run.room.spawn_enemy("charger", pp + Vector2(-420, -160))
	for i in 60 * 3:
		await get_tree().physics_frame
		if g.state == "windup" and s1.state == "aim" and c.state == "windup":
			break
	for i in 12:
		await get_tree().physics_frame
	await shot("03b_telegraphs_staged")
	run.player.stats.set_base("attack_range", 520.0)
	var bot := SimBot.new(run)
	var took_combat := false
	var took_boss := false
	for i in 60 * 400:
		bot.step()
		run.player.hp = run.player.max_hp
		await get_tree().physics_frame
		var tgs := run.room.ground.get_child_count()
		var near := run.room.alive.filter(func(e): return is_instance_valid(e) and e.is_targetable() and e.global_position.distance_to(run.player.global_position) < 450.0).size()
		if not took_combat and run.run.room_index >= 1 and tgs >= 2 and near >= 3:
			took_combat = true
			await shot("03_combat_telegraphs")
		if not took_boss and run.room.is_boss_room and run.room.boss and run.room.boss.enraged() and tgs >= 2:
			took_boss = true
			await shot("04_boss")
			break
	get_tree().quit()
