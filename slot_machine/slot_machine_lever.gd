extends Button


func _ready() -> void:
	disabled = false
	#get_tree().current_scene.player_turn_started.connect(func() -> void: disabled = false)
	#EventBus.spin_lock_toggled.connect(func(): disabled = !disabled)
	#EventBus.spin_all_completed.connect(
		#func() -> void: disabled = false and CombatManager.curr_slot_press_action == CombatManager.SlotPressAction.SELECT
	#)
	
	
func _on_pressed() -> void:
	# Ignore clicks if the slot machine is already spinning
	if disabled:
		return
	
	disabled = true
	# Play your lever animation or sprite frames here...
	
	_attempt_lever_pull()

func _attempt_lever_pull(cost: int = 1) -> void:
	if Global.player.tokens < cost:
		push_error("Not enough tokens to pull lever!")
		return
	
	Global.player.tokens -= cost
	EventBus.lever_pulled.emit()
	
