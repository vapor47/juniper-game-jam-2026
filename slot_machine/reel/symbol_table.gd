extends RefCounted
class_name SymbolTable
## §3 symbol table + strip order. One singleton Symbol instance per symbol type,
## reused across every stop so exact-symbol matching can compare by reference.
##
## Only the nine §3 symbols appear on the starting strip. Everything below that
## line is shop-only, so the opening strip stays exactly as §3 tuned it and the
## additions are genuine build choices rather than dilution.

# ------------------------------------------------------------ starting strip

# Payout constants live above the symbols because the symbols read them when
# they build their own description strings, and a static var initialiser cannot
# see a constant declared further down the file.

## Gold per Recycler per junk symbol. Multiplying both counts is the point: the
## pair scales quadratically, which is what makes committing strip space to two
## dead symbols worth doing. Junk dilutes everything else on the strip, so the
## build pays for itself — and curses count, so being cursed pays a little.
const RECYCLER_GOLD_PER_JUNK := 2
const CHIP_GOLD_PER_COPY := 5
const PENNY_GOLD_PER_COPY := 1

## Both scale with the curse's level, which The Cooler raises as the fight runs.
## Damage per Live Wire showing, per spin, per level.
const LIVE_WIRE_DAMAGE_PER_LEVEL := 2
## Damage per Marked Card sitting on a line you played, per level.
const MARKED_CARD_DAMAGE_PER_LEVEL := 3


static var LIGHT_ATK := _make("Light Atk", Action.Type.ATTACK, 2, Symbol.Rarity.COMMON,
		preload("res://assets/icons/light_attack_icon.svg"))
static var MED_ATK := _make("Med Atk", Action.Type.ATTACK, 4, Symbol.Rarity.COMMON,
		preload("res://assets/icons/medium_attack_icon.svg"))
static var HEAVY_ATK := _make("Heavy Atk", Action.Type.ATTACK, 6, Symbol.Rarity.UNCOMMON,
		preload("res://assets/icons/heavy_attack_icon.svg"))
static var MEGA_ATK := _make("Mega Atk", Action.Type.ATTACK, 10, Symbol.Rarity.RARE,
		preload("res://assets/icons/multiply_attack_icon.svg"))
static var LIGHT_BLK := _make("Light Blk", Action.Type.DEFEND, 2, Symbol.Rarity.COMMON,
		preload("res://assets/icons/defend/light_defend_icon.svg"))
static var MED_BLK := _make("Med Blk", Action.Type.DEFEND, 4, Symbol.Rarity.COMMON,
		preload("res://assets/icons/defend/medium_defend_icon.svg"))
static var HEAVY_BLK := _make("Heavy Blk", Action.Type.DEFEND, 8, Symbol.Rarity.UNCOMMON,
		preload("res://assets/icons/defend/heavy_defend_icon.svg"))
static var HEAL := _make("Heal", Action.Type.HEAL, 4, Symbol.Rarity.UNCOMMON)
## Still the thing you first learn to remove; it becomes a resource only next to
## something that pays for junk. Its own tier, so keeping it off the shelf costs
## the good symbols nothing.
static var BLANK := _junk("Blank")

# -------------------------------------------------------------- shop only

## Block is capped by the intent and overflow is wasted (§3), so this is worth
## less than Mega Atk's 10 despite matching it — deliberately not a mirror.
static var MEGA_BLK := _make("Mega Blk", Action.Type.DEFEND, 10, Symbol.Rarity.RARE)

## Substitutes for whatever it sits beside, taking that symbol's identity and
## value. Between two different symbols it joins both runs.
static var WILD := _wild()

## Economy symbols. Coin and Penny pay through the normal run machinery; Penny
## also trickles gold every spin just for being on the board.
static var COIN := _make("Coin", Action.Type.GOLD, 5, Symbol.Rarity.UNCOMMON)
static var PENNY := _board("Penny", Action.Type.GOLD, 1, Symbol.Rarity.COMMON,
	Symbol.Trigger.ON_SPIN, "+%d gold %s" % [PENNY_GOLD_PER_COPY, Symbol.ON_APPEARANCE])

## Flat only — see Symbol.combos.
static var TOKEN := _no_combo("Token", Action.Type.TOKEN, 1, Symbol.Rarity.RARE)

