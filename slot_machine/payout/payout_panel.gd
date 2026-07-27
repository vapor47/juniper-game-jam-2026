extends PanelContainer
class_name PayoutPanel
## The paytable: what the symbols on the board are worth in a run.
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
## Rows are the symbols **on the board right now**, not everything on the strip.
## The strip's distinct-symbol count grows all run and the purchasable catalogue
## grows with development, so a strip-wide table gets longer forever. The board
## is 15 cells, so a board-wide table cannot exceed 15 rows no matter how many
## symbols the game ends up having. Measured over 20k spins, real occupancy is
## 7-10; the 15 is a ceiling, not an expectation.
##
## Ordering is pinned — type, then value, always. Rows entering and leaving as
## the board changes is fine; rows *reordering* under the eye is not, which is
## the same failure the payline readout hit when its box resized on hover.

const MAX_RUN := 5
const MIN_RUN_COLUMN := 1
const SWATCH_SIZE := Vector2(104, 40)
## Caps the scroll viewport. Content shorter than this shows no scrollbar at
## all; only an unusually varied board reveals that it scrolls.
const MAX_TABLE_HEIGHT := 467.0
const HEADER_COLOR := Color(0.62, 0.62, 0.66)
const VALUE_COLOR := Color(0.92, 0.92, 0.92)
const DEAD_COLOR := Color(0.42, 0.42, 0.45)
const GOLD_COLOR := Color(0.95, 0.82, 0.35)
const CURSE_COLOR := Color(0.92, 0.45, 0.42)

@onready var payout_container: MarginContainer = $PayoutContainer

signal panel_updated

## The board to read rows off. Assigned by SlotMachine; with none set the panel
## falls back to the whole strip so it still renders somewhere like the shop.
var columns: Array[ReelColumn] = []

var _scroll: ScrollContainer
var _content: Control


func _ready() -> void:
	build_legend()


## Distinct symbols currently visible across all five columns.
func _visible_symbols() -> Array[Symbol]:
	var seen: Array[Symbol] = []
	for column: ReelColumn in columns:
		if not is_instance_valid(column):
			continue
		if column.reel == null or column.reel.strip.is_empty():
			continue
		for stop: Stop in column.reel.visible_stops():
			if stop != null and stop.symbol not in seen:
				seen.append(stop.symbol)
	return _pin_order(seen)


## Distinct symbols anywhere on the strip.
static func _strip_symbols() -> Array[Symbol]:
	var seen: Array[Symbol] = []
	for stop: Stop in Global.strip:
		if stop.symbol not in seen:
			seen.append(stop.symbol)
	return _pin_order(seen)


## Type, then value — shared with the reel preview's tally so a symbol keeps the
## same relative place wherever it is listed.
static func _pin_order(symbols: Array[Symbol]) -> Array[Symbol]:
	return SymbolTable.sort_for_display(symbols)


func build_legend() -> void:
	for child in payout_container.get_children():
		payout_container.remove_child(child)
		child.queue_free()

	var line_symbols: Array[Symbol] = []
	var board_symbols: Array[Symbol] = []
	var source := _visible_symbols() if not columns.is_empty() else _strip_symbols()
	for symbol: Symbol in source:
		# A symbol that can never pay on a line is a row of dashes. Blank earns
		# its place on the strip, not in the table.
		if symbol.trigger != Symbol.Trigger.NONE:
			board_symbols.append(symbol)
		elif symbol.type != Action.Type.NONE or symbol.is_wild \
				or symbol.is_curse or not symbol.payout.is_empty():
			line_symbols.append(symbol)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)

	if not line_symbols.is_empty():
		root.add_child(_section("PAYOUTS"))
		root.add_child(_run_table(line_symbols))
	if not board_symbols.is_empty():
		root.add_child(_section("ON THE BOARD"))
		root.add_child(_board_table(board_symbols))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.add_child(root)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	payout_container.add_child(scroll)
	_scroll = scroll
	_content = root
	root.resized.connect(_fit_scroll)
	_fit_scroll.call_deferred()
	panel_updated.emit()


## A ScrollContainer reports zero minimum height, so left alone it collapses to
## nothing and its content is *always* taller than it — which means an AUTO
## scrollbar is always showing. Sizing it to its content up to the cap is what
## makes the scrollbar appear only on a board varied enough to overflow; below
## that there is no bar and nothing reads as a scroll region at all.
func _fit_scroll() -> void:
	if not is_instance_valid(_scroll) or not is_instance_valid(_content):
		return
	var wanted := _content.get_combined_minimum_size()
	_scroll.custom_minimum_size = Vector2(wanted.x, minf(wanted.y, MAX_TABLE_HEIGHT))


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", HEADER_COLOR)
	return label


## Symbol down the side, run length across the top, payout in the cells.
func _run_table(symbols: Array[Symbol]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = MAX_RUN - MIN_RUN_COLUMN + 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)

	grid.add_child(Control.new())  # corner, above the swatch column
	for n in range(MIN_RUN_COLUMN, MAX_RUN + 1):
		grid.add_child(_cell("x%d" % n, HEADER_COLOR, HORIZONTAL_ALIGNMENT_CENTER, 13))

	for symbol: Symbol in symbols:
		grid.add_child(_swatch(symbol))
		for n in range(MIN_RUN_COLUMN, MAX_RUN + 1):
			grid.add_child(_payout_cell(symbol, n))
	return grid


## What a run of n pays, straight from the scorer. Wild has no payout of its
## own — it takes the value of whatever it lands beside — so its row says that
## rather than inventing numbers for it.
func _payout_cell(symbol: Symbol, n: int) -> Control:
	# A line curse charges per cell, so n of them on one line costs n times.
	if symbol == SymbolTable.MARKED_CARD:
		var per := SymbolTable.MARKED_CARD_DAMAGE_PER_LEVEL \
			* maxi(1, Global.player.curse_level(SymbolTable.MARKED_CARD))
		return _cell("-%d" % (per * n), CURSE_COLOR, HORIZONTAL_ALIGNMENT_CENTER)

	if symbol.is_wild:
		return _cell("=" if n == MIN_RUN_COLUMN else "", DEAD_COLOR,
			HORIZONTAL_ALIGNMENT_CENTER)

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
		var tint := CURSE_COLOR if symbol.is_curse else GOLD_COLOR
		grid.add_child(_cell(_board_text(symbol), tint, HORIZONTAL_ALIGNMENT_LEFT))
	return grid


## What a board symbol does, stated per copy. Recycler and the curses each pay
## off something other than their own count, so "per copy" would be wrong.
func _board_text(symbol: Symbol) -> String:
	var when := "on lock" if symbol.trigger == Symbol.Trigger.ON_LOCK else "each spin"
	if symbol == SymbolTable.RECYCLER:
		return "%dg per junk symbol, %s" % [SymbolTable.RECYCLER_GOLD_PER_JUNK, when]
	if symbol == SymbolTable.REEL_JAM:
		return "freezes its column, %s" % when
	if symbol == SymbolTable.LIVE_WIRE:
		var per := SymbolTable.LIVE_WIRE_DAMAGE_PER_LEVEL \
			* maxi(1, Global.player.curse_level(SymbolTable.LIVE_WIRE))
		return "%d damage per copy, %s" % [per, when]
	var per := SymbolTable.CHIP_GOLD_PER_COPY if symbol == SymbolTable.CHIP \
		else SymbolTable.PENNY_GOLD_PER_COPY
	return "%dg per copy, %s" % [per, when]


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
