extends ShopItemData
class_name StopShopItemData
## Buying a symbol (§6). Replace and Add are the *same purchase at the same
## price* — you buy the stop, then placement decides which verb it was. That
## self-balances: early on the strip is full of chaff so replacing is obvious;
## late, when everything is good, eating the dilution becomes a live option.

var symbol: Symbol


func requires_flow() -> bool:
	return true


static func create(p_symbol: Symbol) -> StopShopItemData:
	var item := StopShopItemData.new()
	item.symbol = p_symbol
	item.display_name = p_symbol.symbol_name
	item.resource_name = item.display_name
	item.price = SymbolTable.price_of(p_symbol)
	item.icon = p_symbol.icon
	item.description = "Adds a %s stop (%s)" % [
			p_symbol.symbol_name, _effect_text(p_symbol)]
	return item


static func _effect_text(symbol: Symbol) -> String:
	match symbol.type:
		Action.Type.ATTACK:
			return "%d damage" % symbol.value
		Action.Type.DEFEND:
			return "%d block" % symbol.value
		Action.Type.HEAL:
			return "%d heal" % symbol.value
		_:
			return "no effect"
