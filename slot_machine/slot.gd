class_name Slot
extends Button

var slot_reel: Reel = null
var _curr_stop: ReelStop = null
@onready var result_label: Label = $MarginContainer/SlotContainer/SlotWindow/Label

func _ready() -> void:
	_insert_reel(Global.reels["Attack"], false)
	result_label.text = slot_reel.reel_stops.map(func(s): return s.slot_symbol).pick_random().symbol_name
	add_to_group("slots")

func _exit_tree() -> void:
	_remove_reel()

func spin() -> ReelStop:
	"""
	Check current wheel type
	Get random result from options array
	return result / index
	return type: SlotSymbol
	"""
	_curr_stop = slot_reel.reel_stops.pick_random()
	reveal_with_spin(_curr_stop)
	# TODO: After adding art, this below should be updated to result.icon
	#$MarginContainer/SlotContainer/SlotWindow/Label.text = _curr_stop.slot_symbol.symbol_name
	return _curr_stop
	
func get_curr_stop() -> ReelStop:
	return _curr_stop

func _on_pressed() -> void:
	EventBus.open_side_panel.emit(self)
	EventBus.slot_selected.emit(self)


func _on_respin_button_pressed() -> void:
	if Global.player.respin_tokens <= 0:
		return
	spin()
	Global.player.respin_tokens -= 1
	
func _insert_reel(reel: Reel, should_spin: bool = true):
	slot_reel = reel
	Global.reel_inventory[reel.reel_name] -= 1
	if should_spin:
		spin()

func _remove_reel():
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
	
	_swap_reel(reel_to_insert)
	if get_tree().current_scene.initial_spin_completed:
		Global.player.respin_tokens -= token_cost
		
	return true
	
func reveal_with_spin(stop: ReelStop, duration: float = 1.0) -> void:
	var elapsed = 0.0
	var fake_symbols = slot_reel.reel_stops.map(
		func(s):
			return s.slot_symbol
	)
	var interval := 0.01  # how fast it cycles
	
	while elapsed < duration:
		await get_tree().create_timer(interval).timeout
		# show random symbol name as placeholder
		result_label.text = fake_symbols[randi() % fake_symbols.size()].symbol_name
		elapsed += interval
		#interval = lerp(interval, 0.3, 0.1)  # slow down toward end
	
	# Land on actual result
	result_label.text = stop.slot_symbol.symbol_name
