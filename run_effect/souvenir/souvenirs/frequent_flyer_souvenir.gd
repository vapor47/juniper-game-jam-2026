# frequent_flyer_souvenir.gd
extends Souvenir
class_name FrequentFlyerSouvenir

const DISCOUNT := 0.10

func _init() -> void:
	display_name = "Frequent Flyer"
	description = "Shop prices reduced by %d%%" % roundi(DISCOUNT * 100)
	rarity = Souvenir.Rarity.UNCOMMON

func modify_shop_price(price: int, _item: ShopItemData) -> int:
	return roundi(price * (1.0 - DISCOUNT))
