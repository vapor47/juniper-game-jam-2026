extends Button

func _on_pressed() -> void:
	EventBus.post_combat_completed.emit()
