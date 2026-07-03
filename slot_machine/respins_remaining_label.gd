extends Label

func _ready() -> void:
	_update_label()
	EventBus.respin_count_updated.connect(_update_label)

func _update_label():
	print_debug("label updated")
	text = "RESPINS REMAINING: " + str(CombatManager.respin_tokens)
