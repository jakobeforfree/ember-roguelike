extends Enemy
## Boss - Cinder Golem. Cycles between three telegraphed attacks:
##  * Meteor Slam: AoE circles drop on your position one after another
##  * Ember Nova: rings of slow orbs with a gap you can slip through
##  * Molten Rush: long charge across the arena
## Below 50% HP it enrages: faster windups, double novas and summoned grunts.

signal summon_requested(ids: Array, near: Vector2)

const ATTACKS := ["slam", "nova", "rush"]

var _last_attack := ""
var _attack_count := 0
var _dir := Vector2.ZERO
var _dash_len := 0.0
var _dashed := 0.0
var _hit_player := false
var _pending := 0


func _on_ready() -> void:
	is_boss = true
	set_state("walk")


func enraged() -> bool:
	return hp < max_hp * 0.5


func _windup_mult() -> float:
	return 0.75 if enraged() else 1.0


func _think(delta: float) -> void:
	match state:
		"walk":
			if player_alive():
				steer_to(player.global_position)
			if state_time > (0.9 if enraged() else 1.5):
				_start_attack()
		"busy":
			if _pending <= 0 and telegraphs.is_empty():
				set_state("walk")
		"rush":
			velocity = _dir * 1050.0
			_dashed += 1050.0 * delta
			if not _hit_player and player_alive() and global_position.distance_to(player.global_position) < radius + player.radius:
				_hit_player = true
				player.take_damage(damage * 1.4, self)
			if _dashed >= _dash_len or get_slide_collision_count() > 0:
				Fx.spawn(get_parent(), Fx.Kind.BURST, global_position, color, 90.0, 0.35)
				set_state("recover")
		"recover":
			if state_time > 0.9:
				set_state("walk")


func _start_attack() -> void:
	_attack_count += 1
	if enraged() and _attack_count % 3 == 0:
		summon_requested.emit(["grunt", "grunt"] if difficulty < 4.0 else ["grunt", "charger"], global_position)
	var options := ATTACKS.filter(func(a): return a != _last_attack)
	var pick: String = options[randi() % options.size()]
	_last_attack = pick
	set_state("busy")
	match pick:
		"slam": _slam()
		"nova": _nova()
		"rush": _rush()


func _slam() -> void:
	var count := 4 if enraged() else 3
	_pending = count
	for i in count:
		after(i * 0.45 * _windup_mult(), _drop_meteor)


func _drop_meteor() -> void:
	_pending -= 1
	if dead or not player_alive():
		return
	var tg := add_telegraph(Telegraph.circle(player.global_position, 100.0, 0.95 * _windup_mult()))
	tg.finished.connect(_on_meteor)


func _on_meteor(tg: Telegraph) -> void:
	if dead:
		return
	resolve_hit(tg, damage)
	Fx.spawn(get_parent(), Fx.Kind.BURST, tg.global_position, Color("ff7a2f"), 100.0, 0.3)


func _nova() -> void:
	var tg := add_telegraph(Telegraph.circle(global_position, radius + 40.0, 0.8 * _windup_mult()))
	tg.color = Color(1.0, 0.55, 0.1)
	var rings := 2 if enraged() else 1
	_pending = rings
	tg.finished.connect(func(_t):
		for r in rings:
			after(r * 0.45, _fire_ring.bind(r * 0.5)))


func _fire_ring(offset: float) -> void:
	_pending -= 1
	if dead:
		return
	var n := 18
	var gap := randi() % n
	for i in n:
		if i == gap or i == (gap + 1) % n:
			continue  # an opening to slip through
		fire_projectile(Vector2.from_angle((i + offset) * TAU / n), 300.0, damage * 0.8, 11.0)


func _rush() -> void:
	if not player_alive():
		set_state("walk")
		return
	_dir = to_player().normalized()
	_dash_len = 900.0
	var tg := add_telegraph(Telegraph.lane(global_position, _dir, _dash_len, radius * 2.0 + 20.0, 1.0 * _windup_mult()))
	tg.finished.connect(func(_t):
		if dead:
			return
		_dashed = 0.0
		_hit_player = false
		set_state("rush"))


func _draw_body(body: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var r := radius * (1.0 if i % 2 == 0 else 0.82)
		pts.append(Vector2.from_angle(i * TAU / 8.0 + 0.2) * r)
	draw_colored_polygon(pts, body.darkened(0.25))
	draw_circle(Vector2.ZERO, radius * 0.6, body)
	var core := Color("ffe066") if enraged() else Color("ffb347")
	draw_circle(Vector2.ZERO, radius * 0.28, core)
