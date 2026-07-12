extends Control
class_name ReelWheelDisplay
## Draws a reel as a top-down donut wheel. Pure view + input component:
## reports indices via signals, NEVER mutates the reel.
## Reused by: shop edit flow (interactive modes) and reel preview (VIEW mode).

signal wedge_clicked(stop_index: int)
signal insertion_clicked(insert_index: int)
signal wedge_hovered(stop_index: int)  # -1 when nothing hovered

enum WheelMode { VIEW, SELECT_STOP, SELECT_INSERTION }

const INNER_RADIUS_RATIO := 0.35
const EDGE_PADDING := 8.0
const ICON_SIZE := Vector2(28, 28)
const ICON_RADIUS_RATIO := 0.82        # icons sit near outer edge
const ARC_SEGMENTS_PER_WEDGE := 12
const INSERTION_ZONE_RATIO := 0.4      # hit zone spans 40% of a wedge angle
const PART_ANGLE := deg_to_rad(2.5)    # wedge "parting" on hovered insertion
const BOUNDARY_COLOR := Color(0.1, 0.1, 0.1, 0.9)
const HOVER_BRIGHTEN := 0.25

var reel: Reel
var mode: WheelMode = WheelMode.VIEW:
	set(value):
		mode = value
		_hovered_wedge = -1
		_hovered_insertion = -1
		queue_redraw()

## Spin offset in radians. Tween this for browse/spin animation;
## hit-testing stays exact at any rotation.
var wheel_rotation: float = 0.0:
	set(value):
		wheel_rotation = value
		queue_redraw()

var _hovered_wedge: int = -1
var _hovered_insertion: int = -1


func setup(p_reel: Reel) -> void:
	reel = p_reel
	if is_inside_tree():
		queue_redraw()


func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)


# ---------------------------------------------------------------- geometry

func _center() -> Vector2:
	return size / 2.0

func _outer_radius() -> float:
	return minf(size.x, size.y) / 2.0 - EDGE_PADDING

func _inner_radius() -> float:
	return _outer_radius() * INNER_RADIUS_RATIO

func _wedge_angle() -> float:
	return TAU / reel.reel_stops.size()

## Screen position -> (dist, angle-in-wheel-space). Angle normalized [0, TAU),
## 0 at top, increasing clockwise, rotation offset removed.
func _to_polar(local_pos: Vector2) -> Vector2:
	var v := local_pos - _center()
	var angle := fposmod(v.angle() + PI / 2.0 - wheel_rotation, TAU)
	return Vector2(v.length(), angle)


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if reel == null or reel.reel_stops.is_empty():
		return

	if event is InputEventMouseMotion:
		_update_hover(_to_polar(event.position))
	elif event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click(_to_polar(event.position))


func _update_hover(polar: Vector2) -> void:
	var new_wedge := -1
	var new_insertion := -1

	if _in_ring(polar.x):
		match mode:
			WheelMode.SELECT_STOP, WheelMode.VIEW:
				new_wedge = _wedge_at(polar.y)
			WheelMode.SELECT_INSERTION:
				new_insertion = _insertion_at(polar.y)

	if new_wedge != _hovered_wedge or new_insertion != _hovered_insertion:
		_hovered_wedge = new_wedge
		_hovered_insertion = new_insertion
		wedge_hovered.emit(_hovered_wedge)
		queue_redraw()


func _handle_click(polar: Vector2) -> void:
	if not _in_ring(polar.x):
		return
	match mode:
		WheelMode.SELECT_STOP:
			wedge_clicked.emit(_wedge_at(polar.y))
		WheelMode.SELECT_INSERTION:
			var idx := _insertion_at(polar.y)
			if idx != -1:
				insertion_clicked.emit(idx)


func _in_ring(dist: float) -> bool:
	return dist >= _inner_radius() and dist <= _outer_radius()


func _wedge_at(angle: float) -> int:
	return int(angle / _wedge_angle()) % reel.reel_stops.size()


