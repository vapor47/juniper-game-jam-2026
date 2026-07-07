extends Button

"""
Enabled state ==
	Enough tokens &&
	Is post initial lever pull
means Disabled == 
	Not enough tokens ||
	Is pre initial lever pull
"""

func _ready() -> void:
	disabled = true
	get_tree().current_scene.player_turn_started.connect(func() -> void: disabled = true)
	EventBus.lever_pulled.connect(func() -> void: disabled = Global.player.respin_tokens <= 0)
	EventBus.respin_count_updated.connect(
		func(tokens: int) -> void: disabled = tokens <= 0
	)

func _update_state() -> void:
	var has_not_spun: bool = !get_tree().current_scene.initial_spin_completed
	disabled = Global.player.respin_tokens <= 0 || has_not_spun