## Dead on a payline, pays only for being on the board. You want it visible and
## off your lines, which is the whole point of it.
## Curses. Injected onto the strip by debuffs, never sold. Both are junk, so a
## Recycler build gets a little back from being cursed.
##
## Live Wire fires every spin, including the free opening one — it is a flat
## tax first and a respin deterrent second.
static var LIVE_WIRE := _curse("Live Wire", Symbol.Trigger.ON_SPIN,
	"Damages you %s" % Symbol.ON_APPEARANCE)
## Marked Card has no board trigger at all: it costs only when it sits on a line
## you actually play. That is the whole point of it — the cost lands on the
## decision, so the best line of the turn can be the one carrying a price.
static var MARKED_CARD := _curse("Marked Card", Symbol.Trigger.NONE,
	"Damages you when its line pays")

## Lands undecided and becomes something else for the spin. Its own face never
## scores — `Stop.resolved` stands in for it once a spin has rolled.
static var MYSTERY := _mystery()

## Freezes whatever column it lands in. Fires on spin because that is when the
## column locks up — it pays nothing, so BoardEffects ignores it and combat
## reads the board for it directly.
static var REEL_JAM := _curse("Reel Jam", Symbol.Trigger.ON_SPIN,
	"Freezes its column %s" % Symbol.ON_APPEARANCE)



## Pays for the junk on the board. Two symbols that are worthless alone and
## worth something together — and both cost strip space, which is the price.
static var RECYCLER := _board("Recycler", Action.Type.NONE, 0, Symbol.Rarity.UNCOMMON,
	Symbol.Trigger.ON_LOCK,
	"+%d gold per junk symbol %s" % [RECYCLER_GOLD_PER_JUNK, Symbol.ON_LOCK_IN])

static var CHIP := _board("Chip", Action.Type.NONE, 0, Symbol.Rarity.COMMON,
	Symbol.Trigger.ON_LOCK, "+%d gold %s" % [CHIP_GOLD_PER_COPY, Symbol.ON_LOCK_IN])

## Pays only as three or more in a row on a played line, like a slot line.
## Nothing below that, so it is a genuine jackpot rather than filler — and a
## Wild can stand in for one of the three.
static var LUCKY_SEVEN := _jackpot()


## A full line of Wilds pays out everything at once.
##
## DELIBERATELY UNDOCUMENTED IN GAME. Nothing in the shop blurb, the cell
## tooltip or the payline readout hints that this exists — it is meant to be
## stumbled into, not read about. Don't "helpfully" surface it later.
##
## Wilds have no identity of their own, so ordinarily an all-wild line scores
## nothing; this turns the one hand that should feel best into the one that
## paid least.
##
## PROBABILITY, and the trap in it: all five columns are independent windows
## into the SAME strip, so one stop can show in every column at once. A single
## Wild is enough to make this possible — copies are not required, they only
## shorten the odds. Each payline cell is a uniform draw from the strip, so an
## all-Wild line is (wilds / strip_size) ^ 5: about 1 in 3,200,000 with one
## Wild on a 20-stop strip, 1 in 100,000 with two, 1 in 13,000 with three.
const WILD_JACKPOT := {
	"attack": 250,
	"block": 100,
	"heal": 50,
	"gold": 500,
	"tokens": 10,
}


## run length -> [tokens, gold]
##
## Sized against measured odds, not guessed ones. Three in a row on a single
## line runs 1 in 2,500 with one stop on the strip, 1 in 380 with two and 1 in
## 112 with three — each payline cell is a uniform draw from the shared strip,
## so a run of three is roughly (stops / strip_size) ^ 3. An earlier table was
## priced against a much looser figure that belonged to a different, discarded
## design where sevens counted across the whole grid.
##
## The gold weighting past the first tier dates from a token cap of 10, where
## grants above it were simply lost. The cap is now 100, so the token half of
## these tiers is worth far more than it was when they were set — left alone
## deliberately rather than retuned in passing.
static func _jackpot() -> Symbol:
	var s := _make("Lucky Seven", Action.Type.NONE, 0, Symbol.Rarity.UNCOMMON)
	s.min_run = 3
	s.effect_override = "3 in a row pays 6 tokens and 400 gold, and more beyond that"
	s.payout = {
		3: [6, 400],
		4: [10, 900],
		5: [10, 2000],
	}
	return s


static func _junk(n: String) -> Symbol:
	var s := _make(n, Action.Type.NONE, 0, Symbol.Rarity.JUNK)
	s.is_junk = true
	return s


static func _make(n: String, t: Action.Type, v: int, r: Symbol.Rarity,
		icon: Texture2D = null) -> Symbol:
	var s := Symbol.new(n, t, v, icon)
	s.rarity = r
	return s