## Boundary b sits at angle b * wedge_angle, between wedge b-1 and wedge b.
## Returns b (the index new stop would be inserted at), or -1 if outside zone.
func _insertion_at(angle: float) -> int:
	var wa := _wedge_angle()
	var nearest := roundi(angle / wa) % reel.reel_stops.size()
	var diff := absf(angle - float(nearest) * wa)
	diff = minf(diff, TAU - diff)  # wraparound at 0/TAU
	if diff <= wa * INSERTION_ZONE_RATIO / 2.0:
		return nearest
	return -1


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if reel == null or reel.reel_stops.is_empty():
		return

	var wa := _wedge_angle()
	var n := reel.reel_stops.size()

	for i in n:
		var start := float(i) * wa
		var end := start + wa

		# part wedges adjacent to hovered insertion boundary
		if mode == WheelMode.SELECT_INSERTION and _hovered_insertion != -1:
			if i == _hovered_insertion:
				start += PART_ANGLE
			if (i + 1) % n == _hovered_insertion:
				end -= PART_ANGLE

		var color := _symbol_color(reel.reel_stops[i].slot_symbol)
		if i == _hovered_wedge and mode != WheelMode.VIEW:
			color = color.lightened(HOVER_BRIGHTEN)

		draw_colored_polygon(_arc_polygon(start, end), color)

	_draw_boundaries(wa, n)
	_draw_icons(wa, n)


func _arc_polygon(start_angle: float, end_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var c := _center()
	var inner := _inner_radius()
	var outer := _outer_radius()

	for s in ARC_SEGMENTS_PER_WEDGE + 1:
		var t := lerpf(start_angle, end_angle, float(s) / ARC_SEGMENTS_PER_WEDGE)
		points.append(c + _dir(t) * outer)
	for s in ARC_SEGMENTS_PER_WEDGE + 1:
		var t := lerpf(end_angle, start_angle, float(s) / ARC_SEGMENTS_PER_WEDGE)
		points.append(c + _dir(t) * inner)
	return points


## wheel-space angle -> screen direction (0 = up, clockwise, rotation applied)
func _dir(angle: float) -> Vector2:
	return Vector2.from_angle(angle - PI / 2.0 + wheel_rotation)


func _draw_boundaries(wa: float, n: int) -> void:
	var c := _center()
	for b in n:
		var angle := float(b) * wa
		var width := 2.0
		var color := BOUNDARY_COLOR

		if mode == WheelMode.SELECT_INSERTION:
			width = 5.0 if b == _hovered_insertion else 3.0
			color = Color.GOLD if b == _hovered_insertion else Color(0.9, 0.9, 0.9)

		draw_line(c + _dir(angle) * _inner_radius(),
				c + _dir(angle) * _outer_radius(), color, width)

		# "+" badge at outer edge of each boundary in insertion mode
		if mode == WheelMode.SELECT_INSERTION:
			var badge_pos := c + _dir(angle) * (_outer_radius() + 2.0)
			var r := 9.0 if b == _hovered_insertion else 7.0
			draw_circle(badge_pos, r, color)
			draw_line(badge_pos - Vector2(r * 0.5, 0), badge_pos + Vector2(r * 0.5, 0), Color.BLACK, 2.0)
			draw_line(badge_pos - Vector2(0, r * 0.5), badge_pos + Vector2(0, r * 0.5), Color.BLACK, 2.0)


func _draw_icons(wa: float, n: int) -> void:
	var c := _center()
	var icon_radius := _outer_radius() * ICON_RADIUS_RATIO
	for i in n:
		var icon: Texture2D = reel.reel_stops[i].slot_symbol.get_symbol_icon()
		if icon == null:
			continue
		var mid_angle := (float(i) + 0.5) * wa
		var pos := c + _dir(mid_angle) * icon_radius
		draw_texture_rect(icon, Rect2(pos - ICON_SIZE / 2.0, ICON_SIZE), false)


func _symbol_color(symbol: SlotSymbol) -> Color:
	# Base color by type, intensity could scale with symbol_value tier later.
	match symbol.get_symbol_type():
		SlotSymbol.SymbolType.ATTACK:
			return Color(0.75, 0.25, 0.22)
		SlotSymbol.SymbolType.DEFEND:
			return Color(0.24, 0.42, 0.72)
		_:
			return Color(0.3, 0.6, 0.35)  # heal / fallback


func _on_mouse_exited() -> void:
	if _hovered_wedge != -1 or _hovered_insertion != -1:
		_hovered_wedge = -1
		_hovered_insertion = -1
		wedge_hovered.emit(-1)
		queue_redraw()
