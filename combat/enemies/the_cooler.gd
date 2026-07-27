extends EnemyData
class_name TheCoolerData
## A casino "cooler" is the person brought in to break a winning streak. This
## one breaks the machine instead.
##
## Three-beat cycle, fixed and never randomised so it can be learned: a swing
## that also raises a small guard, a heavy guard, then a bare turn spent cursing
## the reel. Only a third of its turns deal damage — it wins by outlasting, and
## by wrecking the machine while it does.
##
## A guard raised on its turn stands through the player's next one. Since the
## cool beat raises none, the turn after being cursed is the player's clear
## swing: the rhythm alternates rather than being wall after wall.
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
## Raised alongside the swing, so even its attacking turn is partly defensive.
const SWING_GUARD_MIN: int = 6
const SWING_GUARD_MAX: int = 12
const GUARD_MIN: int = 20
const GUARD_MAX: int = 30

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
	max_health = 300
	health = max_health


func _choose_intent() -> void:
	match phase:
		Phase.SWING:
			intent = {
				"type": "attack",
				"value": randi_range(HIT_MIN, HIT_MAX),
				"block": randi_range(SWING_GUARD_MIN, SWING_GUARD_MAX),
			}
		Phase.GUARD:
			intent = { "type": "block", "value": randi_range(GUARD_MIN, GUARD_MAX) }
		Phase.COOL:
			# No guard on the cool beat: the turn after it is the player's clear
			# swing, which is what keeps the rhythm from being all wall.
			intent = { "type": "curse" }

	phase = ((phase + 1) % 3) as Phase


## The curse lands on the cool beat and nowhere else. This used to key off the
## intent being a block, which fired it on both guarding turns — twice a cycle
## instead of once.
func get_actions() -> Array[Action]:
	if intent.get("type") == "curse":
		_apply_curse()
		return []
	return super()


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
