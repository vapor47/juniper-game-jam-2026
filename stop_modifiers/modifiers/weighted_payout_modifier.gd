# weighted_payout_modifier.gd
extends StopModifier
class_name WeightedPayoutModifier

func _init() -> void:
	display_name = "Weighted Payout"
	description = "+4 to the final result when selected"

func modify_result_total(total: int, _ctx: ResolutionContext, _stop: ReelStop) -> int:
	return total + 4
