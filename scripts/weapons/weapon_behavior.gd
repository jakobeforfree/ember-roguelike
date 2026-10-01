class_name WeaponBehavior
extends RefCounted
## Base class for how a weapon attacks. Weapons differ in *behavior*, not just numbers:
## a bow fires projectiles, a sword would sweep an arc, a staff would lob orbs, etc.
## Subclasses override `attack()`; on-hit effects are handled by Combat for all weapons.

var player  # Player node
var def: Dictionary


func setup(p, weapon_def: Dictionary) -> void:
	player = p
	def = weapon_def


## Called when the attack timer is ready and a target is in range.
func attack(_target) -> void:
	pass


## Hook for weapons that need per-frame logic (charge-up, orbiting blades...).
func update(_delta: float) -> void:
	pass
