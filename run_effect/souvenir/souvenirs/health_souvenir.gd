extends Souvenir
class_name HealthSouvenir

func on_acquired(player: PlayerData) -> void:
	player.max_health += 10
	player.heal(10)

func _init() -> void:
	display_name = "HealthSouvenir"
	description = "Increases max health by 10"
