# matching_cufflinks_modifier.gd
extends StopModifier
class_name MatchingCufflinksModifier

func _init() -> void:
	display_name = "Matching Cufflinks"
	description = "Combos with this stop count as +1 symbol"

func combo_count_bonus() -> int:
	return 1
