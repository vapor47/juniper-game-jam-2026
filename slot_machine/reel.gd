extends Control
class_name Reel
## §7/§8: one tween driving one float (scroll_pos). Everything visual derives
## from it. Built entirely in code — no scene file — matching the doc's
## reference implementation. strip is shared (Global.strip), not per-instance.

signal spin_finished(stops: Array[Stop])

const VISIBLE_ROWS: int = 3
const BUFFER: int = 1
const POOL_SIZE: int = VISIBLE_ROWS + BUFFER * 2
const SYMBOL_WIDTH: float = 144.0
const SYMBOL_HEIGHT: float = 144.0
const EXTRA_LOOPS: int = 3
const SPIN_DURATION: float = 1.2
## A nudge is one stop, so it wants a short deliberate move rather than the
## spin's long settle — it reads as the machine being pushed, not thrown.
const NUDGE_DURATION: float = 0.22
const CURVATURE_SPINNING: float = 0.28
const CURVATURE_RESTING: float = 0.06

var strip: Array[Stop] = []:
	set(value):
		strip = value
		_layout()

var scroll_pos: float = 0.0:
	set(value):
		scroll_pos = value
		_layout()

var curvature: float = CURVATURE_RESTING:
	set(value):
		curvature = value
		_layout()

var _cells: Array[SymbolCell] = []
var _spin_tween: Tween


func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(SYMBOL_WIDTH, SYMBOL_HEIGHT * VISIBLE_ROWS)
	for i in POOL_SIZE:
		var cell := SymbolCell.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cell)
		_cells.append(cell)
	# Cells span the reel's actual width, which isn't known until layout runs.
	resized.connect(_layout)
	_layout()


func is_spinning() -> bool:
	return _spin_tween != null and _spin_tween.is_valid() and _spin_tween.is_running()


## Center-row strip index at rest.
func current_stop() -> int:
	return wrapi(int(floor(scroll_pos)), 0, strip.size())


## The three stops occupying the payline rows, top to bottom.
func visible_stops() -> Array[Stop]:
	var out: Array[Stop] = []
	var base: int = int(floor(scroll_pos))
	for row: int in range(-1, 2):
		out.append(strip[wrapi(base + row, 0, strip.size())])
	return out


func spin_to(target_stop: int) -> void:
	if strip.is_empty():
		return
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()

	# Decreasing scroll_pos walks the window backwards through the strip, which
	# reads on screen as symbols rolling DOWNWARD. `backward` is the shortest
	# backward distance, so the reel never reverses mid-spin, and the whole
	# revolutions are purely for show.
	var from: int = int(floor(scroll_pos))
	var backward: int = wrapi(from - target_stop, 0, strip.size())
	var target: float = float(from - EXTRA_LOOPS * strip.size() - backward)

	_spin_tween = create_tween()
	_spin_tween.set_parallel(true)
	_spin_tween.tween_property(self, "scroll_pos", target, SPIN_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_spin_tween.tween_property(self, "curvature", CURVATURE_SPINNING, SPIN_DURATION * 0.15)
	_spin_tween.chain().tween_property(self, "curvature", CURVATURE_RESTING, SPIN_DURATION * 0.35)

	await _spin_tween.finished
	scroll_pos = float(wrapi(int(target), 0, strip.size()))
	spin_finished.emit(visible_stops())


## Shifts the window exactly one stop. Deterministic where spin_to is not:
## the whole point is that a player who knows their strip order knows what is
## about to come into view.
##
## Tweens to the raw unwrapped target and normalises afterwards. Tweening
## straight to a wrapped index would scroll the long way round the strip —
## 0 to 19 is one stop backwards, but nineteen stops forwards to a tween.
func nudge(delta: int) -> void:
	if strip.is_empty():
		return
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()

	var target: float = scroll_pos + float(delta)
	_spin_tween = create_tween()
	_spin_tween.tween_property(self, "scroll_pos", target, NUDGE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await _spin_tween.finished
	scroll_pos = float(wrapi(int(round(target)), 0, strip.size()))
	spin_finished.emit(visible_stops())


func _layout() -> void:
	if strip.is_empty() or _cells.is_empty():
		return

	var base: int = int(floor(scroll_pos))
	var frac: float = scroll_pos - float(base)
	var center_y: float = SYMBOL_HEIGHT * VISIBLE_ROWS * 0.5
	var half_window: float = center_y + SYMBOL_HEIGHT

	for i in POOL_SIZE:
		var row: int = i - BUFFER - 1
		var cell: SymbolCell = _cells[i]
		cell.stop = strip[wrapi(base + row, 0, strip.size())]

		cell.size = Vector2(size.x, SYMBOL_HEIGHT)
		cell.pivot_offset = Vector2(size.x * 0.5, SYMBOL_HEIGHT * 0.5)

		var offset: float = (float(row) - frac) * SYMBOL_HEIGHT
		var norm: float = clampf(offset / half_window, -1.0, 1.0)
		var squeeze: float = 1.0 - curvature * norm * norm

		cell.position.x = 0.0
		cell.position.y = center_y + offset * squeeze - SYMBOL_HEIGHT * 0.5
		cell.scale.y = squeeze
