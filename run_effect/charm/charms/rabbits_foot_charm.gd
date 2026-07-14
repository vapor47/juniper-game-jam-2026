# rabbits_foot_charm.gd
extends Charm
class_name RabbitsFootCharm

const BLOCK_AMOUNT := 5

func _init() -> void:
	display_name = "Rabbit's Foot"
	description = "Start each combat with %d block" % BLOCK_AMOUNT
	rarity = Charm.Rarity.COMMON

func on_combat_started(ctx: CombatContext) -> void:
	ctx.player.add_block(BLOCK_AMOUNT)
