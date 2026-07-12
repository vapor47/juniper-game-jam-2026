extends Control

@onready var reels_container := %ReelsContainer

const SHOP_ITEM_SCENE = preload("res://shop/shop_item/shop_item.tscn")

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
	pass
	
func _populate_charms() -> void:
	pass

func _populate_consumables() -> void:
	_populate_cocktails()
	_populate_emergency_heal()
	
func _populate_cocktails() -> void:
	pass
	
func _populate_emergency_heal() -> void:
	pass
