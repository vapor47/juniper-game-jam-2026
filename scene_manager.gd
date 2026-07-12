extends Node

const COMBAT_SCENE = preload("res://combat/combat.tscn")
const SHOP_SCENE = preload("res://shop/shop.tscn")
const VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")

signal combat_reward_chosen

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

func go_to_combat(enemies: Array[EnemyData]) -> void:
	var combat_scene := COMBAT_SCENE.instantiate()
	combat_scene.setup(enemies)
	get_tree().root.add_child(combat_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = combat_scene

func go_to_shop() -> void:
	var shop_scene := SHOP_SCENE.instantiate()
	get_tree().root.add_child(shop_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = shop_scene

func go_to_win_screen() -> void:
	add_child(VICTORY_SCREEN_SCENE.instantiate())
