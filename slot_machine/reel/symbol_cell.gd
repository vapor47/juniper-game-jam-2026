extends Control
class_name SymbolCell
## Placeholder cell visual: a colored panel + the symbol's name as text.
## No final symbol art exists yet (§12 flags this as placeholder-name
## territory already) — swap this for a TextureRect once art lands.

var stop: Stop:
	set(new_stop):
		stop = new_stop
		_refresh()

var _bg: ColorRect
var _label: Label


func _ready() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_refresh()


func _refresh() -> void:
	if not is_inside_tree() or not stop:
		return
	_label.text = stop.symbol.symbol_name
	_bg.color = _color_for_type(stop.symbol.type)


func _color_for_type(type: Action.Type) -> Color:
	match type:
		Action.Type.ATTACK:
			return Color(0.55, 0.18, 0.16)
		Action.Type.DEFEND:
			return Color(0.16, 0.3, 0.5)
		Action.Type.HEAL:
			return Color(0.2, 0.45, 0.25)
		_:
			return Color(0.15, 0.15, 0.15)
