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
	var player := ctx.player
	# Every attack action, not just the first. Each scoring run is now its own
	# Action (§4), so breaking after one multiplied a single run while the
	# description promises total attack damage.
	for action in ctx.actions:
		if action.type == Action.Type.ATTACK:
			action.value = ceili(action.value * (1.0 + (player.drunkenness / 100.0)))
