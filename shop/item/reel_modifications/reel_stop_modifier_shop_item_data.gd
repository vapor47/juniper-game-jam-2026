extends ReelModificationShopItemData
class_name ReelStopModifierShopItemData

const BASE_MODIFIER_PRICE := 100
var modifier: StopModifier

@warning_ignore("untyped_declaration")
func get_flow_payload():  # override: symbol, modifier, or null
	return modifier

func _init() -> void:
	mod_action = ReelModificationFlow.ModAction.ADD_MODIFIER

static func create(p_modifier: StopModifier) -> ReelStopModifierShopItemData:
	var item := ReelStopModifierShopItemData.new()
	item.modifier = p_modifier
	item.display_name = p_modifier.display_name
	item.resource_name = item.display_name
	item.price = BASE_MODIFIER_PRICE
	return item
