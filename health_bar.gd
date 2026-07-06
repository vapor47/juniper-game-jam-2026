extends ProgressBar
class_name HealthBar

@onready var value_label: Label = $Label

func _ready() -> void:
	show_percentage = false 
	_update_bar_text()

func update_value(new_value: int) -> void:
	value = new_value 
	_update_bar_text()

func update_max_value(new_value: int) -> void:
	max_value = new_value 
	_update_bar_text()
	
func _set_initial_values(max_hp: int, curr_hp: int = max_hp) -> void:
	max_value = max_hp
	value = curr_hp
	_update_bar_text()

func _update_bar_text() -> void:
	# Formats the text as "Current Value / Max Value" (e.g., "75 / 100")
	value_label.text = "%d / %d" % [value, max_value]

func setup(combatant: CombatantData) -> void:
	_set_initial_values(combatant.max_health, combatant.health)
	EventBus.curr_health_updated.connect(
		func(who: CombatantData, new_val: int) -> void:
			if who == combatant:
				update_value(new_val)
	)
	EventBus.max_health_updated.connect(
		func(who: CombatantData, new_val: int) -> void:
			if who == combatant:
				update_max_value(new_val)
	)
	
