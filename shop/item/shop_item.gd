extends Button
class_name ShopItem
## One card on the shelf. The price it shows is whatever the shop works out
## after discounts, not `item_data.price` — a souvenir bought mid-visit changes
## what everything else costs, so the card can't cache it.

signal purchase_requested(item: ShopItemData)

const SOLD_MODULATE := Color(1, 1, 1, 0.4)

var item_data: ShopItemData


func setup(p_item_data: ShopItemData) -> void:
	item_data = p_item_data


func is_available() -> bool:
	return not item_data.purchased


func _ready() -> void:
	icon = item_data.icon
	tooltip_text = item_data.description
	custom_minimum_size = item_data.get_card_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	refresh(item_data.price)


## Called by the shop whenever prices could have moved.
func refresh(price: int) -> void:
	if item_data.purchased:
		text = "%s\nSOLD" % item_data.display_name
		disabled = true
		modulate = SOLD_MODULATE
		return

	text = "%s\n $%d" % [item_data.display_name, price]
	modulate = Color.WHITE
	if price < item_data.price:
		# Only worth calling out that it's discounted, not by how much — the
		# number already says that.
		text += " (was $%d)" % item_data.price


func _on_pressed() -> void:
	purchase_requested.emit(item_data)
