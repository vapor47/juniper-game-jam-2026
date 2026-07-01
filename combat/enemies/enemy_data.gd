extends CombatantData
class_name EnemyData

var intent: Dictionary = {}  # { "type": "attack", "value": 10 }
var portrait: Texture2D = load("res://icon.svg")

func _init() -> void:
	display_name = "Bad Guy"
	_choose_intent()

func _choose_intent() -> void:
	# Pick next action and display it to player
	intent = { "type": "attack", "value": 10 }
	#_display_intent()

#func _display_intent() -> void:
	#var new_label := Label.new()
	#new_label.text = "Intends to " + intent.type + " for " + str(intent.value)
	#add_child(new_label)
	
func _execute_intent() -> void:
	print_debug("enemy executing intent")
	match intent.get("type"):
		"attack":
			print_debug("player taken damage")
			if not Global.player:
				print_debug("player is null")
			Global.player.take_damage(intent.value)
		"block":
			block += intent.value

func make_move() -> void:
	_execute_intent()
	_choose_intent()
	
func get_intent_as_string() -> String:
	return "Intends to " + intent.type + " for " + str(intent.value)
