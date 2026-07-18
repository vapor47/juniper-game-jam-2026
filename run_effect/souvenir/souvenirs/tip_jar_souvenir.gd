extends Souvenir
class_name CardCounterSouvenir

func _init() -> void:
	display_name = "Card Counter"
	description = "Combos count as +1 symbol"
	rarity = Souvenir.Rarity.RARE

func combo_count_bonus() -> int:
	return 1
