# FloatingText.gd
# Created for testing purposes. Delete later (unless used for prod)
extends Label

func _ready() -> void:
	
	# Ensure visibility starts at 100%
	modulate.a = 1.0 
	
	# Create a simple, sequential animation
	var tween := create_tween()
	
	# 1. Stay on screen perfectly still for 2.0 seconds
	tween.tween_interval(2.0)
	
	# 2. Smoothly fade alpha property down to 0.0 over 1.0 second
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# 3. Safely delete the node from memory once the fade is done
	tween.tween_callback(queue_free)
