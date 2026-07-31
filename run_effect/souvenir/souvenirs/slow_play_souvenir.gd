extends Souvenir
class_name SlowPlaySouvenir
## Skip a turn to make the next one bigger.
##
## Each skipped turn adds to a multiplier that is spent the next time the player
## actually resolves a line, then resets to nothing. It banks, it does not
## compound across the whole fight — the pot is carried to one hand and taken.
##
## A skip costs a full turn: no damage dealt, and no block either, so the
## enemy's hit lands on an unblocked player. That cost is what the multiplier is
## paying for.
##
## Named for the poker play — underplaying to let the pot grow before taking it.
## The *mechanic* is described to the player in slots language ("skipped turn"),
## since the machine is a slot machine even when the archetype names are not.

const PER_SKIP := 0.5

var skips: int = 0


func _init() -> void:
	display_name = "Slow Play"
	_refresh_text()
	rarity = Souvenir.Rarity.RARE


func on_combat_started(_ctx: CombatContext) -> void:
	skips = 0
	_refresh_text()


func on_turn_skipped(_ctx: CombatContext) -> void:
	skips += 1
	_refresh_text()


## Spent at lock-in, not at score time. score_line runs on every hover, so
## clearing the bank there would wipe it the moment the player read a line.
func on_resolution(_ctx: ResolutionContext) -> void:
	if skips > 0:
		skips = 0
		_refresh_text()


func multiplier() -> float:
	return 1.0 + PER_SKIP * float(skips)


## Scales the line as a whole. Runs inside score_line, so the hover preview
## shows the banked total before the player commits — the payoff has to be
## visible or skipping is a bet placed blind.
func modify_result_total(total: int, _type: Action.Type, _ctx: ResolutionContext) -> int:
	if skips <= 0 or total <= 0:
		return total
	return roundi(float(total) * multiplier())


## Carries the live figure, because the whole decision is "is the bank big
## enough yet" and a static description cannot answer that.
func _refresh_text() -> void:
	description = "Every skipped turn increases your next action's totals by %d%% (Current: %d%%)" \
		% [int(PER_SKIP * 100.0), int((multiplier() - 1.0) * 100.0)]
