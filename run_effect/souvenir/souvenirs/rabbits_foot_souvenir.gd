# rabbits_foot_souvenir.gd
extends Souvenir
class_name RabbitsFootSouvenir

const BLOCK_AMOUNT := 5

func _init() -> void:
	display_name = "Rabbit's Foot"
	description = "Start each combat with %d block" % BLOCK_AMOUNT
	rarity = Souvenir.Rarity.COMMON

func on_combat_started(ctx: CombatContext) -> void:
	ctx.player.add_block(BLOCK_AMOUNT)
