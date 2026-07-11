extends Label

func _ready() -> void:
	_update_label()
	EventBus.token_count_updated.connect(_update_label)

func _update_label(token_count: int = Global.player.tokens):
	print_debug("label updated")
	text = "TOKENS REMAINING: " + str(token_count)
