extends Control
class_name PaylineGlyph
## Tiny 3x5 render of a line's shape, so patterns are visually distinct at a
## glance (§4 legibility requirement). Optionally shows cells shared with
## already-owned lines, which is the concentrate-vs-spread read.

const DOT_RADIUS := 2.0
const CELL := Vector2(9, 8)
const LINE_COLOR := Color(1, 0.85, 0.3, 0.95)
const SHARED_COLOR := Color(0.45, 0.85, 1.0, 1.0)
const EMPTY_COLOR := Color(1, 1, 1, 0.18)

var payline: Payline:
	set(value):
		payline = value
		queue_redraw()

## Columns whose cell is shared with another owned line — drawn hot.
var shared_columns: Dictionary = {}:
	set(value):
		shared_columns = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(CELL.x * 5, CELL.y * 3)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if payline == null:
		return

	var origin := (size - Vector2(CELL.x * 5, CELL.y * 3)) * 0.5

	for col in 5:
		for row in 3:
			var c := origin + Vector2((col + 0.5) * CELL.x, (row + 0.5) * CELL.y)
			draw_circle(c, DOT_RADIUS * 0.6, EMPTY_COLOR)

	var points := PackedVector2Array()
	for col in mini(payline.pattern.size(), 5):
		var row: int = payline.row_at(col)
		points.append(origin + Vector2((col + 0.5) * CELL.x, (row + 0.5) * CELL.y))

	if points.size() >= 2:
		draw_polyline(points, LINE_COLOR, 1.5, true)

	for col in points.size():
		var hot: bool = shared_columns.get(col, false)
		draw_circle(points[col], DOT_RADIUS, SHARED_COLOR if hot else LINE_COLOR)
