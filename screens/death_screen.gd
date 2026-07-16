extends CanvasLayer

func _on_restart_button_pressed() -> void:
	RunManager.restart_run()
	SceneManager.go_to_combat(RunManager.get_next_encounter())


func _on_main_menu_button_pressed() -> void:
	SceneManager.go_to_main_screen()
