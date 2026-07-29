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
	# The card is already titled with the symbol's name, so the description says
	# what it does and nothing else. Symbol.describe() is the single source, so
	# the shop, the cell tooltip and the paytable cannot drift apart.
	item.description = p_symbol.describe()
	return item
