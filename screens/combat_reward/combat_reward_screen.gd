extends CanvasLayer

"""
Select N random(ish) reels to show as combat rewards

Setup and add 3 children to CombatRewardContainer
"""

const REWARD_BUTTON_SCENE = preload("res://screens/combat_reward/combat_reward_button.tscn")

func _ready() -> void:
	const num_rewards = 3
	var reel_pool: Array = Global.reels.values()
	reel_pool.shuffle()
	var reward_reels: Array[Reel] = reel_pool.slice(0, num_rewards)
	
	_init_rewards(reward_reels)

func _init_rewards(reels: Array[Reel]) -> void:
	for reel in reels:
		var reward_button: CombatRewardButton = REWARD_BUTTON_SCENE.instantiate()
		reward_button.setup(reel)
		%CombatRewardContainer.add_child(reward_button)
