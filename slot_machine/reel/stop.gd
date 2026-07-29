extends RefCounted
class_name Stop

## What is printed on this position of the reel. For a Mystery stop this is the
## mystery face itself, not what it turned out to be worth.
var base_symbol: Symbol

## Set only on Mystery stops, once a spin has decided them.
##
## `symbol` returns this when present, so every existing reader keeps working
## untouched. Making callers ask for the resolved value instead would mean 28
## sites each having to remember — the sort of thing that gets remembered in the
## scorer and forgotten in the paytable, which is the exact bug class §0 is
## about. Anything that genuinely wants the reel's own face (the Reel Preview,
## the strip editor) asks for base_symbol.
var resolved: Symbol

var symbol: Symbol:
	get:
		return resolved if resolved != null else base_symbol
	set(value):
		base_symbol = value

var modifiers: Array[StopModifier] = []


func _init(p_symbol: Symbol) -> void:
	base_symbol = p_symbol


func is_mystery() -> bool:
	return base_symbol == SymbolTable.MYSTERY


## Decides what this stop is worth for the coming spin. Unweighted, per §
## Mystery: every face is as likely as any other, which is the gamble.
func reroll() -> void:
	if not is_mystery():
		return
	var pool := SymbolTable.mystery_pool()
	resolved = pool.pick_random() if not pool.is_empty() else null
