class_name Projectile
extends Node3D
## Manual-collision projectile on the ground plane. Player shots hit "enemies",
## enemy shots hit the "player". Walls/obstacles come from the Room.
## Supports several looks (arrow, orb, dagger, bolt), homing and burst-on-hit.

enum Team { PLAYER, ENEMY }

const HOMING_TURN := 5.0   # radians per second

var team := Team.PLAYER
var visual := "arrow"
var velocity := Vector3.ZERO
var damage := 10.0
var crit := false
var radius := 0.2
var max_distance := 20.0
var pierce := 0
var color := Color.WHITE
var room: Room
var source: Node
var homing_target = null
var explode_radius := 0.0
var _traveled := 0.0
var _hit := {}
var _model: Node3D


func _ready() -> void:
	velocity.y = 0.0
	rotation.y = Flat.yaw(velocity)
	child_entered_tree.connect(func(n): if n is GeometryInstance3D: n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_model = Node3D.new()
	add_child(_model)
	var c := Color.WHITE if crit else color
	if team == Team.ENEMY:
		position.y = 0.9
		Models.part(_model, Models.sphere(radius, 10, 5), Mats.glow(color, 1.3))
		Models.part(_model, Models.sphere(radius * 1.6, 10, 5), Mats.fx(Color(color, 0.22), false))
		return
	position.y = 1.0
	match visual:
		"orb":
			Models.part(_model, Models.sphere(radius, 10, 5), Mats.glow(c, 3.0))
			Models.part(_model, Models.sphere(radius * 1.8, 10, 5), Mats.fx(Color(c, 0.25), true))
			Models.part(_model, Models.cyl(radius * 0.6, 0.0, 0.9, 6), Mats.fx(Color(c, 0.3), true), Vector3(0, 0, 0.5), Vector3(90, 0, 0))
		"dagger":
			Models.part(_model, Models.box(Vector3(0.05, 0.03, 0.42)), Mats.solid(Color("e5e7eb"), 0.25, 0.8))
			Models.part(_model, Models.box(Vector3(0.14, 0.04, 0.05)), Mats.glow(c, 1.5), Vector3(0, 0, 0.2))
		"bolt":
			Models.part(_model, Models.box(Vector3(0.09, 0.09, 1.0)), Mats.solid(Color("57534e"), 0.5, 0.6))
			Models.part(_model, Models.cyl(0.0, 0.1, 0.25, 4), Mats.glow(c, 2.0), Vector3(0, 0, -0.6), Vector3(-90, 0, 0))
			Models.part(_model, Models.box(Vector3(0.05, 0.05, 1.2)), Mats.fx(Color(c, 0.3), true), Vector3(0, 0, 1.0))
		_:
			Models.part(_model, Models.box(Vector3(0.07, 0.07, 0.8)), Mats.glow(c, 3.0 if crit else 2.0))
			Models.part(_model, Models.box(Vector3(0.05, 0.05, 0.9)), Mats.fx(Color(c, 0.35), true), Vector3(0, 0, 0.8))


func _physics_process(delta: float) -> void:
	if visual == "dagger":
		_model.rotation.z += delta * 25.0
	if homing_target != null:
		if is_instance_valid(homing_target) and not homing_target.dead:
			var want: Vector3 = homing_target.global_position - global_position
			want.y = 0.0
			var cur := velocity.normalized()
			var ang := Vector2(cur.x, cur.z).angle_to(Vector2(want.x, want.z))
			var turn := clampf(ang, -HOMING_TURN * delta, HOMING_TURN * delta)
			velocity = velocity.rotated(Vector3.UP, -turn)
			rotation.y = Flat.yaw(velocity)
		else:
			homing_target = null
	var step := velocity * delta
	position += step
	_traveled += step.length()
	if _traveled > max_distance or (room and room.is_blocked(Flat.xz(global_position))):
		_impact()
		queue_free()
		return
	if team == Team.PLAYER:
		for e in get_tree().get_nodes_in_group("enemies"):
			if _hit.has(e) or not e.is_targetable():
				continue
			if Flat.dist(global_position, e.global_position) <= radius + e.radius:
				_hit[e] = true
				Combat.player_hits_enemy(source, e, damage, crit, true)
				if explode_radius > 0.0:
					_burst(e)
				if pierce <= 0:
					queue_free()
					return
				pierce -= 1
	else:
		var p = get_tree().get_first_node_in_group("player")
		if p and Flat.dist(global_position, p.global_position) <= radius + p.radius * 0.8:
			p.take_damage(damage, self)
			queue_free()


func _impact() -> void:
	if explode_radius > 0.0 and team == Team.PLAYER:
		_burst(null)
	else:
		Fx.ring(get_parent(), Vector3(global_position.x, 0, global_position.z), color, 0.5, 0.15)


## Splash damage (no procs, so it can't chain-react endlessly).
func _burst(direct_hit) -> void:
	var pos := Vector3(global_position.x, 0, global_position.z)
	Fx.ring(get_parent(), pos, color, explode_radius, 0.25)
	Fx.burst(get_parent(), pos, color, 0.6, 8)
	if source == null or not is_instance_valid(source):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != direct_hit and e.is_targetable() and Flat.dist(e.global_position, pos) <= explode_radius + e.radius:
			Combat.player_hits_enemy(source, e, damage * 0.5, false, false)
