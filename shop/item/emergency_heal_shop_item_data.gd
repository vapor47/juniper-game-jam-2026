extends ShopItemData
class_name EmergencyHealShopItemData

const BASE_EMERGENCY_HEAL_PRICE: int = 300

func is_available() -> bool:
	return not RunManager.emergency_heal_used

func on_purchase(player: PlayerData) -> void:
	player.health = player.max_health
	RunManager.emergency_heal_used = true

static func create() -> EmergencyHealShopItemData:
	var item := EmergencyHealShopItemData.new()
	item.display_name = "Emergency Heal (one-time use!)"
	item.resource_name = item.display_name
	item.price = BASE_EMERGENCY_HEAL_PRICE
	return item
