extends Drink
class_name RetailTherapyDrink
## Widens the bar's shelf once. Spends itself on the first shop that asks, so
## the extra bottle shows up on the next visit rather than every visit.

var spent: bool = false


func _init() -> void:
	display_name = "Retail Therapy"
	description = "The Bar stocks an additional drink next visit"
	rarity = Drink.Rarity.COMMON


func modify_shop_stock(count: int, category: StringName) -> int:
	if spent or category != &"drinks":
		return count
	spent = true
	return count + 1
