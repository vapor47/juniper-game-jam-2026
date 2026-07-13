extends CombatantData
class_name EnemyData

signal intent_updated

var intent: Dictionary = {}:  # { "type": "attack", "value": 10 }
	set(new_intent):
		intent = new_intent
		intent_updated.emit()

var portrait: Texture2D = load("res://icon.svg")
var custom_intent_str: String = ""

func _init() -> void:
	display_name = "Bad Guy"

func _choose_intent() -> void:
	# Pick next action and display it to player
	intent = { "type": "attack", "value": 10 }
	#_display_intent()

func _execute_intent() -> void:
	match intent.get("type"):
		"attack":
			if not Global.player:
				push_error("player is null")
			Global.player.take_damage(intent.get("value"))
		"block":
			block += intent.get("value")

func get_actions() -> Array[CombatManager.Action]:
	if intent.get("type") == "attack":
		return [CombatManager.Action.new(SlotSymbol.SymbolType.ATTACK, intent.get("value"), "Attacked player for %d damage!" % intent.get("value"))]
	return []
	
func make_move() -> void:
	#_execute_intent()
	_choose_intent()
	
func get_intent_as_string() -> String:
	if custom_intent_str:
		return custom_intent_str
	if not intent:
		return "No thoughts, head empty..."
	if intent.has("value"):
		return "Intends to " + intent.get("type") + " for " + str(intent.get("value"))
	return "Intends to " + intent.get("type")
