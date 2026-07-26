extends ShopItemData
class_name StatUpgradeShopItemData

## ACTIVE_SLOTS and TOTAL_SLOTS belonged to the retired loadout system — the
## fields they wrote are no longer read by anything, so those upgrades took
## gold and did nothing. LINE_CAP replaces them: raising how many paylines can
## be played at once is the live equivalent, and §4 specifically wants that to
## be what upgrades buy.
enum StatType { LINE_CAP, TOKEN_CAP, TOKEN_REGEN }

@export var stat_type: StatType
@export var amount: int = 1


func on_purchase(player: PlayerData) -> void:
	match stat_type:
		StatType.LINE_CAP:
			player.max_lines_per_turn += amount
		StatType.TOKEN_CAP:
			player.max_tokens += amount
		StatType.TOKEN_REGEN:
			player.token_regen_per_turn += amount
