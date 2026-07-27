extends CombatantData
class_name EnemyData

signal intent_updated

var intent: Dictionary = {}:  # { "type": "attack", "value": 10 }
	set(new_intent):
		intent = new_intent
		intent_updated.emit()

var portrait: Texture2D = load("res://icon.svg")
var custom_intent_str: String = "":
	set(new_intent_str):
		custom_intent_str = new_intent_str
		intent_updated.emit()

func _init() -> void:
	display_name = "Bad Guy"

func _choose_intent() -> void:
	# Pick next action and display it to player
	intent = { "type": "attack", "value": 10 }
	#_display_intent()

## The single path combat resolves enemies through. A non-"attack" intent
## yields no actions, which is how charge/wind-up turns telegraph without
## dealing damage.
func get_actions() -> Array[Action]:
	if intent.get("type") == "block":
		return [Action.new(Action.Type.DEFEND, intent.get("value", 0),
			"%s guards for %d" % [display_name, intent.get("value", 0)])]
	if intent.get("type") == "attack":
		return [Action.new(Action.Type.ATTACK, intent.get("value"), "Attacked player for %d damage!" % intent.get("value"))]
	return []
	
## States the intent plainly. Flavour belongs in art and animation, not in the
## one string the player reads to decide the turn — an enemy that says "the
## house always wins" is worse at its job than one that says "attacking for 18".
func get_intent_as_string() -> String:
	if custom_intent_str:
		return custom_intent_str
	if not intent:
		return "Waiting"
	var value: int = intent.get("value", 0)
	match intent.get("type"):
		"attack":
			return "Attacking for %d damage" % value
		"block":
			return "Gaining %d block" % value
	if intent.has("value"):
		return "%s for %d" % [str(intent.get("type")).capitalize(), value]
	return str(intent.get("type")).capitalize()
