extends Label

func _ready() -> void:
	_update_label()
	EventBus.respin_count_updated.connect(_update_label)

func _update_label(respin_count: int = Global.player.respin_tokens):
	print_debug("label updated")
	text = "RESPINS REMAINING: " + str(respin_count)
