class_name Projectile
extends Node2D
## Simple manual-collision projectile. Player projectiles hit "enemies",
## enemy projectiles hit "player". Walls/obstacles come from the Room.

enum Team { PLAYER, ENEMY }

var team := Team.PLAYER
var velocity := Vector2.ZERO
var damage := 10.0
var crit := false
var radius := 7.0
var max_distance := 900.0
var pierce := 0
var color := Color.WHITE
var room: Room
var source: Node             # who fired (player for on-hit procs)
var _traveled := 0.0
var _hit := {}


func _ready() -> void:
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_traveled += step.length()
	if _traveled > max_distance or (room and room.is_blocked(global_position)):
		Fx.spawn(get_parent(), Fx.Kind.RING, global_position, color, 12.0, 0.15)
		queue_free()
		return
	if team == Team.PLAYER:
		for e in get_tree().get_nodes_in_group("enemies"):
			if _hit.has(e) or not e.is_targetable():
				continue
			if global_position.distance_to(e.global_position) <= radius + e.radius:
				_hit[e] = true
				Combat.player_hits_enemy(source, e, damage, crit, true)
				if pierce <= 0:
					queue_free()
					return
				pierce -= 1
	else:
		var p = get_tree().get_first_node_in_group("player")
		if p and global_position.distance_to(p.global_position) <= radius + p.radius * 0.8:
			p.take_damage(damage, self)
			queue_free()


func _draw() -> void:
	if team == Team.PLAYER:
		draw_line(Vector2(-14, 0), Vector2(6, 0), color, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(4, -5), Vector2(4, 5)]), Color.WHITE if crit else color)
	else:
		draw_circle(Vector2.ZERO, radius + 3.0, Color(color, 0.35))
		draw_circle(Vector2.ZERO, radius, color)
