extends Control
class_name Shop

@onready var reel_modification_flow: ReelModificationFlow = $ReelModificationFlow
@onready var reels_container := %ReelsContainer
@onready var stat_upgrades_container := %StatUpgradesContainer
@onready var emergency_heal_container := %EmergencyHealContainer
@onready var reel_stop_modifiers_container := %ReelStopModifiersContainer
@onready var remove_reel_stop_container := %RemoveReelStopContainer
@onready var charms_container := %CharmsContainer
@onready var drinks_container := %DrinksContainer

const SHOP_ITEM_SCENE = preload("res://shop/item/shop_item.tscn")

const UPGRADE_POOL: Array[ShopItemData] = [
	preload("res://shop/item/upgrades/increase_active_slots.tres"),
	preload("res://shop/item/upgrades/increase_total_slots.tres"),
	preload("res://shop/item/upgrades/increase_token_cap.tres"),
	preload("res://shop/item/upgrades/increase_token_regen.tres"),
]

func _ready() -> void:
	_populate_shop()
	%GoldLabel.text = "Gold: %d" % Global.player.gold
	Global.player.gold_updated.connect(
		func(g: int) -> void:
			%GoldLabel.text = "Gold: %d" % g
	)

func _populate_shop() -> void:
	_populate_machine_modifications()
	_populate_misc_upgrades()


func _populate_container(container: BoxContainer, items: Array[ShopItemData]) -> void:
	for item_data: ShopItemData in items:
		var item: ShopItem = SHOP_ITEM_SCENE.instantiate()
		item.setup(item_data)
		item.purchase_requested.connect(_on_item_purchased)
		container.add_child(item)

func _on_item_purchased(item: ShopItemData) -> void:
	if not Global.player.can_afford(item):
		# TODO: play animation, cannot afford.
		return
	if item.purchased:
		return
	
	if item.requires_flow():
		reel_modification_flow.start(item.mod_action, item.get_flow_payload())
		reel_modification_flow.flow_finished.connect(_commit_purchase.bind(item), CONNECT_ONE_SHOT)
		reel_modification_flow.flow_aborted.connect(_cancel_purchase.bind(item), CONNECT_ONE_SHOT)
	else:
		item.on_purchase(Global.player)
		_commit_purchase(item)

func _commit_purchase(item: ShopItemData) -> void:
	Global.player.gold -= item.price
	_mark_sold(item)              # remove from stock / gray out the card
	#_refresh_shop_ui()            # gold display, affordability graying on remaining items
	# run-scoped bookkeeping where relevant, e.g. removal count increments,
	# though that arguably belongs in the removal item/flow itself

func _cancel_purchase(_item: ShopItemData) -> void:
	pass

func _mark_sold(item: ShopItemData) -> void:
	item.purchased = true


# ---------- MACHINE MODIFICATIONS ---------- #

func _populate_machine_modifications() -> void:
	_populate_reels()
	_populate_reel_modifications()

func _populate_reels() -> void:
	var reels_for_sale := _get_reels_for_sale()
	_populate_container(reels_container, reels_for_sale)

func _get_reels_for_sale(num_reels: int = 2) -> Array[ShopItemData]:
	"""
	Semi-randomly select reels.
	Weight factors:
		base reel rarity?
		if / how many reels of type player owns.
			If they own == max possible slots, is there purpose to showing them more?
			Can they benefit from more than max slots?
				Selling, sacrificing, gambling, etc
	"""
	var reels: Array[ShopItemData] = []
	for i in num_reels:
		# Get (semi)random reel
		# Create ShopItemData
		var random_reel: Reel = Global.reels.values().pick_random()
		reels.append(ReelShopItemData.create(random_reel))
	return reels

func _populate_reel_modifications() -> void:
	_populate_reel_stop_modifiers()
	_populate_reel_stops()
#	TODO: maybe change this to just button
	_populate_remove_reel_stop()

func _populate_reel_stop_modifiers() -> void:
	var modifiers_for_sale := _get_reel_stop_modifiers_for_sale()
	_populate_container(reel_stop_modifiers_container, modifiers_for_sale)

func _get_reel_stop_modifiers_for_sale(num_modifiers: int = 3) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for m: StopModifier in ModifierPool.roll(num_modifiers):
		items.append(ReelStopModifierShopItemData.create(m))
	return items

