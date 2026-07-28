extends PanelContainer
## Restart the current fight against a chosen enemy.
##
## Restarts rather than swapping the EnemyData in place. A live combat has the
## enemy wired into several things — its died signal, the per-turn intent call,
## the EnemyUI node holding its health bar — and hot-swapping the resource would
## leave all of those pointing at the old one. Rebuilding the scene is both
## simpler and the behaviour you actually want from a test tool: a clean fight
## against the thing you picked.

@onready var enemy_option_button: OptionButton = %EnemyOptionButton


func _ready() -> void:
	# EnemyCatalog, not a list of its own: this panel previously kept its own
	# copy and silently went stale the moment an enemy was added elsewhere.
	var missing := EnemyCatalog.missing_from_catalog()
	if not missing.is_empty():
		push_warning("Enemies in the run queue but not in EnemyCatalog: %s" % str(missing))

	for i in EnemyCatalog.ALL.size():
		var enemy_class: GDScript = EnemyCatalog.ALL[i]
		var temp: EnemyData = enemy_class.new()
		enemy_option_button.add_item("%s (%d HP)" % [temp.display_name, temp.max_health], i)
		enemy_option_button.set_item_metadata(i, enemy_class)


func _on_swap_enemy_button_pressed() -> void:
	var idx := enemy_option_button.selected
	if idx < 0:
		return
	var enemy_class: GDScript = enemy_option_button.get_item_metadata(idx)

	var enemies: Array[EnemyData] = [enemy_class.new()]
	# Unpause and close the menu first: go_to_combat frees the current scene,
	# and leaving the tree paused would freeze the fight it just built.
	PauseMenu.toggle()
	SceneManager.go_to_combat(enemies)
