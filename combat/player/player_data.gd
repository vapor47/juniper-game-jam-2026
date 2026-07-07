extends CombatantData
class_name PlayerData

#const BASE_SOLO_SPIN
var max_respin_tokens: int = 3
var respin_tokens: int = max_respin_tokens:
	set(new_value):
		if new_value < 0:
			push_error("Respin allowed when no tokens were available.")
		respin_tokens = new_value
		EventBus.respin_count_updated.emit(new_value)
