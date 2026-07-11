class_name HealSlotSymbolBase
extends SlotSymbol

func get_symbol_type() -> SymbolType:
	return SymbolType.HEAL

func get_symbol_icon() -> Texture2D:
	return preload("res://at-icons_v1.3.0/addons/at-icons/control/plus_sign_in_square.svg")
