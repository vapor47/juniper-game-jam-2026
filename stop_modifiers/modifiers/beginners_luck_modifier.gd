# beginners_luck_modifier.gd
extends StopModifier
class_name BeginnersLuckModifier

func _init() -> void:
	display_name = "Beginner's Luck"
	description = "Doubled value on the initial pull"

func modify_stop_value(base_value: int, ctx: ResolutionContext, _stop: ReelStop) -> int:
	return base_value * 2 if ctx.is_initial_spin else base_value
