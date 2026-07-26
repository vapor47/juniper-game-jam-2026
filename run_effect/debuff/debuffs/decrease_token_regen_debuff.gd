extends Debuff
class_name DecreaseTokenRegenDebuff
## Replaces the old total-slots debuff, which decremented a field nothing reads
## since the loadout system was retired.

const REGEN_DECREMENT: int = 1


func _init() -> void:
	display_name = "Heavy Pockets"
	description = "One fewer token at the start of each turn"


func on_acquired(player: PlayerData) -> void:
	player.token_regen_per_turn = maxi(0, player.token_regen_per_turn - REGEN_DECREMENT)


func on_removed(player: PlayerData) -> void:
	player.token_regen_per_turn += REGEN_DECREMENT
