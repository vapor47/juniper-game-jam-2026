extends Control
class_name SymbolCell
## Placeholder cell visual, built to be *scanned* rather than read.
##
## It used to render the symbol's name, which meant "Light Atk" and "Med Atk"
## were near-identical strings on near-identical red — you had to read every
## cell in sequence to tell a board apart. The value is what actually differs
## within a type, so it leads: a big number you can compare at a glance, a
## short type tag under it, and a background whose brightness tracks the tier
## so the strong cells stand out without reading anything at all.
##
## Swap for a TextureRect once real symbol art lands (§12).

const VALUE_FONT_SIZE := 44
const TAG_FONT_SIZE := 15

var stop: Stop:
	set(new_stop):
		stop = new_stop
		_refresh()

var _bg: ColorRect
var _value: Label
var _tag: Label


func _ready() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	_value = _make_label(VALUE_FONT_SIZE)
	_tag = _make_label(TAG_FONT_SIZE)
	vbox.add_child(_value)
	vbox.add_child(_tag)

	_refresh()


func _make_label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	return label


func _refresh() -> void:
	if not is_inside_tree() or not stop:
		return
	var symbol := stop.symbol
	_value.text = _headline(symbol)
	_tag.text = _tag_for(symbol)
	_bg.color = _color_for(symbol)


## The number leads, because within a type the number is the whole difference.
## Symbols that have no meaningful value say what they are instead.
func _headline(symbol: Symbol) -> String:
	if symbol.is_wild:
		return "W"
	if not symbol.payout.is_empty():
		return "7"
	if symbol == SymbolTable.CHIP:
		return "$"
	if symbol.type == Action.Type.NONE:
		return "-"
	return str(symbol.value)


func _tag_for(symbol: Symbol) -> String:
	if symbol.is_wild:
		return "WILD"
	if not symbol.payout.is_empty():
		return "LUCKY"
	match symbol.type:
		Action.Type.ATTACK:
			return "ATK"
		Action.Type.DEFEND:
			return "BLK"
		Action.Type.HEAL:
			return "HEAL"
		Action.Type.GOLD:
			return "GOLD"
		Action.Type.TOKEN:
			return "TOKEN"
		_:
			return "CHIP" if symbol == SymbolTable.CHIP else ""


## Hue carries the type, brightness carries the tier — so a Heavy reads as
## stronger than a Light before you've read either number.
func _color_for(symbol: Symbol) -> Color:
	if symbol.is_wild:
		return Color(0.42, 0.2, 0.5)

	var base := Color(0.15, 0.15, 0.15)
	match symbol.type:
		Action.Type.ATTACK:
			base = Color(0.5, 0.15, 0.13)
		Action.Type.DEFEND:
			base = Color(0.13, 0.27, 0.47)
		Action.Type.HEAL:
			base = Color(0.16, 0.42, 0.22)
		Action.Type.GOLD:
			base = Color(0.5, 0.4, 0.1)
		Action.Type.TOKEN:
			base = Color(0.38, 0.25, 0.46)
		_:
			if not symbol.payout.is_empty():
				base = Color(0.48, 0.36, 0.08)
			elif symbol == SymbolTable.CHIP:
				base = Color(0.34, 0.3, 0.14)

	# 2 is the floor, 10 the ceiling across the table; lighten across that span.
	if symbol.value > 0:
		var tier := clampf((float(symbol.value) - 2.0) / 8.0, 0.0, 1.0)
		base = base.lightened(tier * 0.35)
	return base
