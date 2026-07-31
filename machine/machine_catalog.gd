extends RefCounted
class_name MachineCatalog
## Every machine that exists, in one place — the same rule as EnemyCatalog.
## The select screen enumerates from here and nothing else keeps a list.

const SLOW_PLAY := preload("res://run_effect/souvenir/souvenirs/slow_play_souvenir.gd")


## Built fresh rather than held as static vars: a static var initialiser cannot
## safely depend on another file's statics being ready, and machines are cheap.
static func all() -> Array[Machine]:
	return [_reg(), _nit()]


## The baseline. Every tier of attack and block, one Penny, two Blanks — 16
## stops at 50 combat value, and the strip every other machine is measured
## against.
static func _reg() -> Machine:
	var T := SymbolTable
	return Machine.new(
		"The Reg",
		"A working machine. Every tier, nothing special.",
		[T.LIGHT_ATK, T.LIGHT_BLK, T.MED_ATK, T.BLANK, T.HEAVY_ATK,
		T.MED_BLK, T.LIGHT_ATK, T.MED_BLK, T.MEGA_ATK, T.BLANK,
		T.LIGHT_BLK, T.PENNY, T.HEAL, T.MED_ATK, T.LIGHT_ATK, T.HEAVY_BLK] as Array[Symbol])


## Block breadth, damage depth. Six Light Blks mean it is almost never
## defenceless — thin-block lines drop from 29% to 20% — while a third of its
## lines deal no damage at all against The Reg's 5%. When damage does land it is
## a 6 or a 10.
##
## Carries only 38 combat value against The Reg's 50, and that gap is the point:
## concentration feeds the run bonus, so a focused strip gets roughly a 50%
## premium on the same points. A focused machine has to be given about
## three-quarters of the generalist's budget to end up lateral.
static func _nit() -> Machine:
	var T := SymbolTable
	return Machine.new(
		"The Nit",
		"Folds and folds, then takes the pot.",
		[T.LIGHT_BLK, T.BLANK, T.HEAVY_ATK, T.LIGHT_BLK, T.MED_BLK,
		T.LIGHT_BLK, T.MEGA_ATK, T.BLANK, T.LIGHT_BLK, T.HEAL,
		T.LIGHT_BLK, T.PENNY, T.HEAVY_ATK, T.LIGHT_BLK, T.BLANK] as Array[Symbol],
		[SLOW_PLAY] as Array[GDScript])
