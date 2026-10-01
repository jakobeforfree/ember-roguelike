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
	Settings.path = "user://test_settings.cfg"
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


func test_every_weapon_kills() -> void:
	for wid in WeaponDB.ids():
		var room := Room.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		room.build(rng, 0.0, false, 0)
		add_child(room)
		var stats := StatBuilder.build("wanderer", [], {})
		for k in WeaponDB.get_def(wid)["base"]:
			stats.set_base(k, WeaponDB.get_def(wid)["base"][k])
		var p := Player.new()
		p.setup(stats, wid)
		p.room = room
		p.position = Vector3(10, 0, 10)
		room.player = p
		room.entities.add_child(p)
		var reach: float = minf(stats.get_stat("attack_range") - 1.0, 6.0)
		var a := room.spawn_enemy("grunt", Vector3(10, 0, 10 - reach))
		var b := room.spawn_enemy("grunt", Vector3(10.8, 0, 10 - reach))
		for e in [a, b]:
			e.speed = 0.0
			e.damage = 0.0
		await _frames(60 * 8)
		var dead := 0
		for e in [a, b]:
			if not is_instance_valid(e) or e.dead:
				dead += 1
		check(dead == 2, "%s killed both grunts in 8s (%d/2)" % [wid, dead])
		check(p.model.get_node_or_null("Body/Hand/Weapon") != null, "%s model in hand" % wid)
		room.queue_free()
		await _frames(2)


func test_camp_menu_flow() -> void:
	var main = load("res://scripts/main.gd").new()
	add_child(main)
	await _frames(5)
	var menu: CampMenu = main.menu
	check(main.camp != null and main.run == null, "game opens at camp")
	var inv := menu.open_inventory()
	await _frames(5)
	check(menu._modal_open(), "backpack opens")
	inv.close()
	await _frames(5)
	check(not menu._modal_open(), "backpack closes")
	var circle: Array = main.camp.screen_circle("fire")
	check(circle[1] > 10.0, "campfire is on screen with a clickable radius")
	menu.activate("fire")
	await get_tree().create_timer(0.8).timeout
	check(main.run != null and main.camp == null, "clicking the fire starts a run")
	get_tree().paused = false
	main.queue_free()
	await _frames(2)


## Walks from every open spot in every layout to the gate the way enemies do
## (re-pathing every 0.25s). Guards against corner flip-flops and dead ends.
func test_every_layout_is_navigable() -> void:
	for layout in Room.LAYOUTS:
		for size in [Vector2(31, 24), Vector2(37, 28)]:
			var room := Room.new()
			room.bounds = Rect2(Vector2.ZERO, size)
			for o in Room.LAYOUTS[layout]:
				var c := Vector2(size.x * o[0], size.y * o[1])
				room.obstacles.append(Rect2(c - Vector2(o[2], o[3]) * 0.5, Vector2(o[2], o[3])))
			room._build_nav()
			var goal := Vector2(size.x * 0.5, 0.6)
			var stuck := 0
			for sx in range(2, int(size.x) - 2, 2):
				for sz in range(2, int(size.y) - 2, 2):
					var p := Vector2(sx + 0.3, sz + 0.3)
					if room.is_blocked(p, 0.45):
						continue
					var wp := p
					var hold := 0
					var ok := false
					for step in 500:
						hold -= 1
						if hold <= 0 or p.distance_to(wp) < 0.3:
							wp = room.next_waypoint(p, goal, 0.45)
							hold = 15
						p += (wp - p).normalized() * 0.12
						if p.distance_to(goal) < 1.0:
							ok = true
							break
					if not ok:
						stuck += 1
			check(stuck == 0, "layout %s %s: every spot reaches the gate (%d stuck)" % [layout, size, stuck])
			room.free()


func test_worlds_cycle_and_theme_rooms() -> void:
	check(WorldDB.index_for_stage(1) == 0 and WorldDB.index_for_stage(4) == 3 and WorldDB.index_for_stage(5) == 0, "worlds cycle every 4 stages")
	check(WorldDB.ascension_for_stage(5) == 1, "stage 5 is Ascension 1")
	for i in WorldDB.count():
		var w: Dictionary = WorldDB.WORLDS[i]
		check(WorldDB.LORE.has(w["id"]) and WorldDB.LORE[w["id"]].size() == 3, "%s has 3 journal pages" % w["id"])
		var room := Room.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		room.build(rng, 2.0, true, 4, w)
		add_child(room)
		var e := room.spawn_enemy("boss", Vector3(10, 0, 8))
		check(e.display_name == w["boss"]["name"] and e.color == w["boss"]["color"], "%s boss is themed" % w["id"])
		check(e.get("world_index") == i, "%s boss knows its world" % w["id"])
		var g := room.spawn_enemy("grunt", Vector3(14, 0, 8))
		if w["tint"].has("grunt"):
			check(g.color == w["tint"]["grunt"], "%s tints grunts" % w["id"])
		room.queue_free()
		await _frames(2)


