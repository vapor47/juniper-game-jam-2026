# FloatingText.gd
# Created for testing purposes. Delete later (unless used for prod)
extends Label

func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modulate.a = 1.0
	
	# Fade sequence
	var fade_tween := create_tween()
	fade_tween.tween_interval(2.0)
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	fade_tween.tween_callback(queue_free)
	
	# Float upward (new, runs simultaneously with the fade sequence)
	var float_tween := create_tween()
	float_tween.tween_property(self, "global_position:y", global_position.y - 80, 3.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
