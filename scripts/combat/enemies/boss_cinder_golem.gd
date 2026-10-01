extends Enemy
## Boss - Cinder Golem. Cycles between three telegraphed attacks:
##  * Meteor Slam: AoE circles drop on your position one after another
##  * Ember Nova: rings of slow orbs with a gap you can slip through
##  * Molten Rush: long charge across the arena
## Below 50% HP it enrages: faster windups, double novas and summoned grunts.

signal summon_requested(ids: Array, near: Vector3)

const ATTACKS := ["slam", "nova", "rush"]

var _last_attack := ""
var _attack_count := 0
var _dir := Vector3.FORWARD
var _dash_len := 0.0
var _dashed := 0.0
var _hit_player := false
var _pending := 0
var _core: MeshInstance3D


func _build_model() -> Node3D:
	bar_height = 4.0
	var m := Models.boss(color)
	_core = m.get_node("Core")
	return m


func _on_ready() -> void:
	is_boss = true
	set_state("walk")


func enraged() -> bool:
	return hp < max_hp * 0.5


func _windup_mult() -> float:
	return 0.75 if enraged() else 1.0


func _think(delta: float) -> void:
	if _core:
		var s := 1.0 + sin(_t * (9.0 if enraged() else 4.0)) * 0.12
		_core.scale = Vector3.ONE * s
	match state:
		"walk":
			if player_alive():
				steer_to(player.global_position)
			if state_time > (0.9 if enraged() else 1.5):
				_start_attack()
		"busy":
			face_player()
			if _pending <= 0 and telegraphs.is_empty():
				set_state("walk")
		"rush":
			velocity = _dir * 26.0
			_dashed += 26.0 * delta
			if not _hit_player and player_alive() and Flat.dist(global_position, player.global_position) < radius + player.radius:
				_hit_player = true
				player.take_damage(damage * 1.4, self)
			if _dashed >= _dash_len or get_slide_collision_count() > 0:
				Fx.ring(get_parent(), global_position, color, 3.5, 0.35)
				Fx.burst(get_parent(), global_position, Color("a8a29e"), 1.4, 24)
				set_state("recover")
		"recover":
			if state_time > 0.9:
				set_state("walk")


func _animate(delta: float) -> void:
	if state == "walk":
		var v := Vector3(velocity.x, 0, velocity.z)
		if v.length() > 0.2:
			facing = v.normalized()
	super._animate(delta)


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
	var tg := add_telegraph(Telegraph.circle(player.global_position, 2.5, 0.95 * _windup_mult()))
	tg.finished.connect(_on_meteor)


func _on_meteor(tg: Telegraph) -> void:
	if dead:
		return
	resolve_hit(tg, damage)
	Fx.ring(get_parent(), tg.global_position, Color("ff7a2f"), 2.8, 0.3)
	Fx.burst(get_parent(), tg.global_position, Color("ff9a3d"), 1.2, 20)


func _nova() -> void:
	var tg := add_telegraph(Telegraph.circle(global_position, radius + 1.0, 0.8 * _windup_mult()))
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
		var a := (i + offset) * TAU / n
		fire_projectile(Vector3(cos(a), 0, sin(a)), 7.5, damage * 0.8, 0.3)


func _rush() -> void:
	if not player_alive():
		set_state("walk")
		return
	_dir = to_player().normalized()
	facing = _dir
	_dash_len = 22.0
	var tg := add_telegraph(Telegraph.lane(global_position, _dir, _dash_len, radius * 2.0 + 0.5, 1.0 * _windup_mult()))
	tg.finished.connect(func(_t):
		if dead:
			return
		_dashed = 0.0
		_hit_player = false
		set_state("rush"))
