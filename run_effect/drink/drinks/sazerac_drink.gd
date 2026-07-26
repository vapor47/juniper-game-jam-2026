extends Drink
class_name SazeracDrink
## A Card Counter for one combat.

func _init() -> void:
	display_name = "Sazerac"
	description = "Combos count as +1 symbol this combat"
	rarity = Drink.Rarity.UNCOMMON
	alcohol_content = 15.0


func combo_count_bonus() -> int:
	return 1
