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
	item.description = "Adds a %s symbol (%s)" % [p_symbol.symbol_name, _blurb(p_symbol)]
	return item


static func _blurb(symbol: Symbol) -> String:
	if symbol.is_wild:
		return "counts as whatever it sits beside"
	if not symbol.payout.is_empty():
		return "%d in a row pays big" % symbol.min_run
	if symbol == SymbolTable.CHIP:
		return "%d gold each turn it shows" % SymbolTable.CHIP_GOLD_PER_COPY
	if symbol == SymbolTable.PENNY:
		return "%d gold on a line, %d more every spin it shows" % [
				symbol.value, SymbolTable.PENNY_GOLD_PER_COPY]
	return symbol.effect_text()
