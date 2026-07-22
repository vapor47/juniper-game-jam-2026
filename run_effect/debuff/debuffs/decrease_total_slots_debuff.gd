extends Debuff
class_name DecreaseTotalSlotsDebuff

const SLOT_DECREMENT: int = 1

func _init() -> void:
	display_name = "Decrease Total Slots"
	description = "Decreases total slots by %d" % SLOT_DECREMENT

func on_acquired(player: PlayerData) -> void:
	player.total_slots -= SLOT_DECREMENT

func on_removed(player: PlayerData) -> void:
	player.total_slots += SLOT_DECREMENT
