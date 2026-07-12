class_name DefendReel
extends Reel

func _init() -> void:
	reel_name = "Defend"
	# x4 Light, x3 Medium, x2 Heavy, x1 Multiply
	reel_stops = [
		ReelStop.new(Global.slot_symbols["Light Defend"]),
		ReelStop.new(Global.slot_symbols["Light Defend"]),
		ReelStop.new(Global.slot_symbols["Light Defend"]),
		ReelStop.new(Global.slot_symbols["Light Defend"]),
		ReelStop.new(Global.slot_symbols["Medium Defend"]),
		ReelStop.new(Global.slot_symbols["Medium Defend"]),
		ReelStop.new(Global.slot_symbols["Medium Defend"]),
		ReelStop.new(Global.slot_symbols["Heavy Defend"]),
		ReelStop.new(Global.slot_symbols["Heavy Defend"]),
		ReelStop.new(Global.slot_symbols["Multiply Defend"]),
		]
	#icon:
	description = "Reel containing defends"
	allowed_symbol_types = [SlotSymbol.SymbolType.DEFEND]
