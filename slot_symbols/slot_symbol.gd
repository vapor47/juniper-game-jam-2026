class_name SlotSymbol
extends RefCounted

# TODO: Move elsewhere?
enum SymbolType { ATTACK, DEFEND, HEAL }

var symbol_name: String
var symbol_value: int = 0
var result_modifier: Callable
var icon: Texture2D
	
func _init() -> void:
	# TODO: remove symbol_name setters from child classes and write tests
	symbol_name = str(get_script().get_global_name()).capitalize()
	

func get_symbol_type() -> SymbolType:
	push_error("CRITICAL: get_symbol_type() was called on a base class without being overridden!")
	return SymbolType.ATTACK 

func get_symbol_icon() -> Texture2D:
	push_error("CRITICAL: get_symbol_icon() was called on a base class without being overridden!")
	return preload("res://assets/icons/icon.svg")
