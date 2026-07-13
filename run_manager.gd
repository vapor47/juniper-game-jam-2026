extends Node

var encounter_queue: Array[Array] = [
	[DestituteGamblerData],
	[ChargeyGuyData],
	[TwoFacedData],
	[PitBossData],
]

var curr_encounter_idx: int = 0
var emergency_heal_used: bool = false

func _ready() -> void:
	EventBus.run_restarted.connect(_on_restart)


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

func is_run_complete() -> bool:
	return curr_encounter_idx >= encounter_queue.size()

func _on_restart() -> void:
	Global.reset()
	_reset_run_state()
	#Global.reel_inventory = {
		#"Attack": 3,
		#"Defend": 3,
		#"Heal": 0,
	#}

func _reset_run_state() -> void:
	curr_encounter_idx = 0
	emergency_heal_used = false
