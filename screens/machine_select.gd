extends Control
## Pick the machine you sit down at. Shown once, between the menu and the run.
##
## Each card states the machine's identity and shows its whole starting strip as
## a tally, because that *is* the choice — a machine is its reel, and picking
## one blind would be picking a name. Composition is legible enough to judge
## from counts: six Light Blks and two Heavies reads as "never defenceless,
## rarely dangerous" without a paragraph saying so.

const CARD_SIZE := Vector2(300, 380)
const TALLY_FONT := 14


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	add_child(column)

	var title := Label.new()
	title.text = "PICK YOUR MACHINE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	column.add_child(row)

	for machine: Machine in MachineCatalog.all():
		row.add_child(_card(machine))


func _card(machine: Machine) -> Control:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: RunManager.start_run(machine))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	box.add_child(_label(machine.display_name, 26, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER))
	var desc := _label(machine.description, 14, Color(0.72, 0.72, 0.76),
		HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.y = 40
	box.add_child(desc)

	var strip := machine.build_strip()
	box.add_child(_label("%d SYMBOLS" % strip.size(), 12, Color(0.58, 0.58, 0.62),
		HORIZONTAL_ALIGNMENT_CENTER))

	for entry: Array in machine.tally():
		var symbol: Symbol = entry[0]
		box.add_child(_label("%s  x%d" % [symbol.symbol_name, int(entry[1])], TALLY_FONT,
			SymbolCell.color_for(symbol).lightened(0.55), HORIZONTAL_ALIGNMENT_LEFT))

	# Starting kit last: it is the part composition cannot state.
	for souvenir: Souvenir in machine.starting_souvenirs():
		box.add_child(_label("", 6, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_LEFT))
		box.add_child(_label(souvenir.display_name, 15, Color(0.55, 0.72, 0.95),
			HORIZONTAL_ALIGNMENT_LEFT))
		var effect := _label(souvenir.description, 12, Color(0.62, 0.72, 0.85),
			HORIZONTAL_ALIGNMENT_LEFT)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(effect)

	return button


func _label(text: String, size: int, color: Color, align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
