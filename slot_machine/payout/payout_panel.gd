extends PanelContainer
class_name PayoutPanel
## The paytable: every symbol on the strip, and what a run of it pays.
##
## This exists because the action summary was doing too much work. A player
## reading only "22 ATK · 8 BLK" has no reason to look at the cells, and
## without looking at the cells there is nothing to decide when holding. The
## paytable puts the value structure somewhere it can be checked, so the board
## becomes readable on its own terms.
##
## Every number here is computed by PaylineScorer, never written down. A table
## that drifts from what the machine actually pays is worse than no table, and
## the run bonus gets retuned often enough for drift to be the default outcome.
##
## Rows are built from the live strip, so a symbol appears exactly when the
## player owns one — the table doubles as an inventory of what they've built
## without ever saying so.

const MAX_RUN := 5
const SWATCH_SIZE := Vector2(104, 40)
const HEADER_COLOR := Color(0.62, 0.62, 0.66)
const VALUE_COLOR := Color(0.92, 0.92, 0.92)
const DEAD_COLOR := Color(0.42, 0.42, 0.45)
const GOLD_COLOR := Color(0.95, 0.82, 0.35)

@onready var payout_container: MarginContainer = $PayoutContainer

signal panel_updated


func _ready() -> void:
	build_legend()


## Distinct symbols on the strip, ordered so like sits with like: by action
## type, then by value, matching how the board reads.
static func _strip_symbols() -> Array[Symbol]:
	var seen: Array[Symbol] = []
	for stop: Stop in Global.strip:
		if stop.symbol not in seen:
			seen.append(stop.symbol)
	seen.sort_custom(func(a: Symbol, b: Symbol) -> bool:
		if a.type != b.type:
			return a.type < b.type
		return a.value < b.value)
	return seen


func build_legend() -> void:
	for child in payout_container.get_children():
		payout_container.remove_child(child)
		child.queue_free()

	var line_symbols: Array[Symbol] = []
	var board_symbols: Array[Symbol] = []
	for symbol: Symbol in _strip_symbols():
		if symbol.trigger != Symbol.Trigger.NONE:
			board_symbols.append(symbol)
		else:
			line_symbols.append(symbol)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)

	if not line_symbols.is_empty():
		root.add_child(_section("PER LINE"))
		root.add_child(_run_table(line_symbols))
	if not board_symbols.is_empty():
		root.add_child(_section("ON THE BOARD"))
		root.add_child(_board_table(board_symbols))

	payout_container.add_child(root)
	panel_updated.emit()


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", HEADER_COLOR)
	return label


## Symbol down the side, run length across the top, payout in the cells.
func _run_table(symbols: Array[Symbol]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = MAX_RUN + 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)

	grid.add_child(Control.new())  # corner, above the swatch column
	for n in range(1, MAX_RUN + 1):
		grid.add_child(_cell("x%d" % n, HEADER_COLOR, HORIZONTAL_ALIGNMENT_CENTER, 13))

	for symbol: Symbol in symbols:
		grid.add_child(_swatch(symbol))
		for n in range(1, MAX_RUN + 1):
			grid.add_child(_payout_cell(symbol, n))
	return grid


## What a run of n pays, straight from the scorer. Wild has no payout of its
## own — it takes the value of whatever it lands beside — so its row says that
## rather than inventing numbers for it.
func _payout_cell(symbol: Symbol, n: int) -> Control:
	if symbol.is_wild:
		return _cell("=" if n == 1 else "", DEAD_COLOR, HORIZONTAL_ALIGNMENT_CENTER)

	if not symbol.payout.is_empty():
		if not symbol.payout.has(n):
			return _cell("-", DEAD_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
		var pay: Array = symbol.payout[n]
		var parts := PackedStringArray()
		if int(pay[0]) > 0:
			parts.append("%dT" % int(pay[0]))
		if int(pay[1]) > 0:
			parts.append("%dg" % int(pay[1]))
		return _cell(" ".join(parts), GOLD_COLOR, HORIZONTAL_ALIGNMENT_CENTER)

	if symbol.type == Action.Type.NONE or n < symbol.min_run:
		return _cell("-", DEAD_COLOR, HORIZONTAL_ALIGNMENT_CENTER)

	var value := PaylineScorer.run_value(symbol, n)
	if value == 0:
		return _cell("-", DEAD_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	return _cell(str(value), VALUE_COLOR, HORIZONTAL_ALIGNMENT_CENTER)


## Symbols that pay off the grid rather than off a line, where a run-length
## column would mean nothing.
func _board_table(symbols: Array[Symbol]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	for symbol: Symbol in symbols:
		grid.add_child(_swatch(symbol))
		var per := SymbolTable.CHIP_GOLD_PER_COPY if symbol == SymbolTable.CHIP \
			else SymbolTable.PENNY_GOLD_PER_COPY
		var when := "on lock" if symbol.trigger == Symbol.Trigger.ON_LOCK else "each spin"
		grid.add_child(_cell("%dg per copy, %s" % [per, when], GOLD_COLOR,
			HORIZONTAL_ALIGNMENT_LEFT))
	return grid


## Carries the board's own colour and headline, so a row is recognisably the
## same object as a cell without the name having to be read.
func _swatch(symbol: Symbol) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SWATCH_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = SymbolCell.color_for(symbol)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var headline := Label.new()
	headline.text = SymbolCell.headline(symbol)
	headline.add_theme_font_size_override("font_size", 20)
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(headline)

	var name_label := Label.new()
	name_label.text = symbol.symbol_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	return panel


func _cell(text: String, color: Color, align: int, font_size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
