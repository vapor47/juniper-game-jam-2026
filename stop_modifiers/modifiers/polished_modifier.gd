# polished_modifier.gd
extends StopModifier
class_name PolishedModifier

var amount: int

func _init(p_amount: int = 2) -> void:
	amount = p_amount
	display_name = "Polished" if p_amount <= 2 else "Gilded"
	description = "+%d to this stop's value" % p_amount

func can_apply(stop: ReelStop) -> bool:
	return stop.slot_symbol.symbol_value > 0  # rejects multiply stops

func modify_stop_value(base_value: int, _ctx: ResolutionContext, _stop: ReelStop) -> int:
	return base_value + amount
