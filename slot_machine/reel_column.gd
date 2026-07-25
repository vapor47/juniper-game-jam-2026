extends Control
class_name ReelColumn
## One column: a Reel (§7/§8, pooled scrolling cells) inside a clipping
## ScrollLayer, plus a static CellOverlay for future payline hit-testing/
## highlighting (Phase 2+) that never scrolls. Holds are whole-column state.

## Visual state of a single cell, driven by the payline UI (§9).
enum CellState { NEUTRAL, DIMMED, ON_LINE, IN_RUN }

const GLOW_COLOR := Color(1.0, 0.87, 0.25)
const DIM_COLOR := Color(0, 0, 0, 0.62)

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


## This is a plain Control whose children are anchor-positioned, so it does
## not derive a minimum size from them on its own — report the VBox's instead.
## Without this the column collapses to nothing whenever an ancestor stops
## forcing a size, and the clipped reel draws outside its container.
func _get_minimum_size() -> Vector2:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox:
		return (vbox as Control).get_combined_minimum_size()
	return Vector2(Reel.SYMBOL_WIDTH, Reel.SYMBOL_HEIGHT * Reel.VISIBLE_ROWS)


func _ready() -> void:
	scroll_layer.custom_minimum_size = Vector2(
			Reel.SYMBOL_WIDTH, Reel.SYMBOL_HEIGHT * Reel.VISIBLE_ROWS)
	update_minimum_size()

	reel = Reel.new()
	reel.strip = Global.strip
	scroll_layer.add_child(reel)
	reel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
	# Anchors alone leave the offsets untouched, which collapses this to zero
	# width — the row panels then draw their border as an invisible sliver.
	_cell_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for row in Reel.VISIBLE_ROWS:
		var panel := Panel.new()
		# STOP, per §7: these panels are the hit-test targets for the cells.
		# They never scroll, so they stay put while symbols move under them.
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_cell_overlay.add_child(panel)
		panel.anchor_left = 0.0
		panel.anchor_right = 1.0
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = row * Reel.SYMBOL_HEIGHT
		panel.offset_bottom = (row + 1) * Reel.SYMBOL_HEIGHT
		_cell_panels.append(panel)
		set_cell_state(row, CellState.NEUTRAL)

		# Per-stop inspection. The callable is re-evaluated every frame, so
		# the readout follows whatever symbol currently occupies this row.
		var this_row := row
		panel.mouse_entered.connect(func() -> void:
			HoverLabel.show_for(panel, func() -> String: return _stop_tooltip(this_row)))
		panel.mouse_exited.connect(func() -> void: HoverLabel.hide_for(panel))


## Cells on a payline read as a glowing yellow border — never a wash of colour
## over the symbol, which would fight the thing you're trying to read.
func set_cell_state(row: int, state: CellState) -> void:
	if row < 0 or row >= _cell_panels.size():
		return
	_cell_panels[row].add_theme_stylebox_override("panel", _style_for(state))


func _style_for(state: CellState) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.anti_aliasing = true

	match state:
		CellState.DIMMED:
			box.draw_center = true
			box.bg_color = DIM_COLOR
		CellState.ON_LINE:
			_apply_glow(box, 2, Color(GLOW_COLOR, 0.9), 7, 0.30)
		CellState.IN_RUN:
			_apply_glow(box, 3, Color(GLOW_COLOR, 1.0), 12, 0.55)
		_:
			pass  # NEUTRAL: nothing drawn
	return box


func _apply_glow(box: StyleBoxFlat, width: int, color: Color,
		glow_size: int, glow_alpha: float) -> void:
	box.border_width_left = width
	box.border_width_right = width
	box.border_width_top = width
	box.border_width_bottom = width
	box.border_color = color
	box.set_corner_radius_all(3)
	# StyleBoxFlat's shadow, centred and un-offset, reads as a soft halo.
	box.shadow_color = Color(GLOW_COLOR, glow_alpha)
	box.shadow_size = glow_size
	box.shadow_offset = Vector2.ZERO


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


## Just this cell's effect, e.g. "4 damage". Blank while the reels are moving —
## the symbol under the cursor changes several times a second mid-spin.
func _stop_tooltip(row: int) -> String:
	if reel == null or reel.strip.is_empty() or reel.is_spinning():
		return ""

	var symbol := get_stop_at_row(row).symbol
	match symbol.type:
		Action.Type.ATTACK:
			return "%d damage" % symbol.value
		Action.Type.DEFEND:
			return "%d block" % symbol.value
		Action.Type.HEAL:
			return "%d heal" % symbol.value
		_:
			return "No effect"
