class_name WeaponBehavior
extends RefCounted
## Base class for how a weapon attacks. Weapons differ in *behavior*: projectiles,
## homing orbs, melee sweeps, hitscan chains, area novas... Damage rolls, crits,
## lifesteal and elemental procs are shared through Combat so every weapon gets them.

var player  # Player node
var def: Dictionary
var id := ""


func setup(p, weapon_def: Dictionary) -> void:
	player = p
	def = weapon_def


## Called when the attack timer is ready and a target is in range.
func attack(_target) -> void:
	pass


## Hook for weapons that need per-frame logic (charge-up, orbiting blades...).
func update(_delta: float) -> void:
	pass


func stats() -> Stats:
	return player.stats


## Flat direction from the player to a target.
func dir_to(target) -> Vector3:
	var d: Vector3 = target.global_position - player.global_position
	d.y = 0.0
	return d.normalized()


## Spawns a player projectile. opts: visual, speed, size, pierce_bonus, homing, explode, scale, range_mult
func shoot(pos: Vector3, dir: Vector3, opts: Dictionary = {}) -> Projectile:
	var roll := Combat.roll_damage(player, opts.get("scale", 1.0))
	var p := Projectile.new()
	p.team = Projectile.Team.PLAYER
	p.visual = opts.get("visual", "arrow")
	p.position = pos + dir * 0.6
	p.velocity = dir * opts.get("speed", stats().get_stat("projectile_speed"))
	p.damage = roll[0]
	p.crit = roll[1]
	p.radius = opts.get("size", 0.2)
	p.pierce = stats().geti("pierce") + opts.get("pierce_bonus", 0)
	p.max_distance = stats().get_stat("attack_range") * opts.get("range_mult", 1.6)
	p.homing_target = opts.get("homing", null)
	p.explode_radius = opts.get("explode", 0.0)
	p.color = def.get("color", Color.WHITE)
	p.room = player.room
	p.source = player
	player.get_parent().add_child(p)
	return p
