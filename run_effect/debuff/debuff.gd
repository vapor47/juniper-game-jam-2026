extends RunEffect
class_name Debuff

"""
potentially per turns
	would need base turns remaining
	
effect, needs hook system. ties to runeffect
"""
var combats_remaining: int = 1


## Whether this debuff would actually bite right now. A debuff that clamps to
## no change is worse than nothing — it reads as a punishment while doing
## nothing, and the pool should skip it.
func can_apply(_player: PlayerData) -> bool:
	return true


func on_combat_ended(_result, ctx: CombatContext) -> void:
	combats_remaining -= 1
	if combats_remaining == 0:
		ctx.player.remove_debuff(self)
