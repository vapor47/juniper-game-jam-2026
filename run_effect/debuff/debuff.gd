extends RunEffect
class_name Debuff

"""
potentially per turns
	would need base turns remaining
	
effect, needs hook system. ties to runeffect
"""
var combats_remaining: int = 1

func on_combat_ended(_result, ctx: CombatContext) -> void:
	combats_remaining -= 1
	if combats_remaining == 0:
		ctx.player.remove_debuff(self)
