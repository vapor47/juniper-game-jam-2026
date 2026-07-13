extends Charm
class_name RabbitsFoot

func on_combat_started(_ctx: CombatContext) -> void:
	print_debug("Rabbit combat started")
	Global.player.add_block(8)

func _init() -> void:
	display_name = "Rabbits Foot"
