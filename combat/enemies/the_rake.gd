extends EnemyData
class_name TheRakeData
## Takes a cut of every action, and raises it as the fight runs.
##
## The cut is flat and per *action*, which is what makes it a decision rather
## than a tax. A payline is about four scoring actions on a starting strip, so a
## board of unmatched singles pays the cut four times over while one long run
## pays it once. Measured: at a cut of 3 a line with no match keeps 33% of its
## value, a line with a run of three keeps 71%.
##
## The pressure that produces: early, when the cut is 1, collecting singles is
## still fine and tokens are better banked than spent. Later it stops being
## fine, and the tokens you saved are what buy the respins to hunt a run with.
## The fight argues for patience first and aggression second, which no other
## enemy here does.
##
## It also deletes symbol tiers from the bottom up — at a cut of 2 every Light
## symbol pays nothing at all, at 4 every Med does. The player watches their
## small symbols stop working, which states the escalation without a readout.

const HIT_MIN: int = 8
const HIT_MAX: int = 12
const STARTING_CUT: int = 1
const MAX_CUT: int = 5
## Turns between raises. Frequent on purpose: the whole fight is the ramp.
const TURNS_PER_RAISE: int = 2

var turns_taken: int = 0


func _init() -> void:
	display_name = "The Rake"
	max_health = 130
	health = max_health


func _choose_intent() -> void:
	var cut := mini(STARTING_CUT + turns_taken / TURNS_PER_RAISE, MAX_CUT)
	turns_taken += 1

	if cut != Global.action_cut:
		Global.action_cut = cut
		Toast.show_debuff("The Rake", "Takes %d from every action" % cut, "", "")

	intent = { "type": "attack", "value": randi_range(HIT_MIN, HIT_MAX) }
