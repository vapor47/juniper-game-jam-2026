# morning_coffee_souvenir.gd
extends Souvenir
class_name MorningCoffeeSouvenir

const TOKEN_BONUS := 1

func _init() -> void:
	display_name = "Morning Coffee"
	description = "+%d respin token on your first turn each combat" % TOKEN_BONUS
	rarity = Souvenir.Rarity.COMMON

func on_player_turn_started(ctx: CombatContext) -> void:
	if ctx.turn_number == 1:
		ctx.player.respin_tokens += TOKEN_BONUS
