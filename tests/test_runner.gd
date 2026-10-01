extends Node
## Headless tests. Run with:
##   godot --headless res://tests/test_runner.tscn
## Exits with code 0 on success, 1 on failure.

var _failures := 0
var _checks := 0


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("  FAIL: ", msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.save_path = "user://test_profile.json"
	for m in get_method_list():
		var n: String = m["name"]
		if n.begins_with("test_"):
			print("- ", n)
			var r = call(n)
			if r is Object and r.get_class() == "GDScriptFunctionState":
				await r
	print("%d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func test_stats_math() -> void:
	var s := Stats.new({"damage": 10.0})
	s.add_mod("damage", "flat", 5.0)
	s.add_mod("damage", "pct", 0.5)
	check(is_equal_approx(s.get_stat("damage"), 22.5), "(10+5)*1.5 = 22.5, got %s" % s.get_stat("damage"))
	s.add_mod("crit_chance", "flat", 5.0)
	check(s.get_stat("crit_chance") == 1.0, "crit clamps to 1")
	s.add_mod("dodge_cooldown", "pct", -5.0)
	check(s.get_stat("dodge_cooldown") >= 0.3, "dodge cooldown floor")


func test_rarity_roll_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 5000:
		counts[Rarity.roll(rng)] += 1
	check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3], "rarity weights descend %s" % [counts])
	for i in 200:
		check(Rarity.roll(rng, 0.0, Rarity.EPIC) >= Rarity.EPIC, "min rarity respected")


func test_loot_scaling() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var common := LootGenerator.generate(rng, 1, Rarity.COMMON, "helmet")
	var mythic := LootGenerator.generate(rng, 1, Rarity.MYTHIC, "helmet")
	check(common.mods.size() == 1 and common.specials.is_empty(), "common = implicit only")
	check(mythic.mods.size() == 4 and mythic.specials.size() == 2, "mythic has 3 affixes + 2 specials")
	check(mythic.mods[0]["value"] > common.mods[0]["value"] * 3.0, "mythic implicit much stronger")
	var w := LootGenerator.generate(rng, 5, Rarity.EPIC, "weapon")
	check(w.weapon_id != "" and w.describe_lines().size() >= 4, "weapon has id and descriptions")
	var round_trip := GearItem.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	check(round_trip.uid == w.uid and round_trip.rarity == w.rarity and round_trip.specials.size() == 1, "item json round trip")


func test_upgrade_rolls_and_stacking() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var taken := {}
	for i in 30:
		var choices := UpgradeDB.roll_choices(rng, taken)
		check(choices.size() == 3, "3 choices offered")
		var unique := {}
		for c in choices:
			unique[c] = true
			check(taken.get(c, 0) < UpgradeDB.get_def(c)["max"], "never offers maxed upgrade")
		check(unique.size() == 3, "choices distinct")
		taken[choices[0]] = taken.get(choices[0], 0) + 1
	var base := StatBuilder.build("wanderer", [], {})
	var buffed := StatBuilder.build("wanderer", [], {"power": 2, "multishot": 1})
	check(is_equal_approx(buffed.get_stat("damage"), base.get_stat("damage") * 1.3), "stacked +20%x2 -10% = x1.3")
	check(buffed.geti("multishot") == 1, "multishot stacks")


func test_profile_save_load() -> void:
	Profile.reset()
	check(Profile.get_equipped("weapon") != null, "starter bow equipped")
	var rng := RandomNumberGenerator.new()
	var ring := LootGenerator.generate(rng, 3, Rarity.LEGENDARY, "ring")
	Profile.add_item(ring)
	Profile.equip(ring.uid)
	Profile.gold = 123
	Profile.save_profile()
	Profile.reset()
	check(Profile.gold == 0, "reset clears")
	Profile.load_profile()
	check(Profile.gold == 123, "gold persisted")
	check(Profile.get_equipped("ring") != null and Profile.get_equipped("ring").uid == ring.uid, "equipped ring persisted")
	var stats := Profile.build_stats()
	check(stats.get_stat("crit_chance") > 0.05, "gear feeds into stats")
	var junk := LootGenerator.generate(rng, 1, Rarity.COMMON, "boots")
	Profile.add_item(junk)
	var n := Profile.inventory.size()
	check(Profile.salvage(junk.uid) > 0 and Profile.inventory.size() == n - 1, "salvage gives gold and removes")
	check(Profile.salvage(ring.uid) == 0, "cannot salvage equipped")


