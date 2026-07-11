extends PanelContainer
class_name SlotMachine

@onready var lever = %SlotMachineLever
@onready var lock_in_button: Button = %LockInButton
@onready var health_bar: HealthBar = %PlayerHealthBar
@onready var phase_label: Label = %PhaseLabel

var num_slots_spinning: int = 0:
	set(new_val):
		#%LockInButton.disabled = new_val > 0
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
		#for reel_name: String in Global.reel_inventory:
			#var count: int = Global.reel_inventory[reel_name]
			#if count <= 0:
				#continue
			#slot._insert_reel(Global.reels[reel_name], false)
	
	slots[0]._insert_reel(Global.reels.get("Attack"), false)
	slots[1]._insert_reel(Global.reels.get("Attack"), false)
	slots[2]._insert_reel(Global.reels.get("Attack"), false)
	slots[3]._insert_reel(Global.reels.get("Defend"), false)
	slots[4]._insert_reel(Global.reels.get("Defend"), false)
	
	health_bar.setup(Global.player)

func _on_lever_pulled() -> void:
	var slots: Array[Node] = get_tree().get_nodes_in_group("slots")
	
	for i in slots.size():
		slots[i].spin(Global.SLOT_SPIN_DURATION + (i * Global.SLOT_REVEAL_STAGGER))
		
	# Emit spin completed (hacky)
	var last_slot_duration := Global.SLOT_SPIN_DURATION + (slots.size() * Global.SLOT_REVEAL_STAGGER)
	await get_tree().create_timer(last_slot_duration).timeout
	EventBus.spin_all_completed.emit()


func _confirm_slots() -> void:
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


func _on_reel_swapped(reel_to_insert: Reel) -> void:
	print_debug("on reel swapped")
	if selected_slot == null:
		push_error("Error: no selected slot on reel swap")
		return
	
	selected_slot.attempt_reel_swap(reel_to_insert, $"../..".curr_swap_cost)
	
	# Auto close Side Panel after swap
	selected_slot = null
	
func _get_slots() -> Array[Node]:
	return get_tree().get_nodes_in_group("slots")

"""
onSpin: trigger onSpin for all child slots
onFinalize: calculate results from child slot values
"""
