extends Drink
class_name TheEncoreDrink

var available: bool = true

func _init() -> void:
	display_name = "The Encore"
	description = "Your first turn's actions next combat are repeated"
	rarity = Drink.Rarity.COMMON

#func on_turn_ended(ctx: ResolutionContext) -> void:
	#pass

func on_combat_started(_ctx: CombatContext) -> void:
	available = true
