class_name Slot
extends Button

signal started_spinning
signal stopped_spinning

var slot_reel: Reel = null
var _curr_stop: ReelStop = null:
	set(new):
		print("curr stop changed")
		_curr_stop = new
@onready var result_label: Label = $MarginContainer/SlotContainer/SlotWindow/Label

var is_spinning: bool = false:
	set(new_val):
		if new_val == is_spinning:
			return
		is_spinning = new_val
		if new_val: started_spinning.emit()
		else: stopped_spinning.emit()


func _ready() -> void:
	add_to_group("slots")
	#_insert_reel(Global.reels["Attack"], false)
	#result_label.text = slot_reel.reel_stops.map(
		#func(s: ReelStop) -> SlotSymbol:
			#return s.slot_symbol
	#).pick_random().symbol_name

func _exit_tree() -> void:
	_remove_reel()

func spin(duration: float = Global.SLOT_SPIN_DURATION) -> ReelStop:
	_curr_stop = slot_reel.reel_stops.pick_random()
	
	_start_spin_animation()
	await get_tree().create_timer(duration).timeout
	_stop_spin_animation(_curr_stop)
	
	return _curr_stop

func get_curr_stop() -> ReelStop:
	return _curr_stop

func _start_spin_animation() -> void:
	if is_spinning:
		return
	is_spinning = true
	
	var fake_symbols := slot_reel.reel_stops.map(
		func(s: ReelStop) -> SlotSymbol:
			return s.slot_symbol
	)
	
	while is_spinning:
		result_label.text = fake_symbols.pick_random().symbol_name
		await get_tree().create_timer(Global.SLOT_SPIN_INTERVAL).timeout
		#if not is_spinning:
			#break
		# show random symbol name as placeholder
		
func _stop_spin_animation(final_stop: ReelStop) -> void:
	if not is_spinning:
		return
		
	is_spinning = false
	result_label.text = get_curr_stop().slot_symbol.symbol_name

var is_selected: bool = false

func _make_selected_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.9, 0.3)  # light blue tint, semi-transparent
	style.border_color = Color(0.2, 0.5, 0.9)   # solid blue border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
	
func select() -> void:
	is_selected = true
	add_theme_stylebox_override("normal", _make_selected_stylebox())
	add_theme_stylebox_override("hover", _make_selected_stylebox())
	
func unselect() -> void:
	is_selected = false
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("hover")
	
func _on_pressed() -> void:
	#EventBus.open_side_panel.emit(self)
	EventBus.slot_selected.emit(self)
	
#	EITHER SWAP OR SELECT
	#CombatManager.curr_slot_press_action
	#if in select mode and >= than max active slots selected:
	# ignore button press
	# notify user, or send signal to.
	is_selected = not is_selected
	
"""
combat manager updates slot behavior
combat manager now owns what it means to swap and to select, which feels appropriate

slot on press simply calls whatever behavior is passed to it.
"""


func _on_respin_button_pressed() -> void:
	if Global.player.respin_tokens <= 0:
		return
	spin()
	Global.player.respin_tokens -= 1
	
func _insert_reel(reel: Reel, should_spin: bool = true) -> void:
	if Global.reel_inventory[reel.reel_name] <= 0:
		push_error("Attempted to insert reel with 0 remaining in inventory.")
	slot_reel = reel
	Global.reel_inventory[reel.reel_name] -= 1
	
	result_label.text = slot_reel.reel_stops.map(
		func(s: ReelStop) -> SlotSymbol:
			return s.slot_symbol
	).pick_random().symbol_name
	
	if should_spin:
		spin()

func _remove_reel() -> void:
	Global.reel_inventory[slot_reel.reel_name] += 1
	slot_reel = null
	
func _swap_reel(reel_to_insert: Reel) -> void:
	_remove_reel()
	_insert_reel(reel_to_insert)

func attempt_reel_swap(reel_to_insert: Reel, token_cost: int = 0) -> bool:
	"""
	Returns True if swap is valid and completed,
			False if swap is invalid
			
	Causes for invalid swap include:
		- Not enough respin tokens
	"""
	if !slot_reel:
		push_error("Attempted to swap reel with no existing reel.")
		return false
	
	if Global.player.respin_tokens < token_cost:
		return false
		
	if reel_to_insert == slot_reel:
		return false
		
	if Global.reel_inventory[reel_to_insert.reel_name] <= 0:
		return false
	
	_swap_reel(reel_to_insert)
	#if get_tree().current_scene.initial_spin_completed:
	Global.player.respin_tokens -= token_cost
		
	return true
