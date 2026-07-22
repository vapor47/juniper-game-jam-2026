extends CanvasLayer
class_name Toast

@export var display_duration: float = 4.0
@export var fade_duration: float = 0.4

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var flavor_label: Label = %FlavorLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel


static func show_debuff(effect_name: String, description: String, duration_text: String = "", flavor_text: String = "") -> void:
	var toast_scene: PackedScene = preload("res://toast.tscn")
	var toast: Toast = toast_scene.instantiate()
	#toast.position = Engine.get_main_loop().root.get_
	Engine.get_main_loop().root.add_child(toast)
	toast._play(flavor_text, effect_name, description, duration_text)


func _play(flavor_text: String, effect_name: String, description: String, _duration_text: String) -> void:
	$CenterContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	flavor_label.text = flavor_text
	name_label.text = effect_name
	#description_label.text = "%s (%s)" % [description, duration_text]
	description_label.text = description

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, fade_duration)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, fade_duration)
	tween.tween_interval(display_duration)
	tween.tween_property(panel, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
