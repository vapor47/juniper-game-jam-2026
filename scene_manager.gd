extends Node

const COMBAT_SCENE = preload("res://combat/combat.tscn")
const SHOP_SCENE = preload("res://shop/shop.tscn")
const VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")
const MAIN_MENU_SCENE = preload("res://screens/main_menu.tscn")

signal combat_reward_chosen

var _curr_combat: CombatManager = null

func _ready() -> void:
	EventBus.post_combat_completed.connect(_on_post_combat_continue)
	combat_reward_chosen.connect(_on_post_combat_continue)
	EventBus.shop_exited.connect(_on_shop_exited)

func _on_shop_exited() -> void:
	if RunManager.is_run_complete():
		go_to_win_screen()
	else:
		go_to_combat(RunManager.get_next_encounter())

func _on_post_combat_continue() -> void:
	go_to_shop()
	_curr_combat = null

func go_to_combat(enemies: Array[EnemyData]) -> void:
	var combat: CombatManager = COMBAT_SCENE.instantiate()
	combat.setup(enemies)
	get_tree().root.add_child(combat)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = combat
	_curr_combat = combat

func go_to_shop() -> void:
	var shop_scene := SHOP_SCENE.instantiate()
	get_tree().root.add_child(shop_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = shop_scene

func go_to_win_screen() -> void:
	add_child(VICTORY_SCREEN_SCENE.instantiate())
	
func go_to_main_screen() -> void:
	var main_menu := MAIN_MENU_SCENE.instantiate()
	get_tree().root.add_child(main_menu)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = main_menu
	

func in_combat() -> bool:
	return _curr_combat != null

func get_curr_combat() -> CombatManager:
	if not in_combat():
		return
	return _curr_combat