func test_ember_burst() -> void:
	var arena := _make_arena()
	var room: Room = arena[0]
	var p: Player = arena[1]
	p.stats.set_base("attack_range", 0.0)
	var e := room.spawn_enemy("grunt", Vector3(12, 0, 10))
	e.speed = 0.0
	e.max_hp = 100000.0   # survive the burst so knockback can be measured
	e.hp = e.max_hp
	await _frames(60)
	var shot := Projectile.new()
	shot.team = Projectile.Team.ENEMY
	shot.position = Vector3(9, 0, 10)
	shot.velocity = Vector3(0.01, 0, 0)
	shot.room = room
	room.entities.add_child(shot)
	var hp0 := e.hp
	var x0 := e.global_position.x
	check(p.try_ability(), "Ember Burst fires")
	check(not p.try_ability(), "Ember Burst has a cooldown")
	check(e.hp < hp0, "burst damages nearby enemies")
	await _frames(20)
	check(not is_instance_valid(shot), "burst destroys enemy projectiles")
	check(e.global_position.x > x0 + 0.5, "burst knocks enemies back (%.2f -> %.2f)" % [x0, e.global_position.x])
	var cd := p.stats.get_stat("ability_cooldown")
	p.stats.add_mods(UpgradeDB.mods_of("stoke"))
	check(p.stats.get_stat("ability_cooldown") < cd, "Stoked Flame shortens the cooldown")
	Engine.time_scale = 1.0
	room.queue_free()


func test_lore_unlocks_persist() -> void:
	Profile.reset()
	check(Profile.unlock_lore("frostfell:1"), "new page unlocks")
	check(not Profile.unlock_lore("frostfell:1"), "same page only once")
	Profile.load_profile()
	check(Profile.has_lore("frostfell:1"), "pages survive reload")


func test_journal_opens_from_camp() -> void:
	var main = load("res://scripts/main.gd").new()
	add_child(main)
	await _frames(5)
	var j: JournalScreen = main.menu.open_journal()
	await _frames(5)
	check(main.menu._modal_open(), "journal opens")
	check(main.camp.screen_circle("journal")[1] > 5.0, "journal prop is on screen")
	j.close()
	await _frames(3)
	check(not main.menu._modal_open(), "journal closes")
	main.queue_free()
	await _frames(2)


func test_pc_controls() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "dodge", "ability", "backpack", "journal", "pause", "confirm", "pick_1", "pick_3"]:
		check(InputMap.has_action(a), "action %s registered" % a)
	check(Controls.key_label("dodge") == "SPACE", "dodge shows SPACE keycap (got %s)" % Controls.key_label("dodge"))
	Input.action_press("move_right")
	Input.action_press("move_up")
	var v := Controls.move_vector()
	check(v.x > 0.6 and v.y < -0.6, "WASD produces a diagonal move vector %s" % v)
	Input.action_release("move_right")
	Input.action_release("move_up")
	check(Controls.move_vector() == Vector2.ZERO, "released keys stop movement")
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	check(ev.is_action("dodge"), "gamepad A dodges")


func test_idle_dodge_follows_mouse_aim() -> void:
	var arena := _make_arena()
	var room: Room = arena[0]
	var p: Player = arena[1]
	p.move_input = Vector2.ZERO
	p.aim_dir = Vector3(-1, 0, 0)
	p.try_dodge()
	check(p.dash_dir.is_equal_approx(Vector3(-1, 0, 0)), "standing still dodges toward the cursor")
	Engine.time_scale = 1.0
	room.queue_free()


func test_settings_persist() -> void:
	Settings.set_value("screen_shake", false)
	Settings.set_value("damage_numbers", false)
	Settings.screen_shake = true
	Settings.damage_numbers = true
	Settings.load_settings()
	check(not Settings.screen_shake and not Settings.damage_numbers, "settings survive reload")
	Settings.set_value("screen_shake", true)
	Settings.set_value("damage_numbers", true)


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
	if not died and run.run.stage < 2:
		var info := []
		for e in run.room.alive:
			if is_instance_valid(e):
				info.append("%s@%s st=%s los=%s hp=%d" % [e.enemy_id, Vector2i(Flat.xz(e.global_position)), e.state, e.has_los(), e.hp])
		for n in run.room.entities.get_children():
			if n is LootPickup or n is LorePickup:
				var here := Flat.xz(run.player.global_position)
				var to := Flat.xz(n.global_position)
				print("    loot at %s blocked=%s waypoint=%s bounds=%s obstacles=%s" % [to, run.room.is_blocked(to, 0.45), run.room.next_waypoint(here, to, 0.45), run.room.bounds, run.room.obstacles])
		print("    player move_input=%s velocity=%s dead=%s players_in_tree=%d" % [run.player.move_input, run.player.velocity, run.player.dead, get_tree().get_nodes_in_group("player").size()])
		print("    STALL: layout=%s wave=%d player=%s weapon=%s door=%s alive=%s" % [run.room.layout_name, run.room.wave_index, Vector2i(Flat.xz(run.player.global_position)), run.player.weapon_id, run.room.door_open, info])
	get_tree().paused = false
	Engine.time_scale = 1.0
	main.queue_free()
	await get_tree().physics_frame
	return result


func test_full_run_flow_reaches_stage_2() -> void:
	var r = await _sim_run(11, true, 600.0)
	print("    god-bot run: ", r)
	check(r["stage"] >= 2, "bot clears 4 rooms + boss and enters stage 2 (world 2)")
	check(Profile.has_lore("ashen_woods:0") and Profile.has_lore("ashen_woods:2"), "arrival and guardian pages unlocked")
	check(Profile.has_lore("frostfell:0"), "entering world 2 unlocks its first page")
	check(r["loot"] >= 2, "boss dropped and bot collected loot")
	check(r["kills"] > 10, "enemies were killed")


func test_balance_probe() -> void:
	# Informational: how far does a simple bot get without cheats?
	for s in [1, 2, 3]:
		var r = await _sim_run(s, false, 400.0)
		print("    fair-bot seed %d: reached room %d, died=%s, dmg_taken=%d, dodges=%d (perfect %d), kills=%d" % [s, r["progress"] + 1, r["died"], r["damage_taken"], r["dodges"], r["perfect"], r["kills"]])
	check(true, "probe")
