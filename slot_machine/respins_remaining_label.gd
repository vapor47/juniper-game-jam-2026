extends Label

func _ready() -> void:
	_update_label()
	EventBus.respin_count_updated.connect(_update_label)

func _update_label(respin_count: int = Global.player.tokens):
	print_debug("label updated")
	text = "TOKENS REMAINING: " + str(respin_count)
