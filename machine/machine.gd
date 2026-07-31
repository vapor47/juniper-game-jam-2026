extends RefCounted
class_name Machine
## A machine the player sits down at: a starting strip, and whatever it comes
## with.
##
## This is the character-select analogue, and it is deliberately thin — the
## strip system already exists, so a machine is a different `build_strip()` plus
## an optional starting souvenir. Nothing else in the game needs to know a
## machine exists; Global holds the chosen one and the strip loads from it.
##
## Composition carries *how a machine plays*; a starting souvenir carries a rule
## composition cannot express. The Nit is block breadth and premium damage, and
## Slow Play is "folding is a legal, rewarded turn" — no arrangement of stops
## can say that.

var display_name: String
var description: String

var _strip: Array[Symbol] = []
var _souvenirs: Array[GDScript] = []


func _init(p_name: String, p_description: String, p_strip: Array[Symbol],
		p_souvenirs: Array[GDScript] = []) -> void:
	display_name = p_name
	description = p_description
	_strip = p_strip
	_souvenirs = p_souvenirs


## A fresh copy every call — the caller turns these into Stops, and handing out
## the shared array would let one run's edits leak into the next.
func build_strip() -> Array[Symbol]:
	return _strip.duplicate()


func starting_souvenirs() -> Array[Souvenir]:
	var out: Array[Souvenir] = []
	for script: GDScript in _souvenirs:
		out.append(script.new())
	return out


## Distinct symbols and counts, in display order — what the select screen shows
## so a machine can be judged before it is chosen.
func tally() -> Array:
	var counts := {}
	for symbol: Symbol in _strip:
		counts[symbol] = counts.get(symbol, 0) + 1
	var symbols: Array[Symbol] = []
	for symbol: Symbol in counts:
		symbols.append(symbol)
	var out: Array = []
	for symbol: Symbol in SymbolTable.sort_for_display(symbols):
		out.append([symbol, counts[symbol]])
	return out
