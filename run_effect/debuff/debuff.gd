extends RunEffect
class_name Debuff
## Something the game does *to* the player, and the only RunEffect they did not
## choose.
##
## Two clocks. `combats_remaining` is the default and expires at the end of a
## fight. `turns_remaining`, when set, expires mid-fight instead — and is always
## clamped to the end of combat, so a turn-based debuff can never leak into the
## next one however many turns it had left.

var combats_remaining: int = 1
## Zero means "not turn-based"; use combats_remaining instead.
var turns_remaining: int = 0


## Whether this debuff would actually bite right now. A debuff that clamps to
## no change is worse than nothing — it reads as a punishment while doing
## nothing, and the pool should skip it.
func can_apply(_player: PlayerData) -> bool:
	return true


func on_turn_ended(ctx: CombatContext) -> void:
	if turns_remaining <= 0:
		return
	turns_remaining -= 1
	if turns_remaining <= 0:
		ctx.player.remove_debuff(self)


func on_combat_ended(_result, ctx: CombatContext) -> void:
	# Turn-based debuffs never survive the fight, whatever is left on the clock.
	if turns_remaining > 0:
		ctx.player.remove_debuff(self)
		return
	combats_remaining -= 1
	if combats_remaining <= 0:
		ctx.player.remove_debuff(self)