func _populate_reel_stops() -> void:
	var reel_stops_for_sale := _get_reel_stops_for_sale()
	_populate_container(reel_stop_modifiers_container, reel_stops_for_sale)

func _get_reel_stops_for_sale(num_stops: int = 3) -> Array[ShopItemData]:
	var stops: Array[ShopItemData] = []
	# Allow duplicate stops(?), but stop must belong to a reel that player currently owns
	# Get eligible symbol types
	var eligible_symbol_types_for_sale := _get_eligible_symbol_types()
	
	for i in num_stops:
		var random_symbol: SlotSymbol = Global.slot_symbols.values().pick_random()
		while random_symbol.get_symbol_type() not in eligible_symbol_types_for_sale:
			random_symbol = Global.slot_symbols.values().pick_random()
		
		stops.append(ReelStopShopItemData.create(random_symbol))
	
	return stops

func _get_eligible_symbol_types() -> Dictionary[SlotSymbol.SymbolType, bool]:
	var types: Dictionary[SlotSymbol.SymbolType, bool] = {}
	for reel_name: String in Global.player.get_reel_inventory():
		if Global.player.get_reel_inventory()[reel_name] <= 0:
			continue
		var reel: Reel = Global.reels.get(reel_name)
		for type in reel.allowed_symbol_types:
			types[type] = true
	return types
	
func _populate_remove_reel_stop() -> void:
	_populate_container(remove_reel_stop_container, [RemoveReelStopShopItemData.create()])

"""
In all 3 cases, we need to open a modal.
With add modifier, we need to pass the modifier
With add stop, we need to pass the stop
With remove, we don't need to pass anything.
	We do need to prevent player from selecting a reel with only 1 stop

Open Reel Select Modal for action -> Reel Selected (returns reel) ->
Start specific flow with provided reel (can return to reel selection screen) ->

For add modifier and remove stop, we need to highlight the stops themselves.
	Each stop is a pie slice / wedge shaped button. Upon selection, we perform appropriate action
		(either add modifier to stop, or remove stop)

For add stop, we need to highlight inbetween (insertion point)
	This can just be the index to insert at.
	Buttons are lines between stops?


Upon action completion, we exit all modals and return to shop screen.
"""

# ------------ MISC UPGRADES ------------ #

func _populate_misc_upgrades() -> void:
	_populate_stat_upgrades()
	_populate_charms()
	_populate_consumables()

func _populate_stat_upgrades() -> void:
	var upgrades_for_sale := _get_upgrades_for_sale()
	_populate_container(stat_upgrades_container, upgrades_for_sale)

func _get_upgrades_for_sale(num_upgrades: int = 2) -> Array[ShopItemData]:
	var upgrades: Array[ShopItemData] = []
	# TODO: prevent picking irrelevant / non-applicable upgrades
	for i in num_upgrades:
		var upgrade: ShopItemData = UPGRADE_POOL.pick_random()
		while upgrade in upgrades:
			upgrade = UPGRADE_POOL.pick_random()
		upgrades.append(upgrade)
	return upgrades

func _populate_charms() -> void:
	var charms_for_sale := _get_charms_for_sale()
	_populate_container(charms_container, charms_for_sale)

func _get_charms_for_sale(count: int = 2) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for c: Charm in CharmPool.roll(count):
		items.append(CharmShopItemData.create(c))
	return items

func _populate_consumables() -> void:
	_populate_drinks()
	_populate_emergency_heal()
	
func _populate_drinks() -> void:
	var drinks_for_sale := _get_drinks_for_sale()
	#_populate_container(drinks_container, drinks_for_sale)
	for item_data: ShopItemData in drinks_for_sale:
		var item: ShopItem = SHOP_ITEM_SCENE.instantiate()
		item.setup(item_data)
		item.purchase_requested.connect(_on_item_purchased)
		drinks_container.add_child(item)
		item.tooltip_text = ""
		HoverLabel.attach_to(item, item_data.description)
		item.mouse_entered.connect(
			func() -> void:
				HoverLabel.set_target_relative_pos(item, Vector2(-100,-100))
		)

func _get_drinks_for_sale(count: int = 5) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for d: Drink in DrinkPool.roll(count):
		items.append(DrinkShopItemData.create(d))
	return items
	
func _populate_emergency_heal() -> void:
	_populate_container(emergency_heal_container, [EmergencyHealShopItemData.create()])


func _on_continue_button_pressed() -> void:
	EventBus.shop_exited.emit()
