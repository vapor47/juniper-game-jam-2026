extends Button
class_name CombatRewardButton
"""
init:
	set reel type
	set icon and label derived from reel

onpress:
	adds reel to inventory
	continues from screen
"""
var reel: Reel

func setup(r: Reel) -> void:
	reel = r
	text = r.reel_name
	icon = r.icon
	
func _on_pressed() -> void:
	Global.player.add_reel_to_inventory(reel)
	# continue from combat reward screen
	SceneManager.combat_reward_chosen.emit()
