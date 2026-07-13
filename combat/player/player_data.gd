extends CombatantData
class_name PlayerData

# BASE STATE
const BASE_TOKEN_REGEN_PER_TURN = 1
const BASE_MAX_TOKENS = 3
const BASE_TOTAL_SLOTS = 5
const BASE_MAX_ACTIVE_SLOTS = 3
const BASE_GOLD = 1000


# Tokens
var token_regen_per_turn: int = BASE_TOKEN_REGEN_PER_TURN
var max_tokens: int = BASE_MAX_TOKENS
var tokens: int = max_tokens:
	set(new_value):
		if new_value < 0:
			push_error("Token(s) spent when no tokens were available.")
			return
		if new_value > max_tokens:
			print_debug("Cannot exceed max tokens")
		tokens = min(new_value, max_tokens)
		EventBus.token_count_updated.emit(tokens)

# Slots
const MAX_TOTAL_SLOTS: int = 8
var total_slots: int = BASE_TOTAL_SLOTS:
	set(new_value):
		if new_value < 1:
			push_error("Total slots should never go below 1")
			total_slots = 1
			return
		if new_value > MAX_TOTAL_SLOTS:
			push_error("Cannot exceed max slots")
		total_slots = min(new_value, MAX_TOTAL_SLOTS)

var max_active_slots: int = BASE_MAX_ACTIVE_SLOTS:
	set(new_value):
		if new_value < 1:
			push_error("Active slots should never go below 1")
			max_active_slots = 1
			return
		if new_value > total_slots:
			push_error("Maximum Active Slots cannot exceed current Total Slots")
		max_active_slots = min(new_value, total_slots)


var gold: int = BASE_GOLD


func _init() -> void:
	display_name = "Player"
	
func replenish_tokens() -> void:
	tokens = max_tokens

func regen_tokens() -> void:
	tokens += token_regen_per_turn

func can_afford(item: ShopItemData) -> bool:
	return item.price <= gold

#func reset():
	#token_regen_per_turn = BASE_TOKEN_REGEN_PER_TURN
	#max_tokens = BASE_MAX_TOKENS
	#tokens = max_tokens
	
