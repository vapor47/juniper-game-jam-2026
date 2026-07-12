# loaded_dice_modifier.gd
extends StopModifier
class_name LoadedDiceModifier

func _init() -> void:
	display_name = "Loaded Dice"
	description = "50/50: doubled or nothing"

func modify_stop_value(base_value: int, _ctx: ResolutionContext, _stop: ReelStop) -> int:
	return base_value * 2 if randf() < 0.5 else 0
