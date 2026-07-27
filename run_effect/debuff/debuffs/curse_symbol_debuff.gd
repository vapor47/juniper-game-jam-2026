extends Debuff
class_name CurseSymbolDebuff
## Base for debuffs that jam a symbol onto the player's reel.
##
## The strip is shared by reference with every column, so inserting is enough
## for all five to see it. Removal finds the exact Stops this debuff added
## rather than the first matching symbol — the same curse can be applied twice,
## and removing someone else's copy would strand this one on the reel forever.
##
## Two independent ways to get worse, and The Cooler picks between them: `level`
## makes each copy hit harder, extra copies make it hit more often. They feel
## different — one raises the cost of a bad board, the other raises how often
## you get one.

var symbol: Symbol
var level: int = 1

var _stops: Array[Stop] = []


func _init(p_symbol: Symbol) -> void:
	symbol = p_symbol
	display_name = p_symbol.symbol_name
	rarity = RunEffect.Rarity.UNCOMMON


func on_acquired(_player: PlayerData) -> void:
	add_copy()


## One more of this symbol on the reel, at a random position: order is a design
## layer (§6), and dropping every curse at the end would make them predictably
## adjacent when adjacency is what decides who can share a column.
func add_copy() -> void:
	var stop := Stop.new(symbol)
	_stops.append(stop)
	Global.strip.insert(randi() % maxi(1, Global.strip.size() + 1), stop)
	refresh_text()


## Whether The Cooler may deepen this curse. Some effects are strong enough at
## one copy that scaling them produces dead boards rather than harder ones.
func can_deepen() -> bool:
	return true


func upgrade() -> void:
	level += 1
	refresh_text()


func copies() -> int:
	return _stops.size()


func refresh_text() -> void:
	description = describe()


## Overridden per curse.
func describe() -> String:
	return "%d on your reel, level %d" % [copies(), level]


func on_removed(_player: PlayerData) -> void:
	for stop: Stop in _stops:
		var i := Global.strip.find(stop)
		if i != -1:
			Global.strip.remove_at(i)
	_stops.clear()
