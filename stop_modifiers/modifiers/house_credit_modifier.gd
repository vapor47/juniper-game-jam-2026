# house_credit_modifier.gd
extends StopModifier
class_name HouseCreditModifier

func _init() -> void:
	display_name = "House Credit"
	description = "50% to refund the token when spun away"

func on_spun_away(ctx: ResolutionContext, _stop: ReelStop) -> void:
	if randf() < 0.5:
		ctx.player.respin_tokens += 1
