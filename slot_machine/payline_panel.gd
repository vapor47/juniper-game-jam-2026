extends PanelContainer
class_name PaylinePanel
## §9 board-reading UI. A persistent compact list of owned lines with ATK/BLK
## always visible — hover is reserved for showing the *path* on the board,
## because hover-only comparison is slow across many candidates (and absent
## on touch).
##
## Totals shown are *marginal* once something is already selected: with
## double-dip, attack is additive but block is capped by intent and overflow
## is wasted, so a standalone block number can be actively misleading (§9).

signal line_clicked(payline: Payline)
signal line_hovered(payline: Payline)  # null when nothing hovered

const ROW_BG_SELECTED := Color(1, 0.85, 0.3, 0.16)
const ROW_BG_HOVER := Color(1, 1, 1, 0.07)

var _rows: Array[Control] = []
var _list: VBoxContainer
var _summary: Label
var _intent_label: Label


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

	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_summary)

	_intent_label = Label.new()
	root.add_child(_intent_label)


## Rebuilds the list. `costs` maps a payline to what clicking it costs right
## now (0 = free, negative = refund on deselect).
func refresh(owned: Array[Payline], selected: Array[Payline],
		columns: Array[ReelColumn], incoming: int, costs: Dictionary) -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()

	for payline: Payline in owned:
		_rows.append(_build_row(payline, selected, columns, incoming, costs))

	_refresh_summary(selected, columns, incoming)


## Just the line's name. Per-line numbers live in the summary below the list
## and on the board itself (hover traces the path, cells glow), so repeating
## them on every row was noise.
func _build_row(payline: Payline, selected: Array[Payline], _columns: Array[ReelColumn],
		_incoming: int, _costs: Dictionary) -> Control:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 30
	button.text = payline.display_name

	if payline in selected:
		var box := StyleBoxFlat.new()
		box.bg_color = ROW_BG_SELECTED
		button.add_theme_stylebox_override("normal", box)

	_list.add_child(button)

	button.pressed.connect(func() -> void: line_clicked.emit(payline))
	button.mouse_entered.connect(func() -> void: line_hovered.emit(payline))
	button.mouse_exited.connect(func() -> void: line_hovered.emit(null))
	return button


func _refresh_summary(selected: Array[Payline], columns: Array[ReelColumn], incoming: int) -> void:
	if selected.is_empty():
		_summary.text = "Select a line to play."
		_intent_label.text = ""
		return

	var attack := PaylineEvaluator.total_attack(selected, columns)
	var block := PaylineEvaluator.total_block(selected, columns)

	var match_bits: Array[String] = []
	for line: Payline in selected:
		for run: PaylineScorer.Run in PaylineEvaluator.score_for(line, columns).matched_runs():
			match_bits.append("%s x%d (+%d)" % [run.symbol.symbol_name, run.count, run.bonus])

	_summary.text = "%d ATK · %d BLK" % [attack, block]
	if not match_bits.is_empty():
		_summary.text += "\n" + "\n".join(match_bits)

	# Block reads as a comparison against the hit, never a raw number (§9).
	if incoming > 0:
		var delta := block - incoming
		if delta >= 0:
			_intent_label.text = "BLOCK %d / %d  (covered, %d wasted)" % [block, incoming, delta]
		else:
			_intent_label.text = "BLOCK %d / %d  (%d)" % [block, incoming, delta]
	else:
		_intent_label.text = "BLOCK %d" % block
