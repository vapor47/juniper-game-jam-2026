extends Button
class_name LockInButton

signal lock_in_pressed

## Enabled state is owned by CombatManager (needs a spin *and* a selected
## line), so this button doesn't manage its own.
func _ready() -> void:
	disabled = true

func _on_pressed() -> void:
	lock_in_pressed.emit()
	EventBus.slot_selection_confirmed.emit()
