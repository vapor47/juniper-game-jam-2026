extends RefCounted
class_name TurnContext

var combat: CombatContext

func _init(combat_context: CombatContext) -> void:
	combat = combat_context
