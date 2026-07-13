extends ReelModificationShopItemData
class_name RemoveReelStopShopItemData

const BASE_MODIFIER_PRICE := 100

func get_flow_payload():  # override: symbol, modifier, or null
	return null
	
func on_purchase(player: PlayerData) -> void:
	pass

func _init() -> void:
	mod_action = ReelModificationFlow.ModAction.REMOVE_STOP

static func create() -> RemoveReelStopShopItemData:
	var item := RemoveReelStopShopItemData.new()
	item.display_name = "Remove Reel Stop"
	item.resource_name = item.display_name  # optional, debugger nicety only
	item.price = BASE_MODIFIER_PRICE
	return item
