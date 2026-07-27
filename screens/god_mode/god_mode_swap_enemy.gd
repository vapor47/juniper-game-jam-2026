extends PanelContainer
## Restart the current fight against a chosen enemy.
##
## Restarts rather than swapping the EnemyData in place. A live combat has the
## enemy wired into several things — its died signal, the per-turn intent call,
## the EnemyUI node holding its health bar — and hot-swapping the resource would
## leave all of those pointing at the old one. Rebuilding the scene is both
## simpler and the behaviour you actually want from a test tool: a clean fight
## against the thing you picked.

const ENEMIES: Array = [
	preload("res://combat/enemies/destitute_gambler.gd"),
	preload("res://combat/enemies/chargey_guy.gd"),
	preload("res://combat/enemies/two_faced.gd"),
	preload("res://combat/enemies/the_cooler.gd"),
	preload("res://combat/enemies/pit_boss.gd"),
]

@onready var enemy_option_button: OptionButton = %EnemyOptionButton


func _ready() -> void:
	for i in ENEMIES.size():
		var enemy_class: GDScript = ENEMIES[i]
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
