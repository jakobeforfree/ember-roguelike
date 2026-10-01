class_name Projectile
extends Node3D
## Manual-collision projectile on the ground plane. Player shots hit "enemies",
## enemy shots hit the "player". Walls/obstacles come from the Room.

enum Team { PLAYER, ENEMY }

var team := Team.PLAYER
var velocity := Vector3.ZERO
var damage := 10.0
var crit := false
var radius := 0.2
var max_distance := 20.0
var pierce := 0
var color := Color.WHITE
var room: Room
var source: Node
var _traveled := 0.0
var _hit := {}


func _ready() -> void:
	velocity.y = 0.0
	child_entered_tree.connect(func(n): if n is GeometryInstance3D: n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	rotation.y = Flat.yaw(velocity)
	if team == Team.PLAYER:
		position.y = 1.0
		var c := Color.WHITE if crit else color
		Models.part(self, Models.box(Vector3(0.07, 0.07, 0.8)), Mats.glow(c, 3.0 if crit else 2.0))
		var trail := Models.part(self, Models.box(Vector3(0.05, 0.05, 0.9)), Mats.fx(Color(c, 0.35), true), Vector3(0, 0, 0.8))
		trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		position.y = 0.9
		Models.part(self, Models.sphere(radius, 10, 5), Mats.glow(color, 1.3))
		var halo := Models.part(self, Models.sphere(radius * 1.6, 10, 5), Mats.fx(Color(color, 0.22), false))
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_traveled += step.length()
	if _traveled > max_distance or (room and room.is_blocked(Flat.xz(global_position))):
		Fx.ring(get_parent(), Vector3(global_position.x, 0, global_position.z), color, 0.5, 0.15)
		queue_free()
		return
	if team == Team.PLAYER:
		for e in get_tree().get_nodes_in_group("enemies"):
			if _hit.has(e) or not e.is_targetable():
				continue
			if Flat.dist(global_position, e.global_position) <= radius + e.radius:
				_hit[e] = true
				Combat.player_hits_enemy(source, e, damage, crit, true)
				if pierce <= 0:
					queue_free()
					return
				pierce -= 1
	else:
		var p = get_tree().get_first_node_in_group("player")
		if p and Flat.dist(global_position, p.global_position) <= radius + p.radius * 0.8:
			p.take_damage(damage, self)
			queue_free()
