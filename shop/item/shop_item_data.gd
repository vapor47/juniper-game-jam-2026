extends Resource
class_name ShopItemData

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

const BASE_PRICE: int = 1

@export var display_name: String
@export var price: int
@export var icon: Texture2D
var purchased: bool = false

func on_purchase(player: PlayerData) -> void:
	pass  # override
