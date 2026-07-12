class_name AttackReel
extends Reel

func _init() -> void:
	reel_name = "Attack"
	# x4 Light, x3 Medium, x2 Heavy, x1 Multiply
	reel_stops = [
		ReelStop.new(Global.slot_symbols["Light Attack"]),
		ReelStop.new(Global.slot_symbols["Light Attack"]),
		ReelStop.new(Global.slot_symbols["Light Attack"]),
		ReelStop.new(Global.slot_symbols["Light Attack"]),
		ReelStop.new(Global.slot_symbols["Medium Attack"]),
		ReelStop.new(Global.slot_symbols["Medium Attack"]),
		ReelStop.new(Global.slot_symbols["Medium Attack"]),
		ReelStop.new(Global.slot_symbols["Heavy Attack"]),
		ReelStop.new(Global.slot_symbols["Heavy Attack"]),
		ReelStop.new(Global.slot_symbols["Multiply Attack"]),
		]
	#icon:
	description = "Reel containing attacks"
	allowed_symbol_types = [SlotSymbol.SymbolType.ATTACK]
