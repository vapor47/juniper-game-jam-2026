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


func _build_row(payline: Payline, selected: Array[Payline], columns: Array[ReelColumn],
		incoming: int, costs: Dictionary) -> Control:
	var is_selected := payline in selected
	var result := PaylineEvaluator.score_for(payline, columns)

	var button := Button.new()
	button.flat = true
	button.toggle_mode = false
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 34
	if is_selected:
		var box := StyleBoxFlat.new()
		box.bg_color = ROW_BG_SELECTED
		button.add_theme_stylebox_override("normal", box)
	_list.add_child(button)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(hbox)

	var glyph := PaylineGlyph.new()
	glyph.payline = payline
	glyph.shared_columns = _shared_columns(payline, selected)
	hbox.add_child(glyph)

	var name_label := Label.new()
	name_label.text = payline.display_name
	name_label.custom_minimum_size.x = 96
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_label)

	var totals := Label.new()
	totals.text = _totals_text(payline, result, selected, columns, incoming, is_selected)
	totals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(totals)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

	var cost_label := Label.new()
	var cost: int = costs.get(payline, 0)
	if is_selected:
		cost_label.text = "SELECTED"
	elif cost <= 0:
		cost_label.text = "FREE"
	else:
		cost_label.text = "%d tok" % cost
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(cost_label)

	button.pressed.connect(func() -> void: line_clicked.emit(payline))
	button.mouse_entered.connect(func() -> void: line_hovered.emit(payline))
	button.mouse_exited.connect(func() -> void: line_hovered.emit(null))
	return button


## Attack is additive under double-dip, so marginal == standalone. Block is
## only worth what the intent doesn't already have covered.
func _totals_text(payline: Payline, result: PaylineScorer.LineResult,
		selected: Array[Payline], columns: Array[ReelColumn],
		incoming: int, is_selected: bool) -> String:
	if is_selected or selected.is_empty():
		return "%d ATK · %d BLK" % [result.attack, result.block]

	var marginal := PaylineEvaluator.marginal_block(payline, selected, columns, incoming)
	if marginal == result.block:
		return "%d ATK · %d BLK" % [result.attack, result.block]
	return "+%d ATK · +%d BLK (of %d)" % [result.attack, marginal, result.block]


func _shared_columns(payline: Payline, selected: Array[Payline]) -> Dictionary:
	var shared := {}
	for other: Payline in selected:
		if other == payline:
			continue
		for col in payline.pattern.size():
			if payline.row_at(col) == other.row_at(col):
				shared[col] = true
	return shared


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
