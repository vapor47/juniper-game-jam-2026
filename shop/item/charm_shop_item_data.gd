extends ShopItemData
class_name CharmShopItemData

const BASE_CHARM_PRICE: int = 100
var charm: Charm


func on_purchase(_player: PlayerData) -> void:
	Global.player.add_charm(charm)
	charm.on_purchase()

static func create(p_charm: Charm) -> CharmShopItemData:
	var item := CharmShopItemData.new()
	item.display_name = p_charm.display_name
	item.resource_name = item.display_name
	item.price = BASE_CHARM_PRICE
	item.charm = p_charm
	return item
