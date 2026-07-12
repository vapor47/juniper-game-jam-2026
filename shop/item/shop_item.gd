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
	
	Acquire charm
		Global.player.charms.append(charm)
		
	Apply consumable (next combat effects)
		Global.player.active_consumables.append(consumable)
		
	Heal
		health = max
	
	Add reel, Increase stats, Heal are all simple adjustments
"""

var item_data: ShopItemData

func setup(p_item_data: ShopItemData) -> void:
	item_data = p_item_data

func _ready() -> void:
	text = item_data.display_name

func _on_pressed() -> void:
	if Global.player.gold < item_data.price:
		# TODO: play animation, cannot afford.
		return
	item_data.on_purchase(Global.player)
	_mark_purchased()

func _mark_purchased() -> void:
	Global.player.gold -= item_data.price
	disabled = true
