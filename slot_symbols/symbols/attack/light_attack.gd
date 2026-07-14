class_name LightAttack
extends AttackSlotSymbolBase

const BASE_LIGHT_ATTACK_VALUE = 4

func _init() -> void:
	symbol_name = "Light Attack"
	symbol_value = BASE_LIGHT_ATTACK_VALUE
	icon = preload("res://assets/icons/light_attack_icon.svg")
