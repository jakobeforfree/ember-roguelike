class_name Telegraph
extends Node3D
## Ground-projected warning for an incoming attack. The zone appears immediately
## and fills up; the hit resolves exactly when it is full, using the same shape
## that is drawn - what you see is what hits you.

signal finished(tg: Telegraph)

enum Shape { CIRCLE, LANE, ARC }

const SHADER := preload("res://shaders/telegraph.gdshader")

var shape := Shape.CIRCLE
var radius := 2.0
var direction := Vector3.FORWARD
var length := 8.0
var width := 1.5
var half_angle := 0.8
var duration := 0.8
var elapsed := 0.0
var color := Color("ff3b30")
var _mat: ShaderMaterial


static func circle(pos: Vector3, r: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.position = pos
	t.radius = r
	t.duration = time
	return t


static func lane(origin: Vector3, dir: Vector3, lane_len: float, w: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.shape = Shape.LANE
	t.position = origin
	t.direction = Vector3(dir.x, 0, dir.z).normalized()
	t.length = lane_len
	t.width = w
	t.duration = time
	return t


static func arc(pos: Vector3, dir: Vector3, r: float, half: float, time: float) -> Telegraph:
	var t := Telegraph.new()
	t.shape = Shape.ARC
	t.position = pos
	t.direction = Vector3(dir.x, 0, dir.z).normalized()
	t.radius = r
	t.half_angle = half
	t.duration = time
	return t


func _ready() -> void:
	position.y = 0.03
	rotation.y = atan2(-direction.z, direction.x)   # local +X = direction
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	if shape == Shape.LANE:
		plane.size = Vector2(length, width)
		plane.center_offset = Vector3(length * 0.5, 0, 0)
	else:
		plane.size = Vector2(radius, radius) * 2.0
	mi.mesh = plane
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("shape", shape)
	_mat.set_shader_parameter("color", color)
	_mat.set_shader_parameter("radius", radius)
	_mat.set_shader_parameter("lane_length", length)
	_mat.set_shader_parameter("lane_width", width)
	_mat.set_shader_parameter("half_angle", half_angle)
	mi.material_override = _mat
	add_child(mi)


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)


func _process(delta: float) -> void:
	elapsed += delta
	if _mat:
		_mat.set_shader_parameter("progress", progress())
	if elapsed >= duration:
		set_process(false)
		finished.emit(self)
		queue_free()


## True if a circle (target_pos, target_radius) on the ground overlaps the zone.
func contains(target_pos: Vector3, target_radius: float = 0.0) -> bool:
	var local := Vector2(target_pos.x - global_position.x, target_pos.z - global_position.z)
	var dir := Vector2(direction.x, direction.z)
	match shape:
		Shape.CIRCLE:
			return local.length() <= radius + target_radius
		Shape.ARC:
			if local.length() > radius + target_radius:
				return false
			if local.length() < target_radius:
				return true
			return absf(dir.angle_to(local)) <= half_angle
		Shape.LANE:
			var along := local.dot(dir)
			var across := absf(local.dot(dir.orthogonal()))
			return along >= -target_radius and along <= length + target_radius and across <= width * 0.5 + target_radius
	return false
