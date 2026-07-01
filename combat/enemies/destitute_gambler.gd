extends EnemyData
class_name DestituteGamblerData

func choose_intent() -> void:
	intent = { "type": "attack", "value": randi_range(1, 15) }
