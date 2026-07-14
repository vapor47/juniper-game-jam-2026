extends Charm
class_name CardCounterCharm

func _init() -> void:
	display_name = "Card Counter"
	description = "Combos count as +1 symbol"
	rarity = Charm.Rarity.RARE

func combo_count_bonus() -> int:
	return 1
