extends RefCounted
class_name Symbol

## JUNK is last so the existing ordinals are untouched. It exists so a symbol
## that is worthless on its own can be rolled without competing for a slot in
## the tier the good symbols come from.
enum Rarity { COMMON, UNCOMMON, RARE, JUNK }

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

## Dead weight on a line, and food for the effects that pay for dead weight.
## Blank and the curses share this: a cursed reel is worth something to a junk
## build, which is a small consolation rather than a defused debuff.
var is_junk: bool = false

## Injected by a debuff rather than bought. Never offered in the shop, and the
## strip editor's remove service is the counterplay.
var is_curse: bool = false

## Run length this symbol needs before it pays anything. One for everything
## normal — a lone stop still pays its value; the run bonus is a separate
## threshold at two. Only jackpot symbols raise this (Lucky Seven wants three).
var min_run: int = 1

## run length -> [tokens, gold]. When set, the symbol pays straight from this
## table instead of the value/bonus formula, and pays nothing below min_run.
var payout: Dictionary = {}

## The one vocabulary for *when* an effect fires. Defined here so the shop card,
## the paytable and the cell tooltip cannot drift into three different words for
## the same moment — which is exactly how the shop's colour table and the
## paytable's sort order went wrong (§0).
##
## "on appearance" rather than "each spin": it fires whenever the symbol is
## showing, including on a nudge, and "spin" would read as the lever only.
## "on lock in" matches the button the player actually presses.
const ON_APPEARANCE := "on appearance"
const ON_LOCK_IN := "upon lock in"

## What this symbol does beyond paying on a line — set next to the symbol's own
## definition rather than in a lookup somewhere else.
var board_text: String = ""

## Replaces the whole description for symbols whose worth is not a number.
var effect_override: String = ""


## The player-facing line for this symbol, used by the shop card and the cell
## tooltip. States the effect and nothing else: no "Adds a", no symbol name —
## the card is already titled with the name, and repeating it spends the one
## line that could have said something.
func describe() -> String:
	if effect_override != "":
		return effect_override

	var parts: Array[String] = []
	if type != Action.Type.NONE and value != 0:
		parts.append(effect_text())
	if board_text != "":
		parts.append(board_text)

	if parts.is_empty():
		return "Nothing"
	return "  ·  ".join(parts)


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
