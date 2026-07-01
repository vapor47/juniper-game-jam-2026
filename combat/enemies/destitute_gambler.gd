extends EnemyData
class_name DestituteGamblerData

func _init() -> void:
	display_name = "Destitute Gambler"
	_choose_intent()
	
func _choose_intent() -> void:
	intent = { "type": "attack", "value": randi_range(1, 15) }
