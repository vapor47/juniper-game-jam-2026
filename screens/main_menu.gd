extends Control


func _on_start_button_pressed() -> void:
	# The run starts once a machine is picked — RunManager.start_run does the
	# reset, so nothing is torn down until there is something to build.
	SceneManager.go_to_machine_select()
