extends EnemyData
class_name TheCoolerData
## A casino "cooler" is the person brought in to break a winning streak. This
## one breaks the machine instead.
##
## Three-beat cycle, fixed and never randomised so it can be learned: one swing,
## a heavy guard, then a lighter guard while it curses the reel. Only a third of
## its turns deal damage — it wins by outlasting, and by wrecking the machine
## while it does. Each guard stands through the player's next turn, so two turns
## in three the player is hitting a wall and is better off spending them on
## defence, healing, or setting the reel up.
##
## Its swings never grow. The entire clock is the strip: every third turn either
## adds a curse or deepens one, and they last the fight, so by the late game the
## player's own reel is what is killing them. A rising swing on top would blur
## that — the fight would read as a damage race with curses attached, which is
## the Pit Boss's job, not this one's.
##
## The guard does not grow either. It is not where the pressure comes from, and
## a growing wall would eventually make the cool beat unanswerable.

const HIT_MIN: int = 12
const HIT_MAX: int = 16
const GUARD_BIG: int = 30
const GUARD_SMALL: int = 15

const CURSES: Array = [
	preload("res://run_effect/debuff/debuffs/live_wire_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/marked_card_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/cold_deck_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/reel_jam_debuff.gd"),
]

enum Phase { SWING, GUARD, COOL }

## How often the cool beat deepens an existing curse rather than adding a new
## kind. Weighted toward deepening: three different curses is confusing, one
## curse getting genuinely dangerous is a clock.
const ESCALATE_CHANCE := 0.65

var phase: Phase = Phase.SWING


func _init() -> void:
	display_name = "The Cooler"
	max_health = 220
	health = max_health


func _choose_intent() -> void:
	match phase:
		Phase.SWING:
			intent = { "type": "attack", "value": randi_range(HIT_MIN, HIT_MAX) }
		Phase.GUARD:
			intent = { "type": "block", "value": GUARD_BIG }
		Phase.COOL:
			intent = { "type": "block", "value": GUARD_SMALL }

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
		# Only an axis this curse supports. Reel Jam has no level, so rolling
		# one for it would silently waste a cool beat.
		var upgrade := curse.can_upgrade()
		if upgrade and curse.can_add_copy():
			upgrade = randf() < 0.5
		if upgrade:
			curse.upgrade()
		else:
			curse.add_copy()
		Toast.show_debuff(curse.display_name, curse.description, "", "")
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
