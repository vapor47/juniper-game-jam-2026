extends Drink
class_name DasBootDrink

var available: bool = true

func _init() -> void:
	display_name = "Das Boot"
	description = "Raw Strength ja?"
	rarity = Drink.Rarity.COMMON

func on_resolution(ctx: ResolutionContext) -> void:
	#print_debug(ctx.actions)
	for action in ctx.actions:
		print_debug(action.type)
		if action.type == Action.Type.ATTACK:
			action.value *= 2
			print_debug("DOUBLED")
			break
