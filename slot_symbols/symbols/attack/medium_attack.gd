class_name MediumAttack
extends AttackSlotSymbolBase

const BASE_MEDIUM_ATTACK_VALUE = 8

func _init() -> void:
	symbol_name = "Medium Attack"
	symbol_value = BASE_MEDIUM_ATTACK_VALUE
	icon = preload("res://assets/icons/medium_attack_icon.svg")
