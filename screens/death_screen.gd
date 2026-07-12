extends CanvasLayer

func _on_restart_button_pressed() -> void:
	EventBus.run_restarted.emit()
