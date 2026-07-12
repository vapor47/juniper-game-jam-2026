extends Control

@onready var reels_container := %ReelsContainer
@onready var stat_upgrades_container := %StatUpgradesContainer
@onready var emergency_heal_container := %EmergencyHealContainer

const SHOP_ITEM_SCENE = preload("res://shop/item/shop_item.tscn")

const UPGRADE_POOL: Array[ShopItemData] = [
	preload("res://shop/item/upgrades/increase_active_slots.tres"),
	preload("res://shop/item/upgrades/increase_total_slots.tres"),
	preload("res://shop/item/upgrades/increase_token_cap.tres"),
	preload("res://shop/item/upgrades/increase_token_regen.tres"),
]

func _ready() -> void:
	_populate_shop()

func _populate_shop() -> void:
	_populate_machine_modifications()
	_populate_misc_upgrades()


# TODO: Create gold label and continue buttong

func _populate_container(container: BoxContainer, items: Array[ShopItemData]) -> void:
	for item_data: ShopItemData in items:
		var item := SHOP_ITEM_SCENE.instantiate()
		item.setup(item_data)
		container.add_child(item)


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
	var reels: Array[ShopItemData]
	for i in num_reels:
		# Get (semi)random reel
		# Create ShopItemData
		print_debug("Get random reel")
		var random_reel: Reel = Global.reels.values().pick_random()
		reels.append(ReelShopItemData.create(random_reel))
	return reels

func _populate_reel_modifications() -> void:
	_populate_reel_stop_modifiers()
	_populate_reel_stops()
#	TODO: maybe change this to just button
	_populate_remove_reel_stop()

func _populate_reel_stop_modifiers() -> void:
	pass

func _populate_reel_stops() -> void:
	pass
	
func _populate_remove_reel_stop() -> void:
	pass


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
	pass

func _populate_consumables() -> void:
	_populate_cocktails()
	_populate_emergency_heal()
	
func _populate_cocktails() -> void:
	pass
	
func _populate_emergency_heal() -> void:
	_populate_container(emergency_heal_container, [EmergencyHealShopItemData.create()])
