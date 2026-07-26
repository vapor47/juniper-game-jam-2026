extends RefCounted
class_name Symbol

enum Rarity { COMMON, UNCOMMON, RARE }

## When a symbol's on-appearance effect fires, if it has one.
##   NONE     — no board effect
##   ON_SPIN  — after every spin and respin, off the settled board
##   ON_LOCK  — once, when the turn resolves
enum Trigger { NONE, ON_SPIN, ON_LOCK }

var symbol_name: String
var type: Action.Type
var value: int
var icon: Texture2D  # kept for future art; cells render name+colour for now

var rarity: Rarity = Rarity.COMMON

## Substitutes for whatever it sits beside on a line, taking that symbol's
## identity *and* value. It never carries its own modifiers into the run — see
## PaylineScorer.
var is_wild: bool = false

## Flat payout only: never scales with run length. Tokens gate both respins and
## extra lines, so a combo-able token symbol pays for several turns at once.
var combos: bool = true

var trigger: Trigger = Trigger.NONE

## Run length this symbol needs before it pays at all. Two for everything
## normal; Lucky Seven wants three, like a slot line.
var min_run: int = 2

## run length -> [tokens, gold]. When set, the symbol pays straight from this
## table instead of the value/bonus formula, and pays nothing below min_run.
var payout: Dictionary = {}


func _init(p_name: String, p_type: Action.Type, p_value: int, p_icon: Texture2D = null) -> void:
	symbol_name = p_name
	type = p_type
	value = p_value
	icon = p_icon


## Reads as a short effect line, e.g. "4 damage".
func effect_text() -> String:
	match type:
		Action.Type.ATTACK:
			return "%d damage" % value
		Action.Type.DEFEND:
			return "%d block" % value
		Action.Type.HEAL:
			return "%d heal" % value
		Action.Type.GOLD:
			return "%d gold" % value
		Action.Type.TOKEN:
			return "%d token" % value
		_:
			return "No effect"
