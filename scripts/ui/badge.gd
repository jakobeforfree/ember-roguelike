class_name Badge
extends Control
## Circular icon badge drawn directly (crisp at any size, no StyleBox seams).

var icon_name := "circle"
var color := Color.WHITE
var fill_alpha := 0.16
var border_alpha := 0.6
var icon_scale := 0.52


static func make(p_icon: String, p_color: Color, diameter: float, p_fill_alpha: float = 0.16) -> Badge:
	var b := Badge.new()
	b.icon_name = p_icon
	b.color = p_color
	b.fill_alpha = p_fill_alpha
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 1.5
	draw_circle(c, r, Color(color, fill_alpha))
	draw_arc(c, r, 0, TAU, 64, Color(color, border_alpha), 2.0, true)
	var f := UiKit.icon_font()
	var fs := int(r * 2.0 * icon_scale)
	var g := Icons.glyph(icon_name)
	var sz := f.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, c + Vector2(-sz.x * 0.5, fs * 0.5), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
