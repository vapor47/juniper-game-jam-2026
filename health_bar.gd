extends ProgressBar

@onready var value_label: Label = $Label

func _ready() -> void:
	show_percentage = false 
	_update_bar_text()

# Call this function whenever your player takes damage, gains XP, etc.
func update_value(new_value: int) -> void:
	# Update the actual bar fill value (inherited from Range)
	value = new_value 
	_update_bar_text()
	
func set_initial_values(max_hp: int) -> void:
	max_value = max_hp
	value = max_hp
	_update_bar_text()

func _update_bar_text() -> void:
	# Formats the text as "Current Value / Max Value" (e.g., "75 / 100")
	value_label.text = "%d / %d" % [value, max_value]
