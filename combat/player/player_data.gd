extends CombatantData
class_name PlayerData

# Tokens
var token_regen_per_turn: int = 1
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

# Slots
const MAX_TOTAL_SLOTS: int = 8
var total_slots: int = 5:
	set(new_value):
		if new_value < 1:
			push_error("Total slots should never go below 1")
			total_slots = 1
			return
		if new_value > MAX_TOTAL_SLOTS:
			push_error("Cannot exceed max slots")
		total_slots = min(new_value, MAX_TOTAL_SLOTS)

var max_active_slots: int = 3:
	set(new_value):
		if new_value < 1:
			push_error("Active slots should never go below 1")
			max_active_slots = 1
			return
		if new_value > total_slots:
			push_error("Maximum Active Slots cannot exceed current Total Slots")
		max_active_slots = min(new_value, total_slots)


var gold: int = 1000


func _init() -> void:
	display_name = "Player"
	
func replenish_tokens() -> void:
	tokens = max_tokens

func regen_tokens() -> void:
	tokens += token_regen_per_turn

func can_afford(item: ShopItemData) -> bool:
	return item.price <= gold
