extends Drink
class_name OldFashionedDrink

"""
Maybe something to do with time? Old timey?
"""

func _init() -> void:
	display_name = "Old Fashioned"
	description = "+1 to every stop value next combat"
	rarity = Charm.Rarity.COMMON

func modify_stop_value(v: int, _ctx: ResolutionContext, _stop: ReelStop) -> int:
	return v + 1
