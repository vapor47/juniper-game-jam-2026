extends Drink
class_name DasBootDrink

var available: bool = true

func _init() -> void:
	display_name = "Das Boot"
	#description = "Raw Strength ja?"
	description = "Multiplies total attack damage (scaling with drunkenness)"
	rarity = Drink.Rarity.COMMON
	alcohol_content = 20.0

func on_resolution(ctx: ResolutionContext) -> void:
	var player := ctx.turn.combat.player
	for action in ctx.actions:
		print_debug(action.type)
		if action.type == Action.Type.ATTACK:
			action.value = ceil(action.value * (1.0 + (player.drunkenness / 100.0)))
			break
