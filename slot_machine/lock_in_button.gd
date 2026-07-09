extends Button

signal lock_in_pressed

func _ready() -> void:
	disabled = true
	get_tree().current_scene.player_turn_started.connect(func() -> void: disabled = true)

func _on_pressed() -> void:
	lock_in_pressed.emit()
