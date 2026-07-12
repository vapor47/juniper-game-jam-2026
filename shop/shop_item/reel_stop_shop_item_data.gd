extends ShopItemData
class_name ReelShopItemData

const BASE_REEL_PRICE := 50

@export var reel: Reel

func on_purchase(_player: PlayerData) -> void:
	Global.reel_inventory[reel.reel_name] = Global.reel_inventory.get(reel.reel_name) + 1


static func create(p_reel: Reel) -> ReelShopItemData:
	var item := ReelShopItemData.new()
	item.reel = p_reel
	item.display_name = p_reel.reel_name + " Reel"
	item.resource_name = item.display_name  # optional, debugger nicety only
	item.price = BASE_REEL_PRICE
	return item
