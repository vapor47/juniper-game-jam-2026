extends Node

## The run's fixed order. Existence lives in EnemyCatalog — an enemy can be in
## the catalog without being in a run, but never the reverse.
var encounter_queue: Array[Array] = [
	[DestituteGamblerData],
	[ChargeyGuyData],
	[TwoFacedData],
	[TheRakeData],
	[TheCoolerData],
	[PitBossData],
]

## Payout for winning a fight. Sized at about one shop item (a souvenir or a
## stat upgrade is 100g, a drink 50g), so clearing a fight buys one thing and
## a gold build on the strip is what buys two.
##
## The band is house variance, not a performance grade. Tying the payout to
## how fast the fight ended would tax defensive play, and block is already
## deliberately scarce against demand (§3) — it shouldn't be charged for twice.
const COMBAT_REWARD_BASE: int = 100
const COMBAT_REWARD_BAND: int = 25

var curr_encounter_idx: int = 0
## What the last win paid, so the reward screen can show the figure.
var last_combat_reward: int = 0
var emergency_heal_used: bool = false
var is_resetting: bool = false


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

## Rolls the payout for a win and banks it. Called once per victory.
func award_combat_reward() -> int:
	last_combat_reward = COMBAT_REWARD_BASE + randi_range(-COMBAT_REWARD_BAND, COMBAT_REWARD_BAND)
	Global.player.gold += last_combat_reward
	return last_combat_reward


func is_run_complete() -> bool:
	return curr_encounter_idx >= encounter_queue.size()

func restart_run() -> void:
	is_resetting = true
	
	reset_run_state()
	SceneManager.go_to_combat(get_next_encounter())
	await get_tree().process_frame
	
	is_resetting = false

func reset_run_state() -> void:
	Global.reset()
	curr_encounter_idx = 0
	emergency_heal_used = false
