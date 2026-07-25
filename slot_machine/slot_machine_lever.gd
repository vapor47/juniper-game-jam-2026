extends Button
## Respin cost (1/2/3… incrementing per turn) is decided by CombatManager, not
## here — this button just requests a spin over EventBus (§5).


func _ready() -> void:
	disabled = false


func _on_pressed() -> void:
	# Ignore clicks if the slot machine is already spinning
	if disabled:
		return

	disabled = true
	# Play your lever animation or sprite frames here...

	EventBus.lever_pulled.emit()
