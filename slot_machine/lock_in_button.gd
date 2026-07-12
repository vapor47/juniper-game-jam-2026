extends Button
class_name LockInButton

signal lock_in_pressed

func _ready() -> void:
	disabled = true
	EventBus.lever_pulled.connect(func() -> void: disabled = false)

func _on_pressed() -> void:
	lock_in_pressed.emit()
	EventBus.slot_selection_confirmed.emit()
