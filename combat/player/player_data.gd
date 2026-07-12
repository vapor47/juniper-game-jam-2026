extends CombatantData
class_name PlayerData


var max_tokens: int = 3
var tokens: int = max_tokens:
	set(new_value):
		if new_value < 0:
			push_error("Token(s) spent when no tokens were available.")
			return
		if new_value > max_tokens:
			print_debug("Cannot exceed max tokens")
		tokens = min(new_value, max_tokens)
		EventBus.token_count_updated.emit(tokens)

var token_regen_per_turn: int = 1

var gold: int = 100


func _init() -> void:
	display_name = "Player"
	
func replenish_tokens() -> void:
	tokens = max_tokens

func regen_tokens() -> void:
	tokens += token_regen_per_turn
