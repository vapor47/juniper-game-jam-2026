extends Button


func _ready() -> void:
	disabled = false
	get_tree().current_scene.player_turn_started.connect(func() -> void: disabled = false)
	#EventBus.spin_lock_toggled.connect(func(): disabled = !disabled)
	
	
func _on_pressed() -> void:
	# Ignore clicks if the slot machine is already spinning
	if disabled:
		return
	
	disabled = true
	# Play your lever animation or sprite frames here...
	
	EventBus.lever_pulled.emit()
