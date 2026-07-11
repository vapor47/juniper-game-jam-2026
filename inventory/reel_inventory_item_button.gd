extends Button

signal item_pressed(item_data)

#@onready var inventory: SidePanel

func _ready() -> void:
	pressed.connect(func(): item_pressed.emit($"..".reel_data))
	EventBus.respin_count_updated.connect(
		func(): 
			disabled = %CombatManager.initial_spin_completed and Global.player.respin_tokens <= 0
	)
	get_tree().current_scene.player_turn_started.connect(
		func() -> void: disabled = false
	)

func _on_pressed() -> void:
	print_debug("emitting reel_swapped")
	EventBus.reel_swapped.emit($"..".reel_data["reel"])
	
	EventBus.swap_reel_selected.emit()
	
#	Otherwise do...? What happens when we click on a reel inventory item in a non swap context
