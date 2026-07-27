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
## Its swings never grow. The entire clock is the strip: every third turn either
## adds a curse or deepens one, and they last the fight, so by the late game the
## player's own reel is what is killing them. A rising swing on top would blur
## that — the fight would read as a damage race with curses attached, which is
## the Pit Boss's job, not this one's.
##
## The guard does not grow either. It is not where the pressure comes from, and
## a growing wall would eventually make the cool beat unanswerable.

const SMALL_MIN: int = 5
const SMALL_MAX: int = 10
const BIG_MIN: int = 15
const BIG_MAX: int = 20
const GUARD: int = 20

const CURSES: Array = [
	preload("res://run_effect/debuff/debuffs/live_wire_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/marked_card_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/cold_deck_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/reel_jam_debuff.gd"),
]

enum Phase { SMALL, BIG, COOL }

## How often the cool beat deepens an existing curse rather than adding a new
## kind. Weighted toward deepening: three different curses is confusing, one
## curse getting genuinely dangerous is a clock.
const ESCALATE_CHANCE := 0.65

var phase: Phase = Phase.SMALL


func _init() -> void:
	display_name = "The Cooler"
	max_health = 180
	health = max_health


func _choose_intent() -> void:
	match phase:
		Phase.SMALL:
			intent = { "type": "attack", "value": randi_range(SMALL_MIN, SMALL_MAX) }
		Phase.BIG:
			intent = { "type": "attack", "value": randi_range(BIG_MIN, BIG_MAX) }
		Phase.COOL:
			intent = { "type": "block", "value": GUARD }

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


## The cool beat always makes things worse, but not always in the same way. A
## curse already on the reel either gains a level or gains a copy — harder hits
## versus more frequent ones, which are different problems. Only when nothing
## is escalatable does it reach for a fresh debuff.
func _apply_curse() -> void:
	var curses: Array[CurseSymbolDebuff] = []
	for d: Debuff in Global.player.active_debuffs:
		if d is CurseSymbolDebuff and (d as CurseSymbolDebuff).can_deepen():
			curses.append(d)

	if not curses.is_empty() and randf() < ESCALATE_CHANCE:
		var curse: CurseSymbolDebuff = curses.pick_random()
		if randf() < 0.5:
			curse.upgrade()
			Toast.show_debuff(curse.display_name, curse.description, "",
				"\"It bites harder now.\"")
		else:
			curse.add_copy()
			Toast.show_debuff(curse.display_name, curse.description, "",
				"\"Another one finds its way in.\"")
		return

	var debuff := _roll_curse()
	if debuff != null:
		Global.player.apply_debuff(debuff)


## Its own short list, not the global pool. The Cooler's fantasy is corrupting
## the machine, so it deals in the curses that do that — pulling from every
## debuff in the game handed out things like a line-cap cut, which has nothing
## to do with this boss and only bites players who happened to buy an upgrade.
func _roll_curse() -> Debuff:
	var candidates: Array[Debuff] = []
	for script in CURSES:
		var debuff: Debuff = script.new()
		if debuff.can_apply(Global.player):
			candidates.append(debuff)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
