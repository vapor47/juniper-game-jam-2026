extends Node

const COMBAT_SCENE = preload("res://combat.tscn")

func _ready() -> void:
	EventBus.post_combat_completed.connect(_on_continue)

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://combat.tscn")


func go_to_combat(enemies: Array[EnemyData]) -> void:
	var combat_scene = COMBAT_SCENE.instantiate()
	combat_scene.setup(enemies)
	get_tree().root.add_child(combat_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = combat_scene
