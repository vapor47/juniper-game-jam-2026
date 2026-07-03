extends Button

signal lock_in_pressed

func _ready() -> void:
	disabled = true
	EventBus.spin_lock_toggled.connect(func(): disabled = !disabled)
	
func _on_pressed():
	lock_in_pressed.emit()
