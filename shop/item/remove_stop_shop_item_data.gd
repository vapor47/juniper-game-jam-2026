extends ShopItemData
## "Stop" is the position on the reel and "Symbol" is what is printed there — a
## real distinction in the code and noise to a player, who sees one thing. All
## player-facing strings say symbol; the classes keep the precise names.
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
	item.display_name = "Remove a Symbol"
	item.resource_name = item.display_name
	item.price = BASE_REMOVE_PRICE
	item.description = "Permanently removes one symbol from the reel"
	return item
