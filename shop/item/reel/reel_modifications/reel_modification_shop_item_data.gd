extends ShopItemData
class_name ReelModificationShopItemData

var mod_action: ReelModificationFlow.ModAction  # set by each subclass

func get_flow_payload():  # override: symbol, modifier, or null
	return null

func requires_flow() -> bool:
	return true
