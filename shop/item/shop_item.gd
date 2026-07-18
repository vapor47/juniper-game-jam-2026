extends Button
class_name ShopItem

"""
Takes in item info
On press, applies item actions

Possible Item Actions:
	Add reel to inventory
		Global inventory[reel_type] += 1
		
	Modify Reel (opens modal)
	Increase player stats
		Global.player.stat += amount
	
	Acquire souvenir
		Global.player.souvenirs.append(souvenir)
		
	Apply consumable (next combat effects)
		Global.player.active_consumables.append(consumable)
		
	Heal
		health = max
	
	Add reel, Increase stats, Heal are all simple adjustments
"""

signal purchase_requested(item: ShopItemData)

var item_data: ShopItemData

func setup(p_item_data: ShopItemData) -> void:
	item_data = p_item_data


func is_available() -> bool:
	return true

func _ready() -> void:
	text = item_data.display_name + "\n $" + str(item_data.price)
	icon = item_data.icon
	tooltip_text = item_data.description
	custom_minimum_size = item_data.get_card_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _on_pressed() -> void:
	purchase_requested.emit(item_data)
