class_name HeavyAttack
extends AttackSlotSymbolBase

const BASE_HEAVY_ATTACK_VALUE = 12

func _init() -> void:
	symbol_name = "Heavy Attack"
	symbol_value = BASE_HEAVY_ATTACK_VALUE
	icon = preload("res://assets/icons/heavy_attack_icon.svg")
