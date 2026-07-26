extends Control
class_name Shop

@onready var stat_upgrades_container := %StatUpgradesContainer
@onready var emergency_heal_container := %EmergencyHealContainer
@onready var stops_container := %StopsContainer
@onready var modifiers_container := %ModifiersContainer
@onready var remove_stop_container := %RemoveStopContainer
@onready var souvenirs_container := %SouvenirsContainer
@onready var drinks_container := %DrinksContainer

const STRIP_EDITOR_SCENE = preload("res://shop/strip_editor.tscn")

const SHOP_ITEM_SCENE = preload("res://shop/item/shop_item.tscn")

const UPGRADE_POOL: Array[ShopItemData] = [
	preload("res://shop/item/upgrades/increase_line_cap.tres"),
	preload("res://shop/item/upgrades/increase_token_cap.tres"),
	preload("res://shop/item/upgrades/increase_token_regen.tres"),
]

func _ready() -> void:
	Global.player.drinks_bought_this_visit = 0
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
		# ShopItem._ready() fills tooltip_text from the description; clear it so
		# the built-in tooltip doesn't double up with the HoverLabel, which
		# follows the cursor and appears without a delay.
		item.tooltip_text = ""
		HoverLabel.attach_to(item, item_data.description)

func _on_item_purchased(item: ShopItemData) -> void:
	if not Global.player.can_afford(item):
		# TODO: play animation, cannot afford.
		return
	if item.purchased:
		return
	
	if item.requires_flow():
		_open_strip_editor(item)
	else:
		item.on_purchase(Global.player)
		_commit_purchase(item)


## Buy-a-stop-then-place, and the removal service, both resolve on the strip
## itself — gold is only spent once an edit is actually committed (§6).
func _open_strip_editor(item: ShopItemData) -> void:
	var editor: StripEditor = STRIP_EDITOR_SCENE.instantiate()
	if item is StopShopItemData:
		editor.setup(StripEditor.Mode.PLACE, (item as StopShopItemData).symbol)
	elif item is StopModifierShopItemData:
		editor.setup_modifier((item as StopModifierShopItemData).modifier)
	else:
		editor.setup(StripEditor.Mode.REMOVE)

	editor.edit_committed.connect(func() -> void:
		editor.queue_free()
		_commit_purchase(item))
	editor.cancelled.connect(func() -> void:
		editor.queue_free()
		_cancel_purchase(item))
	add_child(editor)

func _commit_purchase(item: ShopItemData) -> void:
	Global.player.gold -= display_price(item)
	_mark_sold(item)              # remove from stock / gray out the card
	#_refresh_shop_ui()            # gold display, affordability graying on remaining items
	# run-scoped bookkeeping where relevant, e.g. removal count increments,
	# though that arguably belongs in the removal item/flow itself

	if item is DrinkShopItemData:
		Global.player.drinks_bought_this_visit += 1

func _cancel_purchase(_item: ShopItemData) -> void:
	pass

func _mark_sold(item: ShopItemData) -> void:
	item.purchased = true

## How many items to stock in a category, after any effect that widens the
## shelf (Retail Therapy).
func _stock_for(category: StringName, base: int) -> int:
	var count := base
	for effect: RunEffect in Global.player.get_active_effects():
		count = effect.modify_shop_stock(count, category)
	return maxi(0, count)


## Runs the price through every owned effect's modify_shop_price hook, so any
## souvenir can discount. Loyalty Card used to be hardcoded here, which left
## Frequent Flyer — whose only effect is that hook — doing nothing at all.
func display_price(item: ShopItemData) -> int:
	var price := item.price
	for effect: RunEffect in Global.player.get_active_effects():
		price = effect.modify_shop_price(price, item)
	return maxi(0, price)


# ---------- MACHINE MODIFICATIONS ---------- #

## Three verbs, all acting on the one shared strip (§6):
##   Remove  — strongest, shortens the strip; separate, pricier service.
##   Replace — the workhorse; same purchase and price as Add.
##   Add     — weakest, charges dilution on everything else.
## Replace and Add are the same buy: placement decides which one it was.
func _populate_machine_modifications() -> void:
	_populate_stops()
	_populate_modifiers()
	_populate_remove_stop()


func _populate_modifiers() -> void:
	_populate_container(modifiers_container, _get_modifiers_for_sale())


func _get_modifiers_for_sale(num_modifiers: int = 2) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for m: StopModifier in ModifierPool.roll(_stock_for(&"modifiers", num_modifiers)):
		items.append(StopModifierShopItemData.create(m))
	return items


func _populate_stops() -> void:
	_populate_container(stops_container, _get_stops_for_sale())


func _get_stops_for_sale(num_stops: int = 3) -> Array[ShopItemData]:
	var pool := SymbolTable.purchasable()
	pool.shuffle()
	var items: Array[ShopItemData] = []
	for symbol: Symbol in pool.slice(0, _stock_for(&"stops", num_stops)):
		items.append(StopShopItemData.create(symbol))
	return items


func _populate_remove_stop() -> void:
	_populate_container(remove_stop_container, [RemoveStopShopItemData.create()])

# ------------ MISC UPGRADES ------------ #

func _populate_misc_upgrades() -> void:
	_populate_stat_upgrades()
	_populate_souvenirs()
	_populate_consumables()

func _populate_stat_upgrades() -> void:
	var upgrades_for_sale := _get_upgrades_for_sale()
	_populate_container(stat_upgrades_container, upgrades_for_sale)

func _get_upgrades_for_sale(num_upgrades: int = 2) -> Array[ShopItemData]:
	var upgrades: Array[ShopItemData] = []
	# TODO: prevent picking irrelevant / non-applicable upgrades
	var wanted := mini(_stock_for(&"upgrades", num_upgrades), UPGRADE_POOL.size())
	for i in wanted:
		var upgrade: ShopItemData = UPGRADE_POOL.pick_random()
		while upgrade in upgrades:
			upgrade = UPGRADE_POOL.pick_random()
		upgrades.append(upgrade)
	return upgrades

func _populate_souvenirs() -> void:
	var souvenirs_for_sale := _get_souvenirs_for_sale()
	_populate_container(souvenirs_container, souvenirs_for_sale)

func _get_souvenirs_for_sale(count: int = 2) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for c: Souvenir in SouvenirPool.roll(_stock_for(&"souvenirs", count)):
		items.append(SouvenirShopItemData.create(c))
	return items

func _populate_consumables() -> void:
	_populate_drinks()
	_populate_emergency_heal()
	
func _populate_drinks() -> void:
	_populate_container(drinks_container, _get_drinks_for_sale())
	# Drinks sit low against the bar art, so pin their readout above the card
	# rather than letting it follow the cursor down off the shelf.
	for item: ShopItem in drinks_container.get_children():
		item.mouse_entered.connect(
			func() -> void:
				HoverLabel.set_target_relative_pos(item, Vector2(-100, -100))
		)

func _get_drinks_for_sale(count: int = 5) -> Array[ShopItemData]:
	var items: Array[ShopItemData] = []
	for d: Drink in DrinkPool.roll(_stock_for(&"drinks", count)):
		items.append(DrinkShopItemData.create(d))
	return items
	
func _populate_emergency_heal() -> void:
	_populate_container(emergency_heal_container, [EmergencyHealShopItemData.create()])


func _on_continue_button_pressed() -> void:
	EventBus.shop_exited.emit()
