extends ShopItemData
class_name SouvenirShopItemData

const BASE_CHARM_PRICE: int = 100
var souvenir: Souvenir


func on_purchase(_player: PlayerData) -> void:
	Global.player.add_souvenir(souvenir)
	souvenir.on_acquired()

static func create(p_souvenir: Souvenir) -> SouvenirShopItemData:
	var item := SouvenirShopItemData.new()
	item.display_name = p_souvenir.display_name
	item.resource_name = item.display_name
	item.price = BASE_CHARM_PRICE
	item.souvenir = p_souvenir
	return item
