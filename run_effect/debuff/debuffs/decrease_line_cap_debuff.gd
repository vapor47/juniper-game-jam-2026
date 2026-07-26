extends Debuff
class_name DecreaseLineCapDebuff
## Mirror of the Extra Payline upgrade. Replaces the old active-slots debuff,
## which decremented a field nothing reads since the loadout system was retired.

const LINE_DECREMENT: int = 1

## What was actually taken. Removal refunds this rather than LINE_DECREMENT:
## if the cap had clamped, a flat refund would hand back more than was taken
## and stacking the debuff would leave the player better off than before.
var _applied: int = 0


func _init() -> void:
	display_name = "Seeing Double"
	description = "Play one fewer payline per turn"


## Never drop the player below one playable line — with none, a turn cannot be
## resolved at all.
func can_apply(player: PlayerData) -> bool:
	return player.max_lines_per_turn - LINE_DECREMENT >= 1


func on_acquired(player: PlayerData) -> void:
	_applied = mini(LINE_DECREMENT, player.max_lines_per_turn - 1)
	player.max_lines_per_turn -= _applied


func on_removed(player: PlayerData) -> void:
	player.max_lines_per_turn += _applied
	_applied = 0
