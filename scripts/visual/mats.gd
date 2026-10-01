class_name Mats
extends RefCounted
## Cached materials so hundreds of meshes share a handful of material instances.

static var _cache := {}


static func solid(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "s%s%.2f%.2f" % [color.to_html(), roughness, metallic]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		m.metallic = metallic
		_cache[key] = m
	return _cache[key]


## Emissive material; with glow enabled in the environment these bloom.
static func glow(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var key := "g%s%.2f" % [color.to_html(), energy]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
		_cache[key] = m
	return _cache[key]


## Unshaded, transparent - for overlays, rings and effects. Not cached (often animated).
static func fx(color: Color, additive: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shadow_to_opacity = false
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


## Shared hit-flash / status tints applied via GeometryInstance3D.material_overlay.
static func overlay(color: Color) -> StandardMaterial3D:
	var key := "o%s" % color.to_html()
	if not _cache.has(key):
		var m := fx(color)
		_cache[key] = m
	return _cache[key]
