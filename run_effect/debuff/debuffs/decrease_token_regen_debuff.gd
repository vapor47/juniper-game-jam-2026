extends Debuff
class_name DecreaseTokenRegenDebuff
## Replaces the old total-slots debuff, which decremented a field nothing reads
## since the loadout system was retired.

const REGEN_DECREMENT: int = 1

## Refunding a flat amount after a clamp would pay
## back more than was taken.
var _applied: int = 0


func _init() -> void:
	display_name = "Heavy Pockets"
	description = "One fewer token at the start of each turn"


func can_apply(player: PlayerData) -> bool:
	return player.token_regen_per_turn - REGEN_DECREMENT >= 0


func on_acquired(player: PlayerData) -> void:
	_applied = mini(REGEN_DECREMENT, player.token_regen_per_turn)
	player.token_regen_per_turn -= _applied


func on_removed(player: PlayerData) -> void:
	player.token_regen_per_turn += _applied
	_applied = 0
