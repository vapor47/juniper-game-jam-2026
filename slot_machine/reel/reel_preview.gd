extends PanelContainer
class_name ReelPreview
## Read-only render of the reel: the strip in order, and a tally beneath it.
##
## §2 justifies the master reel on odds legibility — "one pool is learnable,
## five distributions are memorization" — but the pool was only ever visible
## mid-purchase in the shop's editor, so during a fight the learnable thing
## couldn't be looked at.
##
## Order matters as much as composition, which is why this renders the strip as
## a sequence rather than a tally. A column shows three *adjacent* stops, so two
## Mega Atks side by side on the strip can share a column while the same two
## spread apart never can. That is invisible on the board and it is what makes
## the shop's insert-vs-replace choice (§6) a real decision.
##
## Deliberately does not mark where each column currently sits. Landings are
## uniform random (`randi() % strip.size()`), so a column's present position
## says nothing about its next one — a marker would duplicate what the three
## visible symbols already show.

const STOP_SIZE := Vector2(96, 96)
const VIEW_SIZE := Vector2(1470, 162)
const MOD_BORDER := Color(1, 0.85, 0.3, 0.9)
## The stop after the last one is the first one. Repeating it, dimmed, states
## the strip is circular without a sentence saying so.
const WRAP_ALPHA := 0.35
const TALLY_COLUMNS := 4
const TALLY_FONT_SIZE := 20

var _row: HBoxContainer
var _tally: GridContainer


func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = VIEW_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_row)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	column.add_child(scroll)

	# The strip shows order and adjacency; the tally answers "how many of these
	# do I actually own", which is the other half of reading a reel and is
	# genuinely hard to count off a 20-tile row.
	_tally = GridContainer.new()
	_tally.columns = TALLY_COLUMNS
	_tally.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tally.add_theme_constant_override("h_separation", 22)
	_tally.add_theme_constant_override("v_separation", 2)
	column.add_child(_tally)

	refresh()


func refresh() -> void:
	if _row == null:
		return
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()

	for i in Global.strip.size():
		_row.add_child(_tile(Global.strip[i], i + 1))
	if not Global.strip.is_empty():
		_row.add_child(_tile(Global.strip[0], 1, WRAP_ALPHA))

	_refresh_tally()


## One entry per distinct symbol on the strip, with how many there are. Counts
## the strip itself, so the repeated wrap tile is not double-counted.
func _refresh_tally() -> void:
	for child in _tally.get_children():
		_tally.remove_child(child)
		child.queue_free()

	var counts := {}
	for stop: Stop in Global.strip:
		counts[stop.symbol] = counts.get(stop.symbol, 0) + 1

	var symbols: Array[Symbol] = []
	for symbol: Symbol in counts:
		symbols.append(symbol)
	for symbol: Symbol in SymbolTable.sort_for_display(symbols):
		var label := Label.new()
		label.text = "%s x%d" % [symbol.symbol_name, counts[symbol]]
		label.add_theme_font_size_override("font_size", TALLY_FONT_SIZE)
		label.add_theme_color_override("font_color", SymbolCell.color_for(symbol).lightened(0.55))
		_tally.add_child(label)


## Same colour and headline the board and the paytable use, so a tile here is
## recognisably the same object as a cell there. The shop editor used to carry
## its own colour table, which had already drifted from the board's.
func _tile(stop: Stop, number: int, alpha: float = 1.0) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = STOP_SIZE

	var style := StyleBoxFlat.new()
	var base := SymbolCell.color_for(stop.symbol)
	style.bg_color = Color(base.r, base.g, base.b, alpha)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	if not stop.modifiers.is_empty():
		style.set_border_width_all(2)
		style.border_color = MOD_BORDER
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	vbox.add_child(_label(str(number), 15, Color(1, 1, 1, 0.45 * alpha)))
	vbox.add_child(_label(SymbolCell.headline(stop.symbol), 30, Color(1, 1, 1, alpha)))
	vbox.add_child(_label(stop.symbol.symbol_name, 14, Color(1, 1, 1, 0.8 * alpha)))

	var notes: Array[String] = []
	for m: StopModifier in stop.modifiers:
		notes.append("%s — %s" % [m.display_name, m.description])
	if not notes.is_empty():
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		HoverLabel.attach_to(panel, "\n".join(notes))
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
