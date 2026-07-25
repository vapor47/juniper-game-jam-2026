extends Control
class_name PaylineOverlay
## Draws payline paths across the whole grid — cell centre to cell centre.
##
## §9 calls tracing the path the expensive part of reading the board, and it's
## the one thing per-cell highlighting can't do: highlighted cells tell you
## *which* cells, a drawn line tells you the order and the shape. This has to
## live above all five columns, so it can't be per-column overlay work.

const FOCUS_COLOR := Color(1, 0.85, 0.3, 0.95)
const FOCUS_WIDTH := 2.0
const OUTLINE_COLOR := Color(0.05, 0.04, 0.0, 0.7)
const SELECTED_WIDTH := 1.5

## Distinct hues so overlapping purchased lines stay tellable apart.
const SELECTED_COLORS: Array[Color] = [
	Color(0.45, 0.85, 1.0, 0.85),
	Color(0.65, 1.0, 0.55, 0.85),
	Color(1.0, 0.55, 0.85, 0.85),
]

var columns: Array[ReelColumn] = []

var selected_lines: Array[Payline] = []:
	set(value):
		selected_lines = value
		queue_redraw()

## The line being hovered, drawn on top and brighter.
var focused_line: Payline = null:
	set(value):
		focused_line = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if columns.is_empty():
		return

	for i in selected_lines.size():
		var line: Payline = selected_lines[i]
		if line == focused_line:
			continue  # drawn last, in focus styling
		_draw_line(line, SELECTED_COLORS[i % SELECTED_COLORS.size()], SELECTED_WIDTH, false)

	if focused_line != null:
		_draw_line(focused_line, FOCUS_COLOR, FOCUS_WIDTH, true)


## No vertex markers — the cells themselves carry the glowing border, so dots
## on top of them would just be noise.
func _draw_line(payline: Payline, color: Color, width: float, outlined: bool) -> void:
	var points := _points_for(payline)
	if points.size() < 2:
		return

	# A hairline of dark backing keeps the thin line readable over any symbol
	# colour without thickening the line itself.
	if outlined:
		draw_polyline(points, OUTLINE_COLOR, width + 1.5, true)
	draw_polyline(points, color, width, true)


func _points_for(payline: Payline) -> PackedVector2Array:
	var points := PackedVector2Array()
	for col in mini(payline.pattern.size(), columns.size()):
		points.append(_cell_centre(col, payline.row_at(col)))
	return points


## Centre of a given cell, in this overlay's local space. Read off the live
## node rects so it stays correct through resizes and layout changes.
func _cell_centre(col: int, row: int) -> Vector2:
	var column: ReelColumn = columns[col]
	var window: Control = column.scroll_layer
	var top_left: Vector2 = window.global_position - global_position
	return top_left + Vector2(
			window.size.x * 0.5,
			row * Reel.SYMBOL_HEIGHT + Reel.SYMBOL_HEIGHT * 0.5)
