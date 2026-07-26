extends CombatantData
class_name PlayerData

# BASE STATE
const BASE_TOKEN_REGEN_PER_TURN = 1
## Tokens are a persistent pool across the fight, and every spend is meant to
## be a comparison against future turns (§5). The cap has to leave room to
## actually bank: a 3rd line costs 4 on top of the 2nd's 2, so a cap of 3
## would make it unreachable and the line cap dead content. Line pricing
## against real income is an explicit playtest question (§12).
const BASE_MAX_TOKENS = 10
## What each combat opens with — deliberately well under the cap, so banking
## toward a second/third line is a real multi-turn decision rather than
## something the opening hand already affords.
const BASE_STARTING_TOKENS = 3
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

signal gold_updated(gold: int)
var gold: int = BASE_GOLD:
	set(new_gold):
		gold = new_gold
		gold_updated.emit(new_gold)

var owned_souvenirs: Array[Souvenir] = []
var active_drinks: Array[Drink] = []
var expired_drinks: Array[Drink] = []
var active_debuffs: Array[Debuff] = []

## Pattern inventory (§4): which line *shapes* the run owns, grown permanently.
## Distinct from how many are played in a given turn, which is bought per turn.
var owned_paylines: Array[Payline] = []

## Most lines playable in one turn (§4). Souvenirs raise the cap; they never
## cut the price.
const BASE_MAX_LINES_PER_TURN: int = 3
var max_lines_per_turn: int = BASE_MAX_LINES_PER_TURN

## Reset by the shop on entry. Loyalty Card's discount stacks off this, and
## the hook has no shop reference to read it from.
var drinks_bought_this_visit: int = 0

var drunkenness: float = 0.0:
	set(value):
		drunkenness = clampf(value, 0.0, 100.0)

## Concatenating the three typed arrays yields an untyped Array, which can't be
## returned as Array[RunEffect] — build the typed array explicitly.
func get_active_effects() -> Array[RunEffect]:
	var out: Array[RunEffect] = []
	out.append_array(owned_souvenirs)
	out.append_array(active_drinks)
	out.append_array(active_debuffs)
	return out

func get_num_drinks_consumed() -> int:
	return active_drinks.size() + expired_drinks.size()


func _init() -> void:
	display_name = "Player"
	owned_paylines = PaylineCatalog.starting_paylines()


func owns_payline(p: Payline) -> bool:
	return p in owned_paylines


func add_payline(p: Payline) -> bool:
	if p == null or owns_payline(p):
		return false
	owned_paylines.append(p)
	return true

func replenish_tokens() -> void:
	tokens = mini(BASE_STARTING_TOKENS, max_tokens)

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
	if method == "on_combat_ended":
		drunkenness -= 15
		_sweep_expired_drinks()


## Drinks last a combat. combats_remaining was counting down but nothing acted
## on it, so every drink was permanent.
func _sweep_expired_drinks() -> void:
	var still_active: Array[Drink] = []
	for d: Drink in active_drinks:
		if d.is_expired():
			d.on_removed(self)
			expired_drinks.append(d)
		else:
			still_active.append(d)
	active_drinks = still_active

func apply_debuff(debuff: Debuff) -> void:
	print_debug("Debuff Applied! (%s)" % debuff.display_name)
	Toast.show_debuff(debuff.display_name, debuff.description, "", "\"That one felt a little strong...\"")
	debuff.on_acquired(self)
	active_debuffs.append(debuff)

func remove_debuff(debuff: Debuff) -> void:
	active_debuffs.remove_at(active_debuffs.find(debuff))
	debuff.on_removed(self)
	

"""
Debuff flavor line ideas: (First or Third person?)
	You feel the alcohol getting to you.
	Your vision begins to blur
	I'm feeling a little dizzy
	I'm good Ociffer! *belches*
	Goddamn that shit got me fucked up
	That one felt a little strong
"""
