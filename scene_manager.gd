extends Node

func _ready() -> void:
	EventBus.post_combat_completed.connect(_on_continue)

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://root_control.tscn")
