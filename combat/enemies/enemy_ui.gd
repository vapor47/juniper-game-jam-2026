class_name EnemyUI
extends Panel

# 1. Expose a slot in the inspector to drop your .tres resource file
@export var enemy_data: EnemyData:
	set(new_enemy_data):
		enemy_data = new_enemy_data
		print("Enemy is now: " + enemy_data.display_name)
		if is_inside_tree():
			update_ui()

# 2. Get references to your internal UI child nodes
@onready var name_label := $VBoxContainer/NameLabel as Label
@onready var portrait_rect := $VBoxContainer/PortraitRect as TextureRect
@onready var health_bar: HealthBar = $VBoxContainer/HealthBar
@onready var intent_label := $VBoxContainer/IntentLabel as Label

func _ready() -> void:
	update_ui()
	health_bar.setup(enemy_data)
	get_tree().current_scene.player_turn_started.connect(update_ui)

func update_ui() -> void:
	if not enemy_data:
		return
		
	name_label.text = enemy_data.display_name
	intent_label.text = enemy_data.get_intent_as_string()
	portrait_rect.texture = enemy_data.portrait
