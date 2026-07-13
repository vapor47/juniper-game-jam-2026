# ChargeEnemy.gd
extends EnemyData
class_name ChargeyGuyData

var turns_until_attack: int = 2


func _init() -> void:
	display_name = "Chargey Guy"
	max_health = 100
	health = max_health
	#_choose_intent()


func _choose_intent() -> void:
	if turns_until_attack <= 0:
		var dmg := 35
		custom_intent_str = "Attacking for " + str(dmg)
		intent = { "type": "attack", "value": dmg }
		turns_until_attack = 2
	else:
		custom_intent_str = "Charging... (%d %s)" % [turns_until_attack, "turn" if turns_until_attack == 1 else "turns"]
		intent = { "type": "charge", "value": turns_until_attack }
		turns_until_attack -= 1


func _execute_intent() -> void:
	match intent.get("type"):
		"attack":
			Global.player.take_damage(intent.value)
			turns_until_attack = 2  # reset
		"charge":
			pass  # does nothing, just telegraphing
