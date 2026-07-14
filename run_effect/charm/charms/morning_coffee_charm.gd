# morning_coffee_charm.gd
extends Charm
class_name MorningCoffeeCharm

const TOKEN_BONUS := 1

func _init() -> void:
	display_name = "Morning Coffee"
	description = "+%d respin token on your first turn each combat" % TOKEN_BONUS
	rarity = Charm.Rarity.COMMON

func on_player_turn_started(ctx: CombatContext) -> void:
	if ctx.turn_number == 1:
		ctx.player.respin_tokens += TOKEN_BONUS
