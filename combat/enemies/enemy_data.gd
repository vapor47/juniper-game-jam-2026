extends CombatantData
class_name EnemyData

var intent: Dictionary = {}  # { "type": "attack", "value": 10 }
var portrait: Texture2D = load("res://icon.svg")

func _init() -> void:
	display_name = "Bad Guy"

func _choose_intent() -> void:
	# Pick next action and display it to player
	intent = { "type": "attack", "value": 10 }
	#_display_intent()

func _execute_intent() -> void:
	print_debug("enemy executing intent")
	match intent.get("type"):
		"attack":
			print_debug("player taken damage")
			if not Global.player:
				print_debug("player is null")
			Global.player.take_damage(intent.get("value"))
		"block":
			block += intent.get("value")

func make_move() -> void:
	_execute_intent()
	_choose_intent()
	
func get_intent_as_string() -> String:
	if not intent:
		return "No thoughts, head empty..."
	return "Intends to " + intent.get("type") + " for " + str(intent.get("value"))
