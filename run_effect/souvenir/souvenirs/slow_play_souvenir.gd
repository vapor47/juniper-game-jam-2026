extends Souvenir
class_name SlowPlaySouvenir
## Fold to build the pot: every folded turn permanently raises what your lines
## pay for the rest of the fight.
##
## Named for the poker play — deliberately underplaying a strong hand so the pot
## grows before you take it. Mechanically that is exactly this.
##
## A fold costs a full turn: no damage dealt, and no block either, so the
## enemy's hit lands on an unblocked player. Measured against a 9-turn fight on
## a block-heavy machine, three folds turns 182 total damage into 303 — a 66%
## gain for about 42 HP. That is the trade.
##
## The bonus persists for the fight rather than resetting when it is cashed in.
## A version that reset on the next played turn is strictly worse than never
## folding at all: fold-fold-fold-cash on repeat deals roughly 120 over nine
## turns against 182 for simply playing every turn.
##
## It needs no cap up to about four folds — losing a turn you would have scored
## on is its own brake, and at +50% a fourth fold gains nothing over a third.
## MAX_FOLDS only guards the long fights (The Cooler runs past twenty turns)
## where the tempo cost stops mattering.

const PER_FOLD := 0.5
const MAX_FOLDS := 4

var folds: int = 0


func _init() -> void:
	display_name = "Slow Play"
	description = "Folding a turn raises every payline by %d%% for the rest of the combat" \
		% int(PER_FOLD * 100.0)
	rarity = Souvenir.Rarity.RARE


func on_combat_started(_ctx: CombatContext) -> void:
	folds = 0


func on_turn_folded(_ctx: CombatContext) -> void:
	folds = mini(folds + 1, MAX_FOLDS)


## Scales the line as a whole. Runs inside score_line, so the hover preview
## shows the raised numbers before the player commits — which is the point:
## the payoff has to be visible for folding to be a decision.
func modify_result_total(total: int, _type: Action.Type, _ctx: ResolutionContext) -> int:
	if folds <= 0 or total <= 0:
		return total
	return roundi(float(total) * (1.0 + PER_FOLD * float(folds)))
