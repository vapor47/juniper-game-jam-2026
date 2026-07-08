extends PanelContainer

@onready var lever = %SlotMachineLever
@onready var lock_in_button: Button = %LockInButton
@onready var health_bar: HealthBar = %PlayerHealthBar

var num_slots_spinning: int = 0:
	set(new_val):
		%LockInButton.disabled = new_val > 0
		num_slots_spinning = new_val

var selected_slot: Slot = null:
	set(value):
		if value == null:
			EventBus.close_side_panel.emit()
		selected_slot = value

func _ready() -> void:
	EventBus.lever_pulled.connect(_on_lever_pulled)
	lock_in_button.lock_in_pressed.connect(_confirm_slots)
	EventBus.slot_selected.connect(_on_slot_selected)
	EventBus.reel_swapped.connect(_on_reel_swapped)
	
	var slots: Array[Node] = get_tree().get_nodes_in_group("slots")

	for slot: Slot in slots:
		slot.started_spinning.connect(func() -> void: num_slots_spinning += 1)
		slot.stopped_spinning.connect(func() -> void: num_slots_spinning -= 1)
	health_bar.setup(Global.player)

func _on_lever_pulled() -> void:
	var slots: Array[Node] = get_tree().get_nodes_in_group("slots")
	
	for i in slots.size():
		slots[i].spin(Global.SLOT_SPIN_DURATION + (i * Global.SLOT_REVEAL_STAGGER))
		

func _confirm_slots() -> void:
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
			
				
func _on_slot_selected(slot: Slot) -> void:
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
