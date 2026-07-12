extends Control

@onready var reels_container := %ReelsContainer

const SHOP_ITEM_SCENE = preload("res://shop/shop_item/shop_item.tscn")

func _populate_shop() -> void:
	_populate_machine_modifications()
	_populate_misc_upgrades()


# Create gold label and continue buttong

# ---------- MACHINE MODIFICATIONS ---------- #

func _populate_machine_modifications() -> void:
	_populate_reels()
	_populate_reel_modifications()

func _populate_reels() -> void:
	"""
	Semi-randomly select reels.
	Weight factors:
		base reel rarity?
		if / how many reels of type player owns.
			If they own == max possible slots, is there purpose to showing them more?
			Can they benefit from more than max slots?
				Selling, sacrificing, gambling, etc
	"""
	var reels_to_sell
	for shop_item: ShopItem in reels_to_sell:
		var item := SHOP_ITEM_SCENE.instantiate()
		item.setup()
		reels_container.add_child(item)
	pass


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
