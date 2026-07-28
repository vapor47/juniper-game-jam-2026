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
## The pressure that produces: the opening turn is rake-free, so collecting
## singles is fine and tokens are better banked than spent. It stops being fine
## quickly, and the tokens saved early are what buy the respins to hunt a run
## with later. The fight argues for patience first and aggression second, which
## no other enemy here does.
##
## It also deletes symbol tiers from the bottom up — at a cut of 2 every Light
## symbol pays nothing at all, at 4 every Med does. The player watches their
## small symbols stop working, which states the escalation without a readout.
##
## Raises land on its own turn and are telegraphed a turn ahead, so a player can
## see the rake coming and spend a good board before it arrives.

const HIT_MIN: int = 8
const HIT_MAX: int = 12
const MAX_CUT: int = 5
## Turns between raises. Frequent on purpose: the whole fight is the ramp.
const TURNS_PER_RAISE: int = 2

var turns_taken: int = 0


func _init() -> void:
	display_name = "The Rake"
	max_health = 130
	health = max_health


func _choose_intent() -> void:
	# The board opens uncut: the first raise lands on the first enemy turn, so
	# the player gets exactly one clean turn to read the machine before it
	# starts costing them.
	var raising := Global.action_cut < MAX_CUT and turns_taken % TURNS_PER_RAISE == 0
	turns_taken += 1

	intent = {
		"type": "attack",
		"value": randi_range(HIT_MIN, HIT_MAX),
		"raise_rake": raising,
		"note": "increasing the rake" if raising else "",
	}


## The raise happens when the turn resolves, not when it is chosen — the intent
## announces it a turn early so it can be played around.
func get_actions() -> Array[Action]:
	if intent.get("raise_rake", false):
		Global.action_cut = mini(Global.action_cut + 1, MAX_CUT)
		Toast.show_debuff("The Rake", "Takes %d from every action" % Global.action_cut, "", "")
	return super()
