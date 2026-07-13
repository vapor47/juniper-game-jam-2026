extends EnemyData
class_name DestituteGamblerData

func _init() -> void:
	display_name = "Destitute Gambler"
	max_health = 100
	health = max_health
	
func _choose_intent() -> void:
	intent = { "type": "attack", "value": randi_range(4, 18) }
