extends PanelContainer
class_name ComboLegendPanel

const ICON_SIZE := 32
const ICON_SPACING := 4
const RESULT_ICON_SIZE := 16
const MIN_COMBO_ROW_SPACER_WIDTH := 48

@onready var combo_container: MarginContainer = $ComboContainer

signal panel_updated
var _rows: Array[ComboLegendRow] = []

func _ready() -> void:
	EventBus.combo_legend_updated.connect(set_rows)
	print_debug("legend_panel _ready fired — should only print ONCE ever")

func set_rows(rows: Array[ComboLegendRow]) -> void:
	_rows = rows
	build_legend(rows)
		
	#var new_panel := build_legend(rows)
	#combo_container.add_child(new_panel)


#func display_legend(legend_rows: Array[ComboLegendRow] = _rows) -> void:
	#"""
	#Layout for number of category groups:
	#1: single column
	#2: two columns
	#3: three columns
	#4: 2 rows, 2 columns
	#5: 2 rows, 3 columns ( bottom row (of 2) potentially centered / non-aligned with top row
	#6: 2 rows, 3 columns
	#7: 2 rows: 4 columns (same staggering as mentioned previously for (5)
	#8: 2 rows, 4 columns
	#"""
	## clear existing rows
	##for child in combo_container.get_children():
		##child.queue_free()
	#
	#if legend_rows.is_empty():
		#return
	#
	## determine universal width from the largest combo in the legend
	#var max_symbols := 0
	#for row in legend_rows:
		#max_symbols = max(max_symbols, row.required_symbols.size())
	#
	#var symbols_area_width := (max_symbols * ICON_SIZE) + ((max_symbols - 1) * ICON_SPACING)
	#
	#for row in legend_rows:
		#combo_container.add_child(_build_row(row, symbols_area_width))


func _build_row(row: ComboLegendRow, symbols_area_width: int) -> Control:
	var hbox := HBoxContainer.new()
	#hbox.add_theme_constant_override("separation", ICON_SPACING)
	
	# left side: fixed-width container holding the required symbol icons
	var symbols_box := HBoxContainer.new()
	symbols_box.custom_minimum_size = Vector2(symbols_area_width, ICON_SIZE)
	#symbols_box.add_theme_constant_override("separation", ICON_SPACING)
	symbols_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	symbols_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	print("Combo size: %d " % row.required_symbols.size())
	for symbol: SlotSymbol in row.required_symbols:
		var icon := TextureRect.new()
		icon.texture = symbol.get_symbol_icon()
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.custom_maximum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		symbols_box.add_child(icon)
	
	hbox.add_child(symbols_box)
	
	# spacer to push result to the far right
	var spacer := Control.new()
	spacer.custom_minimum_size.x = MIN_COMBO_ROW_SPACER_WIDTH
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# right side: result icon + value
	var result_box := HBoxContainer.new()
	#result_box.add_theme_constant_override("separation", 4)
	result_box.alignment = BoxContainer.ALIGNMENT_END
	result_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var result_icon := TextureRect.new()
	result_icon.texture = _get_result_texture(row.result.type)
	result_icon.custom_minimum_size = Vector2(RESULT_ICON_SIZE, RESULT_ICON_SIZE)
	result_icon.custom_maximum_size = Vector2(RESULT_ICON_SIZE, RESULT_ICON_SIZE)
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	result_box.add_child(result_icon)
	
	var value_label := Label.new()
	if row.result.type == SlotSymbol.SymbolType.ATTACK:
		print_debug("Combo Result value: %d" % row.result.value)
	value_label.text = str(row.result.value)
	result_box.add_child(value_label)
	
	hbox.add_child(result_box)
	
	return hbox


func _get_result_texture(type: SlotSymbol.SymbolType) -> Texture2D:
	match type:
		SlotSymbol.SymbolType.ATTACK:
			return preload("res://assets/icons/attack_icon.svg")
		SlotSymbol.SymbolType.DEFEND:
			return preload("res://assets/icons/defend_icon.svg")
		_:
			return null


