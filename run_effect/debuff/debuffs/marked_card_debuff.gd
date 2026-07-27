extends CurseSymbolDebuff
class_name MarkedCardDebuff

func _init() -> void:
	super(SymbolTable.MARKED_CARD)
	refresh_text()

func damage_per_copy() -> int:
	return SymbolTable.MARKED_CARD_DAMAGE_PER_LEVEL * level

func describe() -> String:
	return "%d damage per copy on a line you play" % damage_per_copy()
