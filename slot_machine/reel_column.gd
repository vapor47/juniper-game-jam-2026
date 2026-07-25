extends Control
class_name ReelColumn
## One column: a Reel (§7/§8, pooled scrolling cells) inside a clipping
## ScrollLayer, plus a static CellOverlay for future payline hit-testing/
## highlighting (Phase 2+) that never scrolls. Holds are whole-column state.

## Visual state of a single cell, driven by the payline UI (§9).
enum CellState { NEUTRAL, DIMMED, ON_LINE, IN_RUN }

const _STATE_COLORS := {
	CellState.NEUTRAL: Color(1, 1, 1, 0),
	CellState.DIMMED: Color(0, 0, 0, 0.62),
	CellState.ON_LINE: Color(1, 0.85, 0.3, 0.30),
	CellState.IN_RUN: Color(1, 0.85, 0.3, 0.60),
}

@onready var hold_button: Button = %HoldButton
@onready var scroll_layer: Control = %ScrollLayer

var reel: Reel
var held: bool = false:
	set(value):
		held = value
		hold_button.button_pressed = value
		_refresh_hold_treatment()

var _cell_overlay: Control
var _cell_panels: Array[Panel] = []


func _ready() -> void:
	# The reel is the column's whole visual body — without a real minimum the
	# VBoxContainer reports zero width and every column collapses.
	custom_minimum_size.x = Reel.SYMBOL_WIDTH
	scroll_layer.custom_minimum_size = Vector2(
			Reel.SYMBOL_WIDTH, Reel.SYMBOL_HEIGHT * Reel.VISIBLE_ROWS)

	reel = Reel.new()
	reel.strip = Global.strip
	scroll_layer.add_child(reel)
	reel.set_anchors_preset(Control.PRESET_FULL_RECT)

	_build_cell_overlay()

	hold_button.toggled.connect(func(pressed: bool) -> void: held = pressed)


## Three neutral row markers at fixed row positions, matching Reel.SYMBOL_HEIGHT.
## Game logic (payline membership, hover highlight, hit-testing) attaches
## here in Phase 2+ — never to the scrolling cells.
## Anchored horizontally so the markers track the column's real width.
func _build_cell_overlay() -> void:
	_cell_overlay = Control.new()
	_cell_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_layer.add_child(_cell_overlay)
	_cell_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	for row in Reel.VISIBLE_ROWS:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cell_overlay.add_child(panel)
		panel.anchor_left = 0.0
		panel.anchor_right = 1.0
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = row * Reel.SYMBOL_HEIGHT
		panel.offset_bottom = (row + 1) * Reel.SYMBOL_HEIGHT
		_cell_panels.append(panel)
		set_cell_state(row, CellState.NEUTRAL)


func set_cell_state(row: int, state: CellState) -> void:
	if row < 0 or row >= _cell_panels.size():
		return
	var box := StyleBoxFlat.new()
	box.bg_color = _STATE_COLORS[state]
	if state == CellState.IN_RUN:
		box.border_width_left = 3
		box.border_width_right = 3
		box.border_width_top = 3
		box.border_width_bottom = 3
		box.border_color = Color(1, 0.9, 0.45, 0.95)
	_cell_panels[row].add_theme_stylebox_override("panel", box)


func clear_cell_states() -> void:
	for row in _cell_panels.size():
		set_cell_state(row, CellState.NEUTRAL)


## Holds read as a column-level treatment, not a per-cell one (§7).
func _refresh_hold_treatment() -> void:
	if scroll_layer:
		scroll_layer.modulate = Color(0.72, 0.85, 1.0) if held else Color.WHITE


## No-ops when held — held columns simply never get spin_to called (§5).
func spin(target_stop: int) -> void:
	if held:
		return
	await reel.spin_to(target_stop)


func get_stop_at_row(row: int) -> Stop:
	return reel.visible_stops()[row]