func build_legend(rows: Array[ComboLegendRow] = _rows) -> VBoxContainer:
	var categorized_rows := get_categorized_rows(rows)
	var legend := _build_legend_by_category(categorized_rows)
	for child in combo_container.get_children():
		child.queue_free()
	combo_container.add_child(legend)
	panel_updated.emit()
	return legend

func get_categorized_rows(rows: Array[ComboLegendRow]) -> Dictionary[SlotSymbol.SymbolType, Array]:
	var categorized_rows: Dictionary[SlotSymbol.SymbolType, Array] = {}
	for row: ComboLegendRow in rows:
		categorized_rows.get_or_add(row.category, [] as Array[ComboLegendRow]).append(row)
		
	return categorized_rows

func _build_legend_by_category(categorized_rows: Dictionary) -> VBoxContainer:
	# categorized_rows: { SlotSymbol.SymbolType: Array[ComboLegendRow] }
	
	var categories: Array[SlotSymbol.SymbolType] = categorized_rows.keys()
	var n := categories.size()
	if n == 0:
		return
	
	var cols := n if n <= 3 else ceili(n / 2.0)
	var rows := 1 if n <= 3 else 2
	
	var grid_wrapper := VBoxContainer.new()
	grid_wrapper.add_theme_constant_override("separation", 12)
	
	var category_idx := 0
	var max_row_width := 0
	for row_idx in rows:
		var items_in_this_row: int
		items_in_this_row = min(cols, n - (cols * row_idx))
		
		#items_in_this_row = 1
			
#		num items in row = n - (cols
#		Total % cols == remainder
# cols * idx == how many seen so far
# total - seen_so_far == remaining
# current row num columns == cols if can remaining fit cols
#How much remaining categories / cols == how many rows remaining
# 	either an integer or float
	#if float, last row is different

		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 16)
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER  # centers uneven last row
		row_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		for i in items_in_this_row:
			var category: SlotSymbol.SymbolType = categories[category_idx]
			var category_rows: Array[ComboLegendRow] = categorized_rows[category] as Array[ComboLegendRow]
			var category_box: VBoxContainer = _build_category_column(category, category_rows)
			max_row_width = max(max_row_width, category_box.size.x)
			row_hbox.add_child(category_box)
			category_idx += 1
		
		grid_wrapper.add_child(row_hbox)
		
	for row_hbox: HBoxContainer in grid_wrapper.get_children():
		for category_box: VBoxContainer in row_hbox.get_children():
			for row: Control in category_box.get_children():
				row.custom_minimum_size.x = max_row_width
	
	#combo_container.add_child(grid_wrapper)
	return grid_wrapper
	
	#await get_tree().process_frame  # let containers compute their natural size
	#var content_size := combo_container.get_combined_minimum_size()
	#size = content_size 
	#const COLUMN_SPACING = 400
	#const PANEL_MARGIN = 4
	#var calculated_width = (cols * ICON_SIZE) + ((cols - 1) * COLUMN_SPACING) + PANEL_MARGIN * 2
	#size.x = calculated_width


func _build_category_column(category: SlotSymbol.SymbolType, category_rows: Array[ComboLegendRow]) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	
	var header := Label.new()
	header.text = SlotSymbol.SymbolType.keys()[category]  # or a proper display name lookup
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(header)
	
	var max_symbols := 0
	for row in category_rows:
		max_symbols = max(max_symbols, row.required_symbols.size())
	var symbols_area_width := (max_symbols * ICON_SIZE) + ((max_symbols - 1) * ICON_SPACING)
	
	#var built_rows: Array[Control] = []
	#var max_row_width := 0.0
	
	for row in category_rows:
		var row_control := _build_row(row, symbols_area_width)
		#built_rows.append(row_control)
		column.add_child(row_control)
		
		# natural width = symbols box + min spacer + result box natural size
		#var natural_width: int = symbols_area_width + MIN_COMBO_ROW_SPACER_WIDTH + row_control.get_child(2).get_combined_minimum_size().x
		#max_row_width = max(max_row_width, row_control.get_combined_minimum_size().x)
	
	# enforce uniform width across all rows
	#for row_control in built_rows:
		#row_control.custom_minimum_size.x = max_row_width
	
	return column
