extends CombatantData
class_name PlayerData

#const BASE_SOLO_SPIN
var max_respin_tokens: int = 3
var respin_tokens: int = max_respin_tokens:
	set(new_value):
		if new_value < 0:
			push_error("Respin allowed when no tokens were available.")
			return
		if new_value > max_respin_tokens:
			print_debug("Cannot exceed max tokens")
		respin_tokens = min(new_value, max_respin_tokens)
		EventBus.respin_count_updated.emit(respin_tokens)

var token_regen_per_turn: int = 1

func replenish_tokens() -> void:
	respin_tokens = max_respin_tokens

func regen_tokens() -> void:
	respin_tokens += token_regen_per_turn
