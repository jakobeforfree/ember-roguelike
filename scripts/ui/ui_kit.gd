class_name UiKit
extends RefCounted
## Helpers for building placeholder UI in code with a consistent look.

const BG := Color("1c1820")
const PANEL := Color("2a2430")
const ACCENT := Color("ff8c42")
const TEXT := Color("f3ece4")
const MUTED := Color("a89fa8")


static func box(color: Color, radius: int = 14, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	return sb


static func label(text: String, size: int = 22, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l


static func button(text: String, size: int = 24, color: Color = ACCENT, min_size := Vector2(0, 64)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("1c1410") if color.get_luminance() > 0.5 else TEXT)
	b.add_theme_color_override("font_hover_color", Color("1c1410") if color.get_luminance() > 0.5 else TEXT)
	b.add_theme_color_override("font_pressed_color", Color("1c1410") if color.get_luminance() > 0.5 else TEXT)
	b.add_theme_stylebox_override("normal", box(color))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", box(color.darkened(0.5)))
	return b


static func panel(color: Color = PANEL, border: Color = Color.TRANSPARENT, border_w: int = 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, 16, border, border_w))
	return p


static func dim_overlay() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, 0.7)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
