extends Node

var encounter_queue: Array[Array] = [
	[DestituteGamblerData],
	[ChargeyGuyData],
	[TwoFacedData],
	[PitBossData],
]

var curr_encounter_idx: int = 0

# Create Encounter object? that can be either combat, shop, etc
func get_next_encounter() -> Array[EnemyData]:
	if curr_encounter_idx >= encounter_queue.size():
		push_error("No more encounters left in queue")
		return []
	
	var pool := encounter_queue[curr_encounter_idx]
	curr_encounter_idx += 1
	
	var enemies: Array[EnemyData] = []
	for enemy_class in pool:
		enemies.append(enemy_class.new())
	return enemies
