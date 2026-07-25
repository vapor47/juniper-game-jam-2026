extends ShopItemData
class_name RemoveStopShopItemData
## Removal is the strongest verb and stays a separate service — it isn't
## buying a symbol (§6). It concentrates the distribution *and* shortens the
## strip, improving consistency on everything left, so it's priced highest.
## Self-limiting: eventually you run out of chaff worth cutting.

const BASE_REMOVE_PRICE: int = 120


func requires_flow() -> bool:
	return true


static func create() -> RemoveStopShopItemData:
	var item := RemoveStopShopItemData.new()
	item.display_name = "Remove a Stop"
	item.resource_name = item.display_name
	item.price = BASE_REMOVE_PRICE
	item.description = "Permanently removes one stop from the reel"
	return item
