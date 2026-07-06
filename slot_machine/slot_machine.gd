extends PanelContainer

@onready var lever = %SlotMachineLever
@onready var lock_in_button = %LockInButton

var selected_slot: Slot = null:
	set(value):
		if value == null:
			EventBus.close_side_panel.emit()
		selected_slot = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.lever_pulled.connect(_on_lever_pulled)
	lock_in_button.lock_in_pressed.connect(_confirm_slots)
	EventBus.slot_selected.connect(_on_slot_selected)
	EventBus.reel_swapped.connect(_on_reel_swapped)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_lever_pulled() -> void:
	get_tree().call_group("slots", "spin")


func _confirm_slots():
	"""
	Combos:
		3 regular attacks = 5 dmg
		3 strong attacks = 15 dmg
		3 multipliers = 30 dmg
		These can be recalculated based on odds, level, whatnot
	"""
	#var attack_val = 0
	#var attack_mult = 1
	#
	#for slot_result in get_tree().get_nodes_in_group("slots").map(func(slot): return slot.get_result()):
		#match slot_result:
			#"attack":
				#attack_val += 1
			#"strong_attack":
				#attack_val += 3
			#'multiply_attack':
				#attack_mult *= 2
				#
	#var total_attack_val = attack_val * attack_mult
	#print_debug("TOTAL DAMAGE: " + str(total_attack_val))
##	TODO: lock player actions and begin enemy turn
	#return total_attack_val
	
	var reel_stops: Array[ReelStop] = []
	for s in _get_slots():
		reel_stops.append(s.get_curr_stop())

	EventBus.slots_locked_in.emit(reel_stops)
			
				
func _on_slot_selected(slot):
	print_debug("slot selected")
	if slot == selected_slot:
		selected_slot = null
		return
		
	selected_slot = slot


func _on_reel_swapped(reel_to_insert: Reel):
	print_debug("on reel swapped")
	if selected_slot == null:
		push_error("Error: no selected slot on reel swap")
		return
	
	selected_slot.attempt_reel_swap(reel_to_insert, 1)
	
	# Auto close Side Panel after swap
	selected_slot = null
	
func _get_slots():
	return get_tree().get_nodes_in_group("slots")
	


"""
onSpin: trigger onSpin for all child slots
onFinalize: calculate results from child slot values
"""
