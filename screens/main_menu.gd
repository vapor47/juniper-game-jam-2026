extends Control


func _on_start_button_pressed() -> void:
	RunManager.reset_run_state()
	SceneManager.go_to_combat(RunManager.get_next_encounter())
