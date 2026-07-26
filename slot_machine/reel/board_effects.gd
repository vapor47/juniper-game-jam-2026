extends RefCounted
class_name BoardEffects
## Symbols that pay for being on the board at all, rather than for sitting on a
## played line. Reads all 15 cells, so the whole grid matters and not just the
## lines you bought.
##
## Two timings, because they want different play:
##   ON_SPIN — after every spin and respin. Penny trickles, so respinning pays
##             a little. The escalating respin cost is the brake.
##   ON_LOCK — once, as the turn resolves. Chip pays properly, and can't be
##             farmed by respinning at it.


static func visible_symbols(columns: Array[ReelColumn]) -> Array[Symbol]:
	var out: Array[Symbol] = []
	for column: ReelColumn in columns:
		if column.reel == null or column.reel.strip.is_empty():
			continue
		for stop: Stop in column.reel.visible_stops():
			out.append(stop.symbol)
	return out


static func _count(symbols: Array[Symbol], target: Symbol) -> int:
	var n := 0
	for s: Symbol in symbols:
		if s == target:
			n += 1
	return n


## Gold from symbols that pay per copy showing. Returns what was granted so the
## caller can surface it.
static func apply(columns: Array[ReelColumn], trigger: Symbol.Trigger) -> int:
	if Global.player == null:
		return 0

	var symbols := visible_symbols(columns)
	var gold := 0

	if trigger == Symbol.Trigger.ON_SPIN:
		gold += _count(symbols, SymbolTable.PENNY) * SymbolTable.PENNY_GOLD_PER_COPY
	elif trigger == Symbol.Trigger.ON_LOCK:
		gold += _count(symbols, SymbolTable.CHIP) * SymbolTable.CHIP_GOLD_PER_COPY

	if gold > 0:
		Global.player.gold += gold
	return gold
