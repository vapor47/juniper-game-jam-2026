extends EnemyData
class_name PitBossData

func _init() -> void:
	display_name = "The Pit Boss"
	max_health = 1000
	health = max_health
	_choose_intent()
	
func _choose_intent() -> void:
	intent = { "type": "attack", "value": 100 }
	
