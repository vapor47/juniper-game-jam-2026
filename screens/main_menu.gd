extends Control


func _on_start_button_pressed() -> void:
	SceneManager.go_to_combat(RunManager.get_next_encounter())
