extends Debuff
class_name CurseSymbolDebuff
## Base for debuffs that jam a symbol onto the player's reel.
##
## The strip is shared by reference with every column, so inserting is enough
## for all five to see it. Removal has to find the exact Stop that was added
## rather than the first matching symbol — the player may have been cursed more
## than once, and removing someone else's copy would leave this one stranded.
##
## Inserted at a random position because order is a design layer (§6): dropping
## every curse at the end would make them predictably adjacent, and adjacency
## decides what can share a column.

var symbol: Symbol
var _stop: Stop


func _init(p_symbol: Symbol) -> void:
	symbol = p_symbol
	display_name = p_symbol.symbol_name
	rarity = RunEffect.Rarity.UNCOMMON


func on_acquired(_player: PlayerData) -> void:
	_stop = Stop.new(symbol)
	var at := randi() % maxi(1, Global.strip.size() + 1)
	Global.strip.insert(at, _stop)


func on_removed(_player: PlayerData) -> void:
	if _stop == null:
		return
	var i := Global.strip.find(_stop)
	if i != -1:
		Global.strip.remove_at(i)
	_stop = null
