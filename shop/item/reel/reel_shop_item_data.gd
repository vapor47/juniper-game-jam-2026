extends ShopItemData
class_name ReelShopItemData

"""
	Add reel to inventory
		Global inventory[reel_type] += 1
"""

const BASE_REEL_PRICE: int = 50

@export var reel: Reel

func on_purchase(_player: PlayerData) -> void:
	Global.player.add_reel_to_inventory(reel)

static func create(p_reel: Reel) -> ReelShopItemData:
	var item := ReelShopItemData.new()
	item.reel = p_reel
	item.display_name = p_reel.reel_name + " Reel"
	item.resource_name = item.display_name
	item.price = BASE_REEL_PRICE
	item.icon = p_reel.icon
	return item
