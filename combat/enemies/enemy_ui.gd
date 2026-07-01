class_name EnemyUI
extends Panel

# 1. Expose a slot in the inspector to drop your .tres resource file
@export var enemy_data: EnemyData:
	set(new_enemy_data):
		enemy_data = new_enemy_data
		if is_inside_tree():
			update_ui()

# 2. Get references to your internal UI child nodes
@onready var name_label := $VBoxContainer/NameLabel as Label
@onready var portrait_rect := $VBoxContainer/PortraitRect as TextureRect
@onready var health_bar := $VBoxContainer/ProgressBar as ProgressBar
@onready var intent_label := $VBoxContainer/IntentLabel as Label

func _ready() -> void:
	update_ui()
	EventBus.damage_taken.connect(func(who):
		if who == enemy_data: update_ui())

# 3. Map the resource enemy_data to the visual nodes
func update_ui() -> void:
	if not enemy_data:
		return
		
	name_label.text = enemy_data.display_name
	intent_label.text = enemy_data.get_intent_as_string()
	portrait_rect.texture = enemy_data.portrait
	health_bar.max_value = enemy_data.max_health
	health_bar.value = enemy_data.health
