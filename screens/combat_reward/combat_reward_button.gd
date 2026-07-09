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
	Global.reel_inventory[reel.reel_name] = Global.reel_inventory.get(reel.reel_name, 0) + 1
	# continue from combat reward screen
	SceneManager.combat_reward_chosen.emit()