func test_run_progression() -> void:
	var run := RunState.new(1)
	var last := -1.0
	for i in RunState.ROOMS_PER_STAGE * 2:
		check(run.difficulty() > last, "difficulty rises")
		last = run.difficulty()
		run.advance_room()
	check(run.stage == 3 and run.room_index == 0, "stages advance after 5 rooms")


# ---------------------------------------------------------------- Combat tests

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func test_telegraph_shapes() -> void:
	var c := Telegraph.circle(Vector3(10, 0, 10), 2.0, 1.0)
	add_child(c)
	check(c.contains(Vector3(11.5, 0, 10)), "inside circle")
	check(not c.contains(Vector3(12.5, 0, 10)), "outside circle")
	check(c.contains(Vector3(12.5, 0, 10), 0.6), "circle overlap with target radius")
	var l := Telegraph.lane(Vector3.ZERO, Vector3(1, 0, 0), 8.0, 1.0, 1.0)
	add_child(l)
	check(l.contains(Vector3(6, 0, 0.3)), "inside lane")
	check(not l.contains(Vector3(6, 0, 1.2)), "beside lane")
	check(not l.contains(Vector3(-1.5, 0, 0)), "behind lane")
	var a := Telegraph.arc(Vector3.ZERO, Vector3(0, 0, -1), 3.0, 0.5, 1.0)
	add_child(a)
	check(a.contains(Vector3(0.3, 0, -2.5)), "inside arc")
	check(not a.contains(Vector3(0, 0, 2.5)), "behind arc")
	for t in [c, l, a]:
		t.queue_free()


func _make_arena() -> Array:
	var room := Room.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	room.build(rng, 0.0, false, 0)
	add_child(room)
	var p := Player.new()
	p.setup(StatBuilder.build("wanderer", [], {}), "bow")
	p.room = room
	p.position = Vector3(10, 0, 10)
	room.player = p
	room.entities.add_child(p)
	return [room, p]


func test_dodge_iframes_and_cooldown() -> void:
	var arena := _make_arena()
	var room: Room = arena[0]
	var p: Player = arena[1]
	var hp0 := p.hp
	p.move_input = Vector2.RIGHT
	check(p.try_dodge(), "dodge works when ready")
	check(not p.try_dodge(), "dodge blocked by cooldown")
	p.take_damage(30)
	check(p.hp == hp0, "i-frames negate damage")
	check(p.forced_crits == Player.PERFECT_CRITS, "perfect dodge grants empowered shots")
	await _frames(45)
	check(p.global_position.x > 10 + p.stats.get_stat("dodge_distance") * 0.8, "dash moved player (x=%s)" % p.global_position.x)
	await _frames(30)
	p.take_damage(30)
	check(p.hp < hp0, "damage applies after i-frames")
	var hp1 := p.hp
	p.take_damage(30)
	check(p.hp == hp1, "hurt grace prevents instant double hit")
	await _frames(int(60 * p.stats.get_stat("dodge_cooldown")) + 5)
	check(p.dodge_ready(), "dodge recharges")
	Engine.time_scale = 1.0
	room.queue_free()


