extends RefCounted
class_name SymbolTable
## §3 symbol table + strip order. One singleton Symbol instance per symbol type,
## reused across every stop so exact-symbol matching can compare by reference.
##
## Only the nine §3 symbols appear on the starting strip. Everything below that
## line is shop-only, so the opening strip stays exactly as §3 tuned it and the
## additions are genuine build choices rather than dilution.

# ------------------------------------------------------------ starting strip

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
static var BLANK := _make("Blank", Action.Type.NONE, 0, Symbol.Rarity.COMMON)

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
static var PENNY := _board("Penny", Action.Type.GOLD, 1, Symbol.Rarity.COMMON, Symbol.Trigger.ON_SPIN)

## Flat only — see Symbol.combos.
static var TOKEN := _no_combo("Token", Action.Type.TOKEN, 1, Symbol.Rarity.RARE)

## Dead on a payline, pays only for being on the board. You want it visible and
## off your lines, which is the whole point of it.
static var CHIP := _board("Chip", Action.Type.NONE, 0, Symbol.Rarity.COMMON, Symbol.Trigger.ON_LOCK)

## Pays only as three or more in a row on a played line, like a slot line.
## Nothing below that, so it is a genuine jackpot rather than filler — and a
## Wild can stand in for one of the three.
static var LUCKY_SEVEN := _jackpot()

const CHIP_GOLD_PER_COPY := 5
const PENNY_GOLD_PER_COPY := 1


## run length -> [tokens, gold]
static func _jackpot() -> Symbol:
	var s := _make("Lucky Seven", Action.Type.NONE, 0, Symbol.Rarity.UNCOMMON)
	s.min_run = 3
	s.payout = {
		3: [4, 100],
		4: [8, 250],
		5: [15, 600],
	}
	return s


static func _make(n: String, t: Action.Type, v: int, r: Symbol.Rarity,
		icon: Texture2D = null) -> Symbol:
	var s := Symbol.new(n, t, v, icon)
	s.rarity = r
	return s


static func _wild() -> Symbol:
	var s := Symbol.new("Wild", Action.Type.NONE, 0)
	s.rarity = Symbol.Rarity.RARE
	s.is_wild = true
	return s


static func _no_combo(n: String, t: Action.Type, v: int, r: Symbol.Rarity) -> Symbol:
	var s := _make(n, t, v, r)
	s.combos = false
	return s


static func _board(n: String, t: Action.Type, v: int, r: Symbol.Rarity,
		trigger: Symbol.Trigger) -> Symbol:
	var s := _make(n, t, v, r)
	s.trigger = trigger
	return s


## Price by inherent symbol quality only (§6). Never scale by how many copies
## are already on the strip: the k-th copy is worth more than the last, and
## that increasing return is the build payoff.
static var PRICES := {
	LIGHT_ATK: 40, MED_ATK: 70, HEAVY_ATK: 110, MEGA_ATK: 200,
	LIGHT_BLK: 45, MED_BLK: 80, HEAVY_BLK: 150, HEAL: 90,
	MEGA_BLK: 200, WILD: 300, COIN: 120, PENNY: 90,
	TOKEN: 220, CHIP: 80, LUCKY_SEVEN: 100,
}


static func price_of(symbol: Symbol) -> int:
	return PRICES.get(symbol, 60)


## Everything the shop can sell. Blank is deliberately absent — it exists on
## the starting strip as a tutorial for the removal verb (§3).
static func purchasable() -> Array[Symbol]:
	return [
		LIGHT_ATK, MED_ATK, HEAVY_ATK, MEGA_ATK,
		LIGHT_BLK, MED_BLK, HEAVY_BLK, HEAL,
		MEGA_BLK, WILD, COIN, PENNY, TOKEN, CHIP, LUCKY_SEVEN,
	]


## §3 strip order, stops 1-20, circular. Order is a design layer (adjacency
## determines what can co-occur in a column window) — do not reshuffle, and
## keep shop-only symbols out of it.
static func build_default_strip() -> Array[Symbol]:
	return [
		LIGHT_ATK, LIGHT_BLK, MED_ATK, BLANK, HEAVY_ATK,
		LIGHT_BLK, LIGHT_ATK, MED_BLK, MED_ATK, BLANK,
		MEGA_ATK, LIGHT_BLK, LIGHT_ATK, HEAL, HEAVY_ATK,
		LIGHT_BLK, MED_ATK, MED_BLK, LIGHT_ATK, HEAVY_BLK,
	]
