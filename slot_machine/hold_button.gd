extends Button
class_name HoldButton

"""
enabled upon initial spin completion
disabled on press (set held)
"""
signal slot_held

func _ready() -> void:
	disabled = true

func _on_pressed() -> void:
	disabled = true
	slot_held.emit()
