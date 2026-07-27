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
## Unlike the Pit Boss it does not escalate its numbers. Its clock is the strip:
## every third turn adds a curse that lasts the rest of the fight, so by the
## late game the player's own reel is working against them. That is a different
## fight from a damage race, which is the reason to have both.

const SMALL_HIT: int = 8
const BIG_HIT: int = 18
const GUARD: int = 20

enum Phase { SMALL, BIG, COOL }

var phase: Phase = Phase.SMALL


func _init() -> void:
	display_name = "The Cooler"
	max_health = 180
	health = max_health


func _choose_intent() -> void:
	match phase:
		Phase.SMALL:
			intent = { "type": "attack", "value": SMALL_HIT }
			custom_intent_str = "Testing the deck — %d" % SMALL_HIT
		Phase.BIG:
			intent = { "type": "attack", "value": BIG_HIT }
			custom_intent_str = "Calling it in — %d" % BIG_HIT
		Phase.COOL:
			intent = { "type": "block", "value": GUARD }
			custom_intent_str = "Cooling the machine — %d block" % GUARD
	phase = ((phase + 1) % 3) as Phase


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
