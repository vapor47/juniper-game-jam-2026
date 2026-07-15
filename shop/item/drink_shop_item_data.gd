extends ShopItemData
class_name DrinkShopItemData

const BASE_CHARM_PRICE: int = 50
var drink: Drink


func on_purchase(_player: PlayerData) -> void:
	Global.player.consume_drink(drink)
	drink.on_acquired()

static func create(p_drink: Drink) -> DrinkShopItemData:
	var item := DrinkShopItemData.new()
	item.display_name = p_drink.display_name
	item.description = p_drink.description
	item.resource_name = item.display_name
	item.price = BASE_CHARM_PRICE
	item.drink = p_drink
	return item
