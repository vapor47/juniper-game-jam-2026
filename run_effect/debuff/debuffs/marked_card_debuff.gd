extends CurseSymbolDebuff
class_name MarkedCardDebuff

func _init() -> void:
	super(SymbolTable.MARKED_CARD)
	description = "A Marked Card joins your reel — -%d attack per copy on lock in" \
		% SymbolTable.MARKED_CARD_ATTACK_PENALTY
