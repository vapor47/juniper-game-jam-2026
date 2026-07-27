extends PanelContainer
class_name StripView
## Read-only render of the strip, in order.
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

const STOP_SIZE := Vector2(64, 64)
const VIEW_SIZE := Vector2(980, 108)
const MOD_BORDER := Color(1, 0.85, 0.3, 0.9)
## The stop after the last one is the first one. Repeating it, dimmed, states
## the strip is circular without a sentence saying so.
const WRAP_ALPHA := 0.35

var _row: HBoxContainer


func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = VIEW_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 4)
	scroll.add_child(_row)

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

	vbox.add_child(_label(str(number), 10, Color(1, 1, 1, 0.45 * alpha)))
	vbox.add_child(_label(SymbolCell.headline(stop.symbol), 20, Color(1, 1, 1, alpha)))
	vbox.add_child(_label(stop.symbol.symbol_name, 9, Color(1, 1, 1, 0.8 * alpha)))

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
