extends Button
class_name HoldButton

"""
enabled upon initial spin completion
disabled on press (set held)
"""
signal slot_held

func _ready() -> void:
	disabled = true
	#get_tree().current_scene.player_turn_started.connect(func() -> void: disabled = true)
	#EventBus.lever_pulled.connect(func() -> void: disabled = Global.player.respin_tokens <= 0)


func _on_pressed() -> void:
	disabled = true
	slot_held.emit()