static func _mystery() -> Symbol:
	var s := _make("Mystery", Action.Type.NONE, 0, Symbol.Rarity.UNCOMMON)
	s.effect_override = "Becomes a random symbol already on your reel"
	return s


static func _wild() -> Symbol:
	var s := Symbol.new("Wild", Action.Type.NONE, 0)
	s.rarity = Symbol.Rarity.RARE
	s.is_wild = true
	s.effect_override = "Counts as whatever it sits beside"
	return s


static func _no_combo(n: String, t: Action.Type, v: int, r: Symbol.Rarity) -> Symbol:
	var s := _make(n, t, v, r)
	s.combos = false
	return s


static func _board(n: String, t: Action.Type, v: int, r: Symbol.Rarity,
		trigger: Symbol.Trigger, board_text: String = "") -> Symbol:
	var s := _make(n, t, v, r)
	s.trigger = trigger
	s.board_text = board_text
	return s


static func _curse(n: String, trigger: Symbol.Trigger, text: String = "") -> Symbol:
	var s := _board(n, Action.Type.NONE, 0, Symbol.Rarity.JUNK, trigger, text)
	s.is_curse = true
	s.is_junk = true
	return s


## Price by inherent symbol quality only (§6). Never scale by how many copies
## are already on the strip: the k-th copy is worth more than the last, and
## that increasing return is the build payoff.
static var PRICES := {
	LIGHT_ATK: 40, MED_ATK: 70, HEAVY_ATK: 110, MEGA_ATK: 200,
	LIGHT_BLK: 45, MED_BLK: 80, HEAVY_BLK: 150, HEAL: 90,
	MEGA_BLK: 200, WILD: 300, COIN: 120, PENNY: 90,
	TOKEN: 220, CHIP: 80, LUCKY_SEVEN: 70,
	RECYCLER: 130, BLANK: 20,
}


## The one display order: action type, then value. Used by the paytable and the
## reel preview's tally, so a symbol keeps the same relative place everywhere it
## is listed.
## What a Mystery stop can turn into: whatever else is already on the reel.
##
## Drawn from the strip rather than the shop catalogue, so it scales with the
## machine the player actually built — a strip of Mega Atks makes Mystery
## dangerous, a strip of Blanks makes it worthless, and neither needs tuning.
## It also means nothing has to be maintained as new symbols are added.
##
## Curses are eligible when the player is carrying one, deliberately: a Mystery
## can only ever become something already on the reel, so it never introduces a
## risk the board did not already hold.
##
## Distinct symbols, not weighted by how many copies there are. Weighting by
## count would make Mystery quietly mirror the strip's own odds, which is what
## an ordinary stop already does.
static func mystery_pool() -> Array[Symbol]:
	var out: Array[Symbol] = []
	for stop: Stop in Global.strip:
		var candidate: Symbol = stop.base_symbol
		if candidate != MYSTERY and candidate not in out:
			out.append(candidate)
	return out


static func sort_for_display(symbols: Array[Symbol]) -> Array[Symbol]:
	symbols.sort_custom(func(a: Symbol, b: Symbol) -> bool:
		if a.type != b.type:
			return a.type < b.type
		return a.value < b.value)
	return symbols


static func price_of(symbol: Symbol) -> int:
	return PRICES.get(symbol, 60)


## The weighted stop pool. Blank sits in its own JUNK tier rather than among the
## rares: rarity here is meant to gate power, and Blank is not rare because it
## is strong. Sharing the rare tier meant a worthless symbol ate a fifth of the
## appearances Wild and the Megas draw from.
static func purchasable() -> Array[Symbol]:
	return [
		LIGHT_ATK, MED_ATK, HEAVY_ATK, MEGA_ATK,
		LIGHT_BLK, MED_BLK, HEAVY_BLK, HEAL,
		MEGA_BLK, WILD, COIN, PENNY, TOKEN, CHIP, LUCKY_SEVEN,
		RECYCLER, BLANK, MYSTERY,
	]


## §3 strip order, stops 1-20, circular. Order is a design layer (adjacency
## determines what can co-occur in a column window) — do not reshuffle, and
## keep shop-only symbols out of it.
static func build_default_strip() -> Array[Symbol]:
	return [
		LIGHT_ATK, LIGHT_BLK, MED_ATK, BLANK, HEAVY_ATK,
		MED_BLK, LIGHT_ATK, MED_BLK, MEGA_ATK, BLANK,
		LIGHT_BLK, HEAL, MED_ATK, LIGHT_ATK, HEAVY_BLK,
	]
