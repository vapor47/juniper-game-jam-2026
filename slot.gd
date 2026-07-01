class_name Slot
extends Button

var slot_reel: Reel = null
var _curr_stop: ReelStop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_insert_reel(Global.reels["Attack"])
	add_to_group("slots")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# TODO: High Priority: should this be returning a slotsymbol object
# or just a GDScript?
func spin() -> ReelStop:
	"""
	Check current wheel type
	Get random result from options array
	return result / index
	return type: SlotSymbol
	"""
	_curr_stop = slot_reel.reel_stops.pick_random()
	# TODO: After adding art, this below should be updated to result.icon
	$MarginContainer/SlotContainer/SlotWindow/Label.text = _curr_stop.slot_symbol.symbol_name
	return _curr_stop
	
func get_curr_stop() -> ReelStop:
	return _curr_stop

func _on_pressed() -> void:
	EventBus.open_side_panel.emit(self)
	EventBus.slot_selected.emit(self)


func _on_respin_button_pressed() -> void:
	# if has respin tokens
	spin()
	# Emit signal to reduce respin count
	CombatManager.respin_tokens -= 1
	
func _insert_reel(reel: Reel):
	slot_reel = reel
	Global.reel_inventory[reel.reel_name] -= 1
	spin()

func _remove_reel():
	Global.reel_inventory[slot_reel.reel_name] += 1
	slot_reel = null
	
func swap_reel(reel_to_insert: Reel) -> void:
	if !slot_reel:
		push_error("Attempted to swap reel with no existing reel.")
	
	_remove_reel()
	_insert_reel(reel_to_insert)

	if CombatManager.has_player_spun:
		CombatManager.respin_tokens -= 1
