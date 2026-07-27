extends CurseSymbolDebuff
class_name LiveWireDebuff

func _init() -> void:
	super(SymbolTable.LIVE_WIRE)
	refresh_text()

func damage_per_copy() -> int:
	return SymbolTable.LIVE_WIRE_DAMAGE_PER_LEVEL * level

func describe() -> String:
	return "%d damage per copy showing, every spin" % damage_per_copy()
