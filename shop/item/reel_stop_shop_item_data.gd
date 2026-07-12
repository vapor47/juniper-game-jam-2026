extends ShopItemData
class_name ReelStopShopItemData

const BASE_REEL_STOP_PRICE := 50

@export var reel: Reel

func on_purchase(_player: PlayerData) -> void:
	# TODO: Open Modal to add Stop
	pass

static func create(p_reel: Reel) -> ReelShopItemData:
	var item := ReelShopItemData.new()
	item.reel = p_reel
	item.display_name = p_reel.reel_name + " Reel"
	item.resource_name = item.display_name  # optional, debugger nicety only
	item.price = BASE_REEL_STOP_PRICE
	return item
