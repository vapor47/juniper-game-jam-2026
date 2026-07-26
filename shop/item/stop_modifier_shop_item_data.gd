extends ShopItemData
class_name StopModifierShopItemData
## Buying a modifier, then placing it on a stop (§6). Like buying a stop, the
## gold is only spent once it's actually attached.

## Priced off rarity: a modifier is worth what it does, not what the strip
## already holds — same rule as symbol pricing (§6).
const PRICES := {
	StopModifier.Rarity.COMMON: 70,
	StopModifier.Rarity.UNCOMMON: 120,
	StopModifier.Rarity.RARE: 200,
}

var modifier: StopModifier


func requires_flow() -> bool:
	return true


static func create(p_modifier: StopModifier) -> StopModifierShopItemData:
	var item := StopModifierShopItemData.new()
	item.modifier = p_modifier
	item.display_name = p_modifier.display_name
	item.description = p_modifier.description
	item.icon = p_modifier.overlay_icon
	item.resource_name = item.display_name
	item.price = PRICES.get(p_modifier.rarity, 70)
	return item
