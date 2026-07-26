extends Souvenir
class_name LoyaltyCardSouvenir

const DISCOUNT_INCREMENT := 0.15

func _init() -> void:
	display_name = "Loyalty Card"
	description = "Every bar visit, receive a stacking %d%% discount on drinks for each drink purchased" % roundi(DISCOUNT_INCREMENT * 100)
	rarity = Souvenir.Rarity.UNCOMMON

## Drinks only, and it stacks with each one already bought this visit — which
## is what the description has always promised. The stacking used to live in
## Shop.display_price as a hardcode; routing it through the hook keeps the
## behaviour and lets other souvenirs discount too.
func modify_shop_price(price: int, item: ShopItemData) -> int:
	if not item is DrinkShopItemData:
		return price
	var bought := Global.player.drinks_bought_this_visit if Global.player else 0
	var discount := clampf(DISCOUNT_INCREMENT * bought, 0.0, 1.0)
	return roundi(price * (1.0 - discount))


"""
this:
drinks on purchase: increase discount

for each drink available in shop:
	increase discount by X%
		
	each item holds its base price and its current price.
	or its keeps its discount percentage. and then we can just calculate it.
	
drink.on_purchase(if shotglass: then decrease all other drink costs)
or add a 
"""