func test_enemy_damage_procs_and_death() -> void:
	var arena := _make_arena()
	var room: Room = arena[0]
	var p: Player = arena[1]
	p.stats.set_base("attack_range", 0.0)
	var e := room.spawn_enemy("grunt", Vector3(18, 0, 10))
	var died := [false]
	e.died.connect(func(_e): died[0] = true)
	check(not e.is_targetable(), "enemy untargetable while spawning in")
	await _frames(60)
	check(e.is_targetable(), "enemy active after spawn-in")
	p.stats.add_mod("poison_dps", "flat", 10.0)
	p.stats.add_mod("lifesteal", "flat", 0.5)
	p.hp = 50.0
	Combat.player_hits_enemy(p, e, 5.0, false, true)
	check(e.poison_left > 0.0, "poison applied")
	check(p.hp > 50.0, "lifesteal heals")
	var hp_before := e.hp
	await _frames(70)
	check(e.hp < hp_before, "poison ticks")
	Combat.player_hits_enemy(p, e, 9999.0, true, false)
	check(died[0] and not room.alive.has(e), "enemy dies and leaves room roster")
	room.queue_free()


func test_auto_attack_kills_enemy() -> void:
	var arena := _make_arena()
	var room: Room = arena[0]
	var e := room.spawn_enemy("spitter", Vector3(10, 0, 3))
	e.speed = 0.0
	await _frames(240)
	check(not is_instance_valid(e) or e.dead, "auto-attack killed a stationary enemy in 4s")
	room.queue_free()


func test_pathfinding_routes_around_obstacles() -> void:
	var room := Room.new()
	var rng := RandomNumberGenerator.new()
	room.build(rng, 0.0, false, 0)
	room.obstacles = [Rect2(10, 5, 2, 10)]
	room._build_nav()
	add_child(room)
	var from := Vector2(6, 10)
	var to := Vector2(16, 10)
	check(room.segment_blocked(from, to), "wall blocks direct line")
	var wp := room.next_waypoint(from, to, 0.5)
	check(not room.segment_blocked(from, wp, 0.4) and wp != to, "waypoint is a reachable detour")
	room.queue_free()


func _sim_run(seed_value: int, god: bool, max_seconds: float) -> Dictionary:
	var main = load("res://scripts/main.gd").new()
	add_child(main)
	var run: RunController = main.start_run(seed_value)
	run.input_enabled = false
	var bot := SimBot.new(run)
	var frames := int(max_seconds * 60)
	var max_room := 0
	var died := false
	for i in frames:
		if god:
			run.player.hp = run.player.max_hp
		bot.step()
		await get_tree().physics_frame
		if not is_instance_valid(run) or run.player.dead:
			died = true
			break
		max_room = maxi(max_room, (run.run.stage - 1) * RunState.ROOMS_PER_STAGE + run.run.room_index)
		if run.run.stage >= 2:
			break
	var result := {"died": died, "progress": max_room, "stage": run.run.stage, "upgrades": run.run.upgrades.duplicate(),
		"dodges": bot.dodges, "perfect": bot.perfect, "damage_taken": roundi(bot.damage_taken),
		"loot": run.run.loot.size(), "kills": run.run.kills, "gold": run.run.gold, "seconds": snappedf(frames / 60.0, 0.1)}
	get_tree().paused = false
	Engine.time_scale = 1.0
	main.queue_free()
	await get_tree().physics_frame
	return result


func test_full_run_flow_reaches_stage_2() -> void:
	var r = await _sim_run(11, true, 600.0)
	print("    god-bot run: ", r)
	check(r["stage"] >= 2, "bot clears 4 rooms + boss and enters stage 2")
	check(r["loot"] >= 2, "boss dropped and bot collected loot")
	check(r["kills"] > 10, "enemies were killed")


func test_balance_probe() -> void:
	# Informational: how far does a simple bot get without cheats?
	for s in [1, 2, 3]:
		var r = await _sim_run(s, false, 400.0)
		print("    fair-bot seed %d: reached room %d, died=%s, dmg_taken=%d, dodges=%d (perfect %d), kills=%d" % [s, r["progress"] + 1, r["died"], r["damage_taken"], r["dodges"], r["perfect"], r["kills"]])
	check(true, "probe")
