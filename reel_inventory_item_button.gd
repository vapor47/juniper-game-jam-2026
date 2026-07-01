extends Button

signal item_pressed(item_data)

func _ready() -> void:
	pressed.connect(func(): item_pressed.emit($"..".reel_data))
	EventBus.respin_count_updated.connect(func(): disabled = CombatManager.respin_tokens <= 0)


func _on_pressed() -> void:
	print_debug("emitting reel_swapped")
	EventBus.reel_swapped.emit($"..".reel_data["reel"])
