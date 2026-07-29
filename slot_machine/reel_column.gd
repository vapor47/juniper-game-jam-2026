extends Control
class_name ReelColumn
## One column: a Reel (§7/§8, pooled scrolling cells) inside a clipping
## ScrollLayer, plus a static CellOverlay for future payline hit-testing/
## highlighting (Phase 2+) that never scrolls. Holds are whole-column state.

## Visual state of a single cell, driven by the payline UI (§9).
enum CellState { NEUTRAL, DIMMED, ON_LINE, IN_RUN }

const GLOW_COLOR := Color(1.0, 0.87, 0.25)
const DIM_COLOR := Color(0, 0, 0, 0.62)

signal nudge_requested(column: ReelColumn, delta: int)

## Symbols move down the screen, which is a *decreasing* scroll_pos — the same
## direction a spin travels.
const NUDGE_DOWN := -1
const NUDGE_UP := 1
## Gap between the reel window and an arrow. The room for them comes from
## GridFrame's margins above and the column VBox's separation below, so the
## arrows never sit on the cells, the health bar, or the hold button.
const NUDGE_GAP := 6.0

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
## Named by position, not direction — the two disagree on purpose, see
## _build_nudge_controls.
var _nudge_top: Button
var _nudge_bottom: Button
var _nudging_available: bool = false
var _hovered: bool = false


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
	_build_nudge_controls()


## Two arrows, one above the reel window and one below it. Hidden unless the
## player owns a nudge *and* the cursor is on this column — with five columns,
## ten permanently visible arrows is a wall of chrome for a verb used three
## times a fight.
## Each arrow is labelled and wired by where the incoming symbol appears, not by
## which way the reel travels. The top arrow pushes the reel *down*, so the stop
## above slides into view — clicking the top of a column reads as "show me
## what's up there", and the glyph points the way the reel will move.
##
## The opposite mapping was tried first and is genuinely confusing: pressing the
## top arrow changed the bottom cell.
func _build_nudge_controls() -> void:
	_nudge_top = _make_nudge_button("▼", NUDGE_DOWN)
	_nudge_bottom = _make_nudge_button("▲", NUDGE_UP)
	set_nudging_available(false)


func _make_nudge_button(glyph: String, delta: int) -> Button:
	var button := Button.new()
	button.text = glyph
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(34, 20)
	button.add_theme_font_size_override("font_size", 12)
	add_child(button)
	button.pressed.connect(func() -> void: nudge_requested.emit(self, delta))
	return button


## Placed off the reel window's own rect rather than the column's. The column
## also contains the hold button, so anchoring to its bottom put the down arrow
## on top of HOLD, and anchoring to its top put the up arrow over the first row
## of cells.
func _place_nudge_controls() -> void:
	if _nudge_top == null or scroll_layer == null:
		return
	var top: float = scroll_layer.global_position.y - global_position.y
	var centre: float = (size.x - _nudge_top.size.x) * 0.5
	_nudge_top.position = Vector2(centre, top - NUDGE_GAP - _nudge_top.size.y)
	_nudge_bottom.position = Vector2(centre, top + scroll_layer.size.y + NUDGE_GAP)


func set_nudging_available(available: bool) -> void:
	_nudging_available = available
	_refresh_nudge_visibility()


## Rect containment rather than mouse_entered: the cell panels above the reel
## take mouse input for their tooltips, so the column itself never sees an
## enter event, and the arrows are children too — leaving the column to press
## one would count as an exit.
func _process(_delta: float) -> void:
	if _nudge_top == null or not _nudging_available:
		return
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	if hovered != _hovered:
		_hovered = hovered
		_refresh_nudge_visibility()


func _refresh_nudge_visibility() -> void:
	if _nudge_top == null:
		return
	var show_arrows := _nudging_available and _hovered
	_nudge_top.visible = show_arrows
	_nudge_bottom.visible = show_arrows
	if not show_arrows:
		return
	_place_nudge_controls()
	var usable := can_nudge()
	_nudge_top.disabled = not usable
	_nudge_bottom.disabled = not usable


## Jammed columns are out of the player's hands by design, and a held column
## has to be released first — holding reads as the column being fixed in place,
## so letting a nudge move it anyway would contradict the verb.
func can_nudge() -> bool:
	return not jammed and not held and reel != null and not reel.is_spinning()


func nudge(delta: int) -> void:
	if not can_nudge():
		return
	await reel.nudge(delta)


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
## Frozen by a Reel Jam showing in this column. Distinct from `held`, which is
## the player's own choice — a jam has to survive the player clicking at it, and
## has to clear on its own next spin.
var jammed: bool = false:
	set(value):
		jammed = value
		if jammed:
			held = true
		if hold_button != null:
			hold_button.disabled = hold_button.disabled or jammed


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
	if symbol.is_wild:
		return "Wild"
	if not symbol.payout.is_empty():
		return "%d in a row pays" % symbol.min_run
	if symbol == SymbolTable.CHIP:
		return "%d gold" % SymbolTable.CHIP_GOLD_PER_COPY
	return symbol.describe()
