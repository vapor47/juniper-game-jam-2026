extends ProgressBar

func _ready() -> void:
	value = Global.player.health
	EventBus.damage_taken.connect(
		func(who):
			if who == Global.player:
				value = Global.player.health
	)
