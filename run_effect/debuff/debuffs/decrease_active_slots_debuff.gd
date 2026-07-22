extends Debuff
class_name DecreaseActiveSlotsDebuff

const SLOT_DECREMENT: int = 1

func _init() -> void:
	display_name = "Decrease Active Slots"
	description = "Decreases active slots by %d" % SLOT_DECREMENT

func on_acquired(player: PlayerData) -> void:
	player.max_active_slots -= SLOT_DECREMENT

func on_removed(player: PlayerData) -> void:
	player.max_active_slots += SLOT_DECREMENT
