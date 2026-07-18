class_name HealReel
extends Reel

func _init() -> void:
	reel_name = "Heal"
	# x4 Light, x3 Medium, x2 Heavy, x1 Multiply
	reel_stops = [
		ReelStop.new(Global.slot_symbols["Light Heal"]),
		ReelStop.new(Global.slot_symbols["Light Heal"]),
		ReelStop.new(Global.slot_symbols["Light Heal"]),
		ReelStop.new(Global.slot_symbols["Light Heal"]),
		ReelStop.new(Global.slot_symbols["Medium Heal"]),
		ReelStop.new(Global.slot_symbols["Medium Heal"]),
		ReelStop.new(Global.slot_symbols["Medium Heal"]),
		ReelStop.new(Global.slot_symbols["Heavy Heal"]),
		ReelStop.new(Global.slot_symbols["Heavy Heal"]),
		ReelStop.new(Global.slot_symbols["Multiply Heal"]),
		]
	#icon:
	description = "Reel containing heals"
	allowed_symbol_types = [Action.Type.HEAL]
