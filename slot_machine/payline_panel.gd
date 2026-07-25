extends PanelContainer
class_name PaylinePanel
## §9 board-reading UI: the list of owned lines. Hovering a row previews that
## line's outcome, and traces its path on the board.
##
## The readout itself lives in PaylineSummaryPanel, a fixed-size box above this
## one. Keeping it out of this container is what stops hover from resizing the
## list and shuffling rows out from under the cursor.
##
## The readout states what the selected lines pay, and nothing else — the
## enemy's intent is shown on the enemy, and weighing one against the other is
## the player's decision to make.

signal line_clicked(payline: Payline)
signal line_hovered(payline: Payline)  # null when nothing hovered

const ROW_BG_SELECTED := Color(1, 0.85, 0.3, 0.16)

@onready var _readout: PaylineSummaryPanel = %PaylineSummary

var _rows: Array[Control] = []
var _list: VBoxContainer

# Last state handed to refresh(), kept so hovering can re-derive the preview
# without rebuilding the rows — rebuilding would free the button under the
# cursor and its mouse_exited would never fire.
var _owned: Array[Payline] = []
var _selected: Array[Payline] = []
var _columns: Array[ReelColumn] = []
var _costs: Dictionary = {}
var _hovered: Payline = null
var _interactive: bool = false


func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var header := Label.new()
	header.text = "PAYLINES"
	root.add_child(header)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	root.add_child(_list)


## Rebuilds the list. `costs` maps a payline to what clicking it costs right
## now (0 = free, negative = refund on deselect).
func refresh(owned: Array[Payline], selected: Array[Payline],
		columns: Array[ReelColumn], costs: Dictionary) -> void:
	_owned = owned
	_selected = selected
	_columns = columns
	_costs = costs
	if _hovered != null and _hovered not in owned:
		_hovered = null

	for row in _rows:
		row.queue_free()
	_rows.clear()

	for payline: Payline in PaylineCatalog.sorted_for_display(owned):
		_rows.append(_build_row(payline, selected))

	_update_summary()


## Selection is post-spin (§4): there's nothing to read or judge until the
## reels settle, so the whole panel greys out and stops responding until then.
func set_interactive(value: bool) -> void:
	_interactive = value
	if not value:
		_hovered = null
	modulate = Color(1, 1, 1, 1.0 if value else 0.4)
	for row in _rows:
		(row as Button).disabled = not value
	_update_summary()


## Hovering previews the outcome, so a line can be judged before committing
## tokens to it. Only the summary changes — the rows stay put.
func set_hovered(payline: Payline) -> void:
	if not _interactive or _hovered == payline:
		return
	_hovered = payline
	_update_summary()


func _update_summary() -> void:
	if _readout == null:
		return
	if not _interactive:
		_readout.set_content("Spinning…", "")
		return
	if _hovered != null:
		_show_line_preview(_hovered)
	else:
		_show_selection_summary()


## Just the line's name. Per-line numbers live in the summary below the list
## and on the board itself (hover traces the path, cells glow), so repeating
## them on every row was noise.
func _build_row(payline: Payline, selected: Array[Payline]) -> Control:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 30
	button.text = payline.display_name
	button.disabled = not _interactive

	if payline in selected:
		var box := StyleBoxFlat.new()
		box.bg_color = ROW_BG_SELECTED
		button.add_theme_stylebox_override("normal", box)

	_list.add_child(button)

	button.pressed.connect(func() -> void:
		if _interactive:
			line_clicked.emit(payline))
	button.mouse_entered.connect(func() -> void:
		if not _interactive:
			return
		set_hovered(payline)
		line_hovered.emit(payline))
	button.mouse_exited.connect(func() -> void:
		set_hovered(null)
		line_hovered.emit(null))
	return button


## What the selected lines resolve to. Nothing about the enemy's intent: the
## readout states the outcome, and judging it against the incoming hit is the
## player's call.
func _show_selection_summary() -> void:
	if _selected.is_empty():
		_readout.set_content("No line selected", "")
		return

	_readout.set_content(
			"Playing %d line%s" % [_selected.size(), "" if _selected.size() == 1 else "s"],
			_outcome_text(_selected))


## What this line pays, on its own.
func _show_line_preview(payline: Payline) -> void:
	var tag := "selected"
	if payline not in _selected:
		var cost: int = _costs.get(payline, 0)
		tag = "free" if cost <= 0 else "%d tokens" % cost

	_readout.set_content("%s — %s" % [payline.display_name, tag],
			_outcome_text([payline] as Array[Payline]))


func _outcome_text(lines: Array[Payline]) -> String:
	var text := "%d ATK · %d BLK" % [
			PaylineEvaluator.total_attack(lines, _columns),
			PaylineEvaluator.total_block(lines, _columns)]

	var heal := 0
	for line: Payline in lines:
		heal += PaylineEvaluator.score_for(line, _columns).heal
	if heal > 0:
		text += " · %d HEAL" % heal

	var match_bits := _match_text(lines)
	if not match_bits.is_empty():
		text += "\n" + match_bits
	return text


func _match_text(lines: Array[Payline]) -> String:
	var bits: Array[String] = []
	for line: Payline in lines:
		for run: PaylineScorer.Run in PaylineEvaluator.score_for(line, _columns).matched_runs():
			bits.append("%s x%d matched (+%d)" % [run.symbol.symbol_name, run.count, run.bonus])
	return "\n".join(bits)
