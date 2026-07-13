extends Charm
class_name RabbitsFoot

func on_combat_started(_ctx: CombatContext) -> void:
	Global.player.add_block(8)

func _init() -> void:
	display_name = "Rabbits Foot"
