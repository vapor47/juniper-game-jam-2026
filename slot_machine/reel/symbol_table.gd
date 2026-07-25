extends RefCounted
class_name SymbolTable
## §3 symbol table + strip order. One singleton Symbol instance per symbol type,
## reused across every stop so exact-symbol matching can compare by reference.

## Values are 2x the §3 table. Stop counts are untouched, so the 50/35
## damage/block supply ratio and the inverse value-to-frequency relationship
## both hold. Heal stays at half of Heavy Blk at equal rarity, the ratio §3
## says to preserve if either is retuned.
static var LIGHT_ATK := Symbol.new("Light Atk", Action.Type.ATTACK, 2,
		preload("res://assets/icons/light_attack_icon.svg"))
static var MED_ATK := Symbol.new("Med Atk", Action.Type.ATTACK, 4,
		preload("res://assets/icons/medium_attack_icon.svg"))
static var HEAVY_ATK := Symbol.new("Heavy Atk", Action.Type.ATTACK, 6,
		preload("res://assets/icons/heavy_attack_icon.svg"))
static var MEGA_ATK := Symbol.new("Mega Atk", Action.Type.ATTACK, 10,
		preload("res://assets/icons/multiply_attack_icon.svg"))
static var LIGHT_BLK := Symbol.new("Light Blk", Action.Type.DEFEND, 2,
		preload("res://assets/icons/defend/light_defend_icon.svg"))
static var MED_BLK := Symbol.new("Med Blk", Action.Type.DEFEND, 4,
		preload("res://assets/icons/defend/medium_defend_icon.svg"))
static var HEAVY_BLK := Symbol.new("Heavy Blk", Action.Type.DEFEND, 8,
		preload("res://assets/icons/defend/heavy_defend_icon.svg"))
static var HEAL := Symbol.new("Heal", Action.Type.HEAL, 4)
static var BLANK := Symbol.new("Blank", Action.Type.NONE, 0)


## Price by *inherent symbol quality* only (§6). Never scale by how many copies
## are already on the strip: match contribution grows with p², so the k-th copy
## is worth more than the last, and that increasing return is the build payoff.
## Charging more as the player specializes would tax exactly the commitment the
## system is supposed to reward.
static var PRICES := {
	LIGHT_ATK: 40,
	MED_ATK: 70,
	HEAVY_ATK: 110,
	MEGA_ATK: 200,
	LIGHT_BLK: 45,
	MED_BLK: 80,
	HEAVY_BLK: 150,
	HEAL: 90,
}


static func price_of(symbol: Symbol) -> int:
	return PRICES.get(symbol, 60)


## Everything the shop can sell. Blank is deliberately not purchasable — it
## exists on the starting strip as a tutorial for the removal verb (§3).
static func purchasable() -> Array[Symbol]:
	return [
		LIGHT_ATK, MED_ATK, HEAVY_ATK, MEGA_ATK,
		LIGHT_BLK, MED_BLK, HEAVY_BLK, HEAL,
	]


## §3 strip order, stops 1-20, circular. Order is a design layer (adjacency
## determines what can co-occur in a column window) — do not reshuffle.
static func build_default_strip() -> Array[Symbol]:
	return [
		LIGHT_ATK, LIGHT_BLK, MED_ATK, BLANK, HEAVY_ATK,
		LIGHT_BLK, LIGHT_ATK, MED_BLK, MED_ATK, BLANK,
		MEGA_ATK, LIGHT_BLK, LIGHT_ATK, HEAL, HEAVY_ATK,
		LIGHT_BLK, MED_ATK, MED_BLK, LIGHT_ATK, HEAVY_BLK,
	]
