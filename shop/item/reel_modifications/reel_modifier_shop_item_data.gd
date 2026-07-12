extends ReelModificationShopItemData
class_name ReelModifierShopItemData

const BASE_MODIFIER_PRICE := 100

func get_flow_payload():  # override: symbol, modifier, or null
	return null

func _init() -> void:
	mod_action = ReelModificationFlow.ModAction.ADD_MODIFIER

static func create() -> ReelModifierShopItemData:
	var item := ReelModifierShopItemData.new()
	#item.reel = p_reel
	item.display_name = "Modifier Name"
	item.resource_name = item.display_name  # optional, debugger nicety only
	item.price = BASE_MODIFIER_PRICE
	return item
