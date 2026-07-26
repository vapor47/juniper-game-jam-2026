extends Debuff
class_name DecreaseLineCapDebuff
## Mirror of the Extra Payline upgrade. Replaces the old active-slots debuff,
## which decremented a field nothing reads since the loadout system was retired.

const LINE_DECREMENT: int = 1


func _init() -> void:
	display_name = "Seeing Double"
	description = "Play one fewer payline per turn"


func on_acquired(player: PlayerData) -> void:
	player.max_lines_per_turn = maxi(1, player.max_lines_per_turn - LINE_DECREMENT)


func on_removed(player: PlayerData) -> void:
	player.max_lines_per_turn += LINE_DECREMENT
