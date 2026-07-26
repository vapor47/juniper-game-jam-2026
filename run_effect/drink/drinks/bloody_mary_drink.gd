extends Drink
class_name BloodyMaryDrink
## Old Fashioned pointed at one half of the board — all offence, no defence.

const BONUS := 2


func _init() -> void:
	display_name = "Bloody Mary"
	description = "+%d to every attack stop this combat" % BONUS
	rarity = Drink.Rarity.UNCOMMON
	alcohol_content = 15.0


func modify_stop_value(v: int, _ctx: ResolutionContext, stop: Stop) -> int:
	return v + BONUS if stop.symbol.type == Action.Type.ATTACK else v
