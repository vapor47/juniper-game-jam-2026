extends EnemyData
class_name TheCoolerData
## A casino "cooler" is the person brought in to break a winning streak. This
## one breaks the machine instead.
##
## Three-beat cycle, fixed and never randomised so it can be learned: a small
## hit, a big hit, then a guard raised while it curses the reel. The guard goes
## up on its own turn and stands through the player's next one, so the turn
## after being cursed is also the turn your attacks land in a wall.
##
## Its clock is mostly the strip: every third turn adds a curse that lasts the
## rest of the fight, so by the late game the player's own reel is working
## against them. That is a different fight from the Pit Boss damage race, which
## is the reason to have both — so the numeric escalation is deliberately mild,
## +2 per full cycle, just enough that a purely defensive player cannot sit
## there forever while the curses do all the work.
##
## The guard does not escalate. It is not where the pressure comes from, and a
## growing wall would eventually make the cool beat unanswerable.

const SMALL_HIT: int = 8
const BIG_HIT: int = 18
const GUARD: int = 20
## Added to both hits after each completed cycle.
const ESCALATION: int = 2

enum Phase { SMALL, BIG, COOL }

var phase: Phase = Phase.SMALL
var cycles_completed: int = 0


func _init() -> void:
	display_name = "The Cooler"
	max_health = 180
	health = max_health


func _choose_intent() -> void:
	var step := ESCALATION * cycles_completed
	match phase:
		Phase.SMALL:
			var small := SMALL_HIT + step
			intent = { "type": "attack", "value": small }
			custom_intent_str = "Testing the deck — %d" % small
		Phase.BIG:
			var big := BIG_HIT + step
			intent = { "type": "attack", "value": big }
			custom_intent_str = "Calling it in — %d" % big
		Phase.COOL:
			intent = { "type": "block", "value": GUARD }
			custom_intent_str = "Cooling the machine — %d block" % GUARD

	phase = ((phase + 1) % 3) as Phase
	if phase == Phase.SMALL:
		cycles_completed += 1


## The cool beat guards *and* curses. Both land on its own turn: the guard then
## stands through the player's next turn, which is the only turn it could
## matter for.
func get_actions() -> Array[Action]:
	if intent.get("type") != "block":
		return super()
	_apply_curse()
	return [Action.new(Action.Type.DEFEND, intent.get("value"),
		"The Cooler guards for %d" % intent.get("value"))]


func _apply_curse() -> void:
	var debuff := DebuffPool.get_random_debuff(Global.player)
	if debuff != null:
		Global.player.apply_debuff(debuff)
