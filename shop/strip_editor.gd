extends CanvasLayer
class_name StripEditor
## §6: the player buys a stop, then places it. Landing on an occupied position
## replaces; landing between two inserts. One price, then the real question —
## do I have something worth sacrificing, or do I eat the dilution?
##
## Removal is a separate service (it isn't buying a symbol), so this same
## editor also runs in REMOVE mode.

signal edit_committed
signal cancelled

enum Mode { PLACE, REMOVE }

const STOP_SIZE := Vector2(64, 64)
const GAP_SIZE := Vector2(16, 64)

var mode: Mode = Mode.PLACE
var symbol: Symbol  # what's being placed, in PLACE mode

var _strip_row: HBoxContainer
var _title: Label


func setup(p_mode: Mode, p_symbol: Symbol = null) -> void:
	mode = p_mode
	symbol = p_symbol


func _ready() -> void:
	layer = 10
	_build_ui()
	_rebuild_strip()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# The affordances carry the interaction: gaps are "+" buttons, stops are
	# labelled tiles. The heading only names what you're doing.
	_title = Label.new()
	_title.text = ("Place %s" % symbol.symbol_name) if mode == Mode.PLACE else "Remove a stop"
	vbox.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1100, 96)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_strip_row = HBoxContainer.new()
	_strip_row.add_theme_constant_override("separation", 0)
	scroll.add_child(_strip_row)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(func() -> void: cancelled.emit())
	vbox.add_child(cancel)


func _rebuild_strip() -> void:
	for child in _strip_row.get_children():
		child.queue_free()

	for i in Global.strip.size():
		# A circular strip has exactly N gaps: gap i inserts before stop i,
		# which is also "after stop i-1". No separate trailing gap.
		if mode == Mode.PLACE:
			_strip_row.add_child(_build_gap(i))
		_strip_row.add_child(_build_stop(i))


func _build_gap(index: int) -> Control:
	var button := Button.new()
	button.custom_minimum_size = GAP_SIZE
	button.text = "+"
	button.tooltip_text = "Insert here"
	button.pressed.connect(func() -> void: _commit_insert(index))
	return button


func _build_stop(index: int) -> Control:
	var stop: Stop = Global.strip[index]
	var button := Button.new()
	button.custom_minimum_size = STOP_SIZE
	button.text = "%d\n%s" % [index + 1, stop.symbol.symbol_name]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var box := StyleBoxFlat.new()
	box.bg_color = _color_for(stop.symbol)
	button.add_theme_stylebox_override("normal", box)

	if mode == Mode.PLACE:
		button.pressed.connect(func() -> void: _commit_replace(index))
	else:
		var can_remove := Global.strip.size() > Reel.POOL_SIZE
		button.disabled = not can_remove
		button.tooltip_text = "" if can_remove else "Strip is already at its minimum length"
		button.pressed.connect(func() -> void: _commit_remove(index))
	return button


func _color_for(s: Symbol) -> Color:
	match s.type:
		Action.Type.ATTACK:
			return Color(0.45, 0.16, 0.14)
		Action.Type.DEFEND:
			return Color(0.14, 0.26, 0.44)
		Action.Type.HEAL:
			return Color(0.16, 0.38, 0.2)
		_:
			return Color(0.13, 0.13, 0.13)


# ------------------------------------------------------------------- commits

func _commit_replace(index: int) -> void:
	Global.strip[index] = Stop.new(symbol)
	edit_committed.emit()


func _commit_insert(index: int) -> void:
	Global.strip.insert(index, Stop.new(symbol))
	edit_committed.emit()


func _commit_remove(index: int) -> void:
	if Global.strip.size() <= Reel.POOL_SIZE:
		return
	Global.strip.remove_at(index)
	edit_committed.emit()
