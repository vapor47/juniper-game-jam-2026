extends Button


func _ready() -> void:
	disabled = true
	EventBus.spin_lock_toggled.connect(func(): disabled = !disabled)
	EventBus.respin_count_updated.connect(func(): disabled = CombatManager.respin_tokens <= 0)
