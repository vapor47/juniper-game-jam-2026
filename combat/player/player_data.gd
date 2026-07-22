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

signal gold_updated(gold: int)
var gold: int = BASE_GOLD:
	set(new_gold):
		gold = new_gold
		gold_updated.emit(new_gold)

var owned_souvenirs: Array[Souvenir] = []
var active_drinks: Array[Drink] = []
var expired_drinks: Array[Drink] = []
var drunkenness: float = 0.0:
	set(value):
		drunkenness = clampf(value, 0.0, 100.0)

signal reel_inventory_updated(new_inventory: Dictionary[String, int])
var _reel_inventory: Dictionary[String, int]

func get_active_effects() -> Array[RunEffect]:
	return owned_souvenirs + active_drinks

func get_num_drinks_consumed() -> int:
	return active_drinks.size() + expired_drinks.size()


func _init() -> void:
	display_name = "Player"
	_reel_inventory = {
		"Attack": 3,
		"Defend": 3,
		"Heal": 0,
	}
	
func replenish_tokens() -> void:
	tokens = max_tokens

func regen_tokens() -> void:
	tokens += token_regen_per_turn

func can_afford(item: ShopItemData) -> bool:
	return item.price <= gold


func consume_drink(d: Drink) -> void:
	active_drinks.append(d)
	EventBus.run_effect_added.emit(d)
	
func add_souvenir(c: Souvenir) -> void:
	owned_souvenirs.append(c)
	EventBus.run_effect_added.emit(c)

func owns_souvenir(type: GDScript) -> bool:
	for s: Souvenir in owned_souvenirs:
		if is_instance_of(s, type):
			return true
	return false

func broadcast(method: StringName, args: Array = []) -> void:
	for e: RunEffect in get_active_effects():
		e.callv(method, args)
	# sweep expirations after combat-end broadcasts
	#active_drinks = active_drinks.filter(func(e): return not e.is_expired())
	# (emit run_effect_removed for UI as needed)

func get_reel_inventory() -> Dictionary[String, int]:
	return _reel_inventory

func add_reel_to_inventory(reel: Reel) -> bool:
	if RunManager.is_resetting:
		return false
	if not reel:
		return false
	_reel_inventory[reel.reel_name] = _reel_inventory.get(reel.reel_name, 0) + 1
	reel_inventory_updated.emit(_reel_inventory)
	return true

func remove_reel_from_inventory(reel: Reel) -> bool:
	if RunManager.is_resetting:
		return false
	if not reel:
		return false
	if _reel_inventory.get(reel.reel_name, 0) <= 0:
		return false
	_reel_inventory[reel.reel_name] -= 1
	reel_inventory_updated.emit(_reel_inventory)
	return true

func apply_debuff(debuff: Debuff) -> void:
	print_debug("Debuff Applied! (%s)" % debuff.display_name)
	debuff.on_acquired(self)

"""
Debuff flavor line ideas: (First or Third person?)
	You feel the alcohol getting to you.
	Your vision begins to blur
	I'm feeling a little dizzy
	I'm good Ociffer! *belches*
	Goddamn that shit got me fucked up
	That one felt a little strong
"""
