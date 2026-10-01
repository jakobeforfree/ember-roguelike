class_name UiKit
extends RefCounted
## Design system: palette, fonts, icons and component builders so every screen
## shares one clean, modern look. Change values here to restyle the whole game.

const BG := Color("0b0d14")
const SURFACE := Color(0.075, 0.085, 0.125, 0.88)
const SURFACE_2 := Color(0.12, 0.13, 0.18, 0.95)
const BORDER := Color(1, 1, 1, 0.08)
const ACCENT := Color("ff7a3d")
const TEAL := Color("2dd4bf")
const GOLD := Color("fbbf24")
const DANGER := Color("f43f5e")
const TEXT := Color("eef0f4")
const MUTED := Color("8b90a0")

const FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"
const ICON_PATH := "res://assets/fonts/MaterialIconsRound-Regular.otf"

static var _fonts := {}
static var _theme: Theme


static func font(weight: int = 500, spacing: int = 0) -> Font:
	var key := "%d_%d" % [weight, spacing]
	if not _fonts.has(key):
		var fv := FontVariation.new()
		fv.base_font = load(FONT_PATH)
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		fv.spacing_glyph = spacing
		_fonts[key] = fv
	return _fonts[key]


static func icon_font() -> Font:
	if not _fonts.has("icons"):
		_fonts["icons"] = load(ICON_PATH)
	return _fonts["icons"]


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(500)
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", box(SURFACE, 20, BORDER, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4
	t.set_stylebox("grabber", "VScrollBar", sb)
	t.set_stylebox("grabber_highlight", "VScrollBar", sb)
	t.set_stylebox("grabber_pressed", "VScrollBar", sb)
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	_theme = t
	return t


static func box(color: Color, radius: int = 16, border: Color = Color.TRANSPARENT, border_w: int = 0, margin: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	return sb


static func label(text: String, size: int = 20, color: Color = TEXT, weight: int = 500, spacing: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(weight, spacing))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func icon(name: String, size: int = 24, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = Icons.glyph(name)
	l.add_theme_font_override("font", icon_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## kind: "primary" (accent fill), "secondary" (surface), "ghost" (transparent), "gold"
static func button(text: String, kind: String = "primary", size: int = 20, min_size := Vector2(0, 56), icon_name: String = "") -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	var bg := ACCENT
	var fg := Color("1a0f08")
	var border := Color.TRANSPARENT
	match kind:
		"secondary":
			bg = Color(1, 1, 1, 0.07)
			fg = TEXT
			border = Color(1, 1, 1, 0.1)
		"ghost":
			bg = Color(0, 0, 0, 0)
			fg = MUTED
		"gold":
			bg = Color(GOLD, 0.14)
			fg = GOLD
			border = Color(GOLD, 0.35)
		"teal":
			bg = TEAL
			fg = Color("06201d")
	var r := int(min_size.y * 0.5) - 2 if min_size.y <= 64 else 22
	b.add_theme_stylebox_override("normal", box(bg, r, border, 1 if border.a > 0 else 0))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.08), r, border, 1 if border.a > 0 else 0))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.15), r, border, 1 if border.a > 0 else 0))
	b.add_theme_stylebox_override("disabled", box(Color(bg, bg.a * 0.4), r))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(row)
	if icon_name != "":
		row.add_child(icon(icon_name, int(size * 1.25), fg))
	if text != "":
		row.add_child(label(text, size, fg, 700 if kind in ["primary", "teal"] else 600))
	press_feedback(b)
	return b


## Subtle scale bounce on press - makes touch UI feel responsive.
static func press_feedback(c: Control) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	if c is BaseButton:
		c.button_down.connect(func(): c.create_tween().tween_property(c, "scale", Vector2.ONE * 0.95, 0.06))
		c.button_up.connect(func(): c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


static func panel(color: Color = SURFACE, border: Color = BORDER, border_w: int = 1, radius: int = 20, margin: int = 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, border, border_w, margin))
	return p


## Small rounded "pill" with optional icon.
static func chip(text: String, color: Color, icon_name: String = "", size: int = 15) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(Color(color, 0.14), 11, Color(color, 0.35), 1, 0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	if icon_name != "":
		row.add_child(icon(icon_name, size + 3, color))
	var l := label(text, size, color, 600)
	l.visible = text != ""
	l.name = "Text"
	row.add_child(l)
	return p


## The text label inside a chip (it always exists, hidden when empty).
static func chip_label(chip: PanelContainer) -> Label:
	return chip.find_child("Text", true, false)


static func dim_overlay(alpha: float = 0.78) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.025, 0.05, alpha)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Fade + scale-up entrance animation (container-safe: never touches position).
static func pop_in(c: CanvasItem, delay: float = 0.0, _offset: float = 0.0) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(maxf(delay, 0.01))
	if c is Control:
		var ctrl: Control = c
		ctrl.scale = Vector2.ONE * 0.92
		tw.tween_callback(func(): ctrl.pivot_offset = ctrl.size * 0.5)
		tw.tween_property(ctrl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "modulate:a", 1.0, 0.22)
	else:
		tw.tween_property(c, "modulate:a", 1.0, 0.22)
