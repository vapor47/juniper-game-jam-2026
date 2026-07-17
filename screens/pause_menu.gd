extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # must keep running even while the tree is paused!
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	if visible:
		_resume()
	else:
		_open()

func _open() -> void:
	get_tree().paused = true
	show()

func _resume() -> void:
	get_tree().paused = false
	hide()


func _on_restart_button_pressed() -> void:
	RunManager.restart_run()
	_resume()


func _on_main_menu_button_pressed() -> void:
	SceneManager.go_to_main_screen()
	_resume()


func _on_god_menu_button_pressed() -> void:
	%MainMenuContainer.hide()
	%GodMenu.show()


func _on_god_menu_back_button_pressed() -> void:
	%GodMenu.hide()
	%MainMenuContainer.show()
