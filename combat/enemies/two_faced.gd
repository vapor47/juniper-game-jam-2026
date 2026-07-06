extends EnemyData
class_name TwoFacedData

#const INTENTS = [
	#{ "type": attack, "value": curr_attack_val},
	#{ "type": }
#]
enum CoinTossResult { HEADS, TAILS }
const BASE_ATTACK_VAL: int = 4
var curr_attack_val: int = BASE_ATTACK_VAL

func _init() -> void:
	display_name = "Two Faced"
	max_health = 200
	health = max_health
	_choose_intent()
	
func _choose_intent() -> void:
	"""
	50/50 chance to attack, or charge attack
	"""
	
	intent = { "type": "toss a coin" }
	custom_intent_str = "???"
	

func _execute_intent() -> void:
	var result: CoinTossResult = CoinTossResult.values().pick_random()
	if result == CoinTossResult.HEADS:
		curr_attack_val *= 2
		print_debug("Flipped Heads: Attack charged")
	else:
		print_debug("Flipped Tails: Attacking for " + str(curr_attack_val))
		Global.player.take_damage(curr_attack_val)
		curr_attack_val = BASE_ATTACK_VAL
