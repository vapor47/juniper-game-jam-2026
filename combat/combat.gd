extends RefCounted
class_name Combat

"""
Holds state for a single combat.
"""

var player: PlayerData
var enemies: Array[EnemyData]
var state: CombatManager.CombatState = CombatManager.CombatState.INACTIVE
var initial_spin_completed: bool = false:
	set(new_value):
		if initial_spin_completed != new_value:
			EventBus.spin_lock_toggled.emit()
		initial_spin_completed = new_value

func _init(p: PlayerData, e: Array[EnemyData]) -> void:
	player = p
	enemies = e
	state = CombatManager.CombatState.PLAYER_TURN
	EventBus.lever_pulled.connect(func(): initial_spin_completed = true)
