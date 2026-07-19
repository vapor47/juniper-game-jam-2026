# frequent_flyer_souvenir.gd
extends Souvenir
class_name LoyaltyCardSouvenir

const DISCOUNT_INCREMENT := 0.15

func _init() -> void:
	display_name = "Loyalty Card"
	description = "Every bar visit, receive a stacking %d%% discount on drinks for each drink purchased" % roundi(DISCOUNT_INCREMENT * 100)
	rarity = Souvenir.Rarity.UNCOMMON

func modify_shop_price(price: int, _item: ShopItemData) -> int:
	return roundi(price * (1.0 - DISCOUNT_INCREMENT))


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
