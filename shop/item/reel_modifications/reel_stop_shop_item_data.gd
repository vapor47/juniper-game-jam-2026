extends ReelModificationShopItemData
class_name ReelStopShopItemData

const BASE_REEL_STOP_PRICE := 50

var symbol: SlotSymbol

func get_flow_payload():  # override: symbol, modifier, or null
	return symbol

func _init() -> void:
	mod_action = ReelModificationFlow.ModAction.ADD_STOP
	
func on_purchase(_player: PlayerData) -> void:
	pass

static func create(p_symbol: SlotSymbol) -> ReelStopShopItemData:
	var item := ReelStopShopItemData.new()
	item.symbol = p_symbol
	item.display_name = p_symbol.symbol_name + " Reel Stop"
	item.resource_name = item.display_name
	item.price = BASE_REEL_STOP_PRICE
	return item
