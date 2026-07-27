extends CurseSymbolDebuff
class_name LiveWireDebuff

func _init() -> void:
	super(SymbolTable.LIVE_WIRE)
	description = "A Live Wire joins your reel — %d damage per copy, every spin" \
		% SymbolTable.LIVE_WIRE_DAMAGE
