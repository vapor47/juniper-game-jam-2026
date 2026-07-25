extends Control
class_name Shop

@onready var stat_upgrades_container := %StatUpgradesContainer
@onready var emergency_heal_container := %EmergencyHealContainer
@onready var stops_container := %StopsContainer
@onready var remove_stop_container := %RemoveStopContainer
@onready var souvenirs_container := %SouvenirsContainer
@onready var drinks_container := %DrinksContainer

const STRIP_EDITOR_SCENE = preload("res://shop/strip_editor.tscn")

const SHOP_ITEM_SCENE = preload("res://shop/item/shop_item.tscn")

const UPGRADE_POOL: Array[ShopItemData] = [
	preload("res://shop/item/upgrades/increase_active_slots.tres"),
	preload("res://shop/item/upgrades/increase_total_slots.tres"),
	preload("res://shop/item/upgrades/increase_token_cap.tres"),
	preload("res://shop/item/upgrades/increase_token_regen.tres"),
]

var drinks_bought_this_visit: int = 0

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
		drinks_bought_this_visit += 1
		# update ui price

func _cancel_purchase(_item: ShopItemData) -> void:
	pass

func _mark_sold(item: ShopItemData) -> void:
	item.purchased = true

func display_price(item: ShopItemData) -> int:
	if not Global.player.owns_souvenir(LoyaltyCardSouvenir):
		return item.price
	var discount := clampf(LoyaltyCardSouvenir.DISCOUNT_INCREMENT * drinks_bought_this_visit, 0.0, 1.0)
	return roundi(item.price * (1.0 - discount))


# ---------- MACHINE MODIFICATIONS ---------- #

## Three verbs, all acting on the one shared strip (§6):
##   Remove  — strongest, shortens the strip; separate, pricier service.
##   Replace — the workhorse; same purchase and price as Add.
##   Add     — weakest, charges dilution on everything else.
## Replace and Add are the same buy: placement decides which one it was.
func _populate_machine_modifications() -> void:
	_populate_stops()
	_populate_remove_stop()


func _populate_stops() -> void:
	_populate_container(stops_container, _get_stops_for_sale())


func _get_stops_for_sale(num_stops: int = 3) -> Array[ShopItemData]:
	var pool := SymbolTable.purchasable()
	pool.shuffle()
	var items: Array[ShopItemData] = []
	for symbol: Symbol in pool.slice(0, num_stops):
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
	for i in num_upgrades:
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
	for c: Souvenir in SouvenirPool.roll(count):
		items.append(SouvenirShopItemData.create(c))
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
