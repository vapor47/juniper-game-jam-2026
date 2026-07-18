extends Souvenir
class_name HealthSouvenir

func on_acquired() -> void:
	Global.player.max_health += 10
	Global.player.heal(10)

func _init() -> void:
	display_name = "HealthSouvenir"
	description = "Increases max health by 10"
