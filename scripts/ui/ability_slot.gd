class_name AbilitySlot
extends Control
## PC action-bar slot: rounded square with icon, radial cooldown sweep and a keycap.

var icon_name := "double_arrow"
var key_text := "SPACE"
var color := UiKit.TEAL
var locked := false
var cooldown_ratio := 0.0
var cooldown_left := 0.0
var _flash := 0.0
var _perfect := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(76, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash() -> void:
	_flash = 0.15


func flash_perfect() -> void:
	_perfect = 0.6


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_perfect = maxf(0.0, _perfect - delta)
	queue_redraw()


func _draw() -> void:
	var sq := Rect2(Vector2(4, 0), Vector2(68, 68))
	var is_ready := cooldown_ratio <= 0.0 and not locked
	var border := Color(color, 0.9) if is_ready else Color(1, 1, 1, 0.12)
	draw_style_box(UiKit.box(Color(0.06, 0.07, 0.11, 0.85), 16, border, 2, 0), sq)
	if is_ready:
		draw_style_box(UiKit.box(Color(color, 0.16 + (0.3 if _flash > 0.0 else 0.0)), 16, Color.TRANSPARENT, 0, 0), sq.grow(-3))
	var f := UiKit.icon_font()
	var g := Icons.glyph("lock" if locked else icon_name)
	var gsz := f.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	var c := sq.get_center()
	draw_string(f, c + Vector2(-gsz.x * 0.5, 13), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, color if is_ready else Color(1, 1, 1, 0.35))
	if not is_ready and not locked:
		# Pie sweep: darkened portion still cooling down
		var pts := PackedVector2Array([c])
		var steps := 40
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * (1.0 - cooldown_ratio) + TAU * cooldown_ratio * i / steps
			var d := Vector2.from_angle(a)
			var t := 34.0 / maxf(absf(d.x), absf(d.y))   # project onto the square
			pts.append(c + d * minf(t, 48.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.5))
		var font := UiKit.font(800)
		var txt := "%.1f" % cooldown_left
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string_outline(font, c + Vector2(-tw * 0.5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0, 0, 0, 0.7))
		draw_string(font, c + Vector2(-tw * 0.5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if _perfect > 0.0:
		var k := 1.0 - _perfect / 0.6
		draw_style_box(UiKit.box(Color.TRANSPARENT, 18, Color(color, 1.0 - k), 3, 0), sq.grow(4.0 + k * 14.0))
	UiKit.draw_keycap(self, Vector2(size.x * 0.5, 86), key_text, 1.0 if not locked else 0.5)
