# weighted_payout_modifier.gd
extends StopModifier
class_name WeightedPayoutModifier

func _init() -> void:
	display_name = "Weighted Payout"
	description = "+4 to the final result when selected"

## Only attack, block and heal carry a result total for this to add to — gold
## and token payouts bypass it entirely. Without this guard the modifier could
## be bought and attached to a Coin or Token stop, cost gold, and silently do
## nothing at all.
func can_apply(stop: Stop) -> bool:
	return stop.symbol.type in [Action.Type.ATTACK, Action.Type.DEFEND, Action.Type.HEAL]


func modify_result_total(total: int, _ctx: ResolutionContext, _stop: Stop) -> int:
	return total + 4
