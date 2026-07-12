# stat_upgrade_shop_item_data.gd
extends ShopItemData
class_name StatUpgradeShopItemData

enum StatType { ACTIVE_SLOTS, TOTAL_SLOTS, TOKEN_CAP, TOKEN_REGEN }

@export var stat_type: StatType
@export var amount: int = 1

func on_purchase(player: PlayerData) -> void:
	match stat_type:
		StatType.ACTIVE_SLOTS:
			player.max_active_slots += amount
		StatType.TOTAL_SLOTS:
			player.total_slots += amount
		StatType.TOKEN_CAP:
			player.max_tokens += amount
		StatType.TOKEN_REGEN:
			player.token_regen_per_turn += amount
