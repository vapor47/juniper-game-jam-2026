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


## Junk is Blank plus every curse, so a Recycler build gets something back from
## a corrupted reel.
static func count_junk(symbols: Array[Symbol]) -> int:
	var n := 0
	for s: Symbol in symbols:
		if s.is_junk:
			n += 1
	return n


## What a board paid, beyond gold. Curses cost damage and output, so a single
## int is no longer enough to report a trigger's outcome.
class Result extends RefCounted:
	var gold: int = 0
	var damage: int = 0
	var attack_penalty: int = 0

	func is_empty() -> bool:
		return gold == 0 and damage == 0 and attack_penalty == 0


## Applies everything that pays for merely being on the board. Grants gold and
## deals curse damage immediately; the attack penalty is returned for the
## caller to take off this turn's actions, since it has to land before they are
## performed rather than after.
static func apply(columns: Array[ReelColumn], trigger: Symbol.Trigger) -> Result:
	var result := Result.new()
	if Global.player == null:
		return result

	var symbols := visible_symbols(columns)
	var junk := count_junk(symbols)

	if trigger == Symbol.Trigger.ON_SPIN:
		result.gold += _count(symbols, SymbolTable.PENNY) * SymbolTable.PENNY_GOLD_PER_COPY
		# Every spin, the free opening one included: a flat tax first, a respin
		# deterrent second.
		result.damage += _count(symbols, SymbolTable.LIVE_WIRE) * SymbolTable.LIVE_WIRE_DAMAGE
	elif trigger == Symbol.Trigger.ON_LOCK:
		result.gold += _count(symbols, SymbolTable.CHIP) * SymbolTable.CHIP_GOLD_PER_COPY
		# Every Recycler pays for every junk symbol, so the pair scales on both
		# counts at once. ON_LOCK rather than ON_SPIN: junk is common enough
		# that respinning at it would farm freely.
		result.gold += _count(symbols, SymbolTable.RECYCLER) * junk \
			* SymbolTable.RECYCLER_GOLD_PER_JUNK
		result.attack_penalty += _count(symbols, SymbolTable.MARKED_CARD) \
			* SymbolTable.MARKED_CARD_ATTACK_PENALTY

	if result.gold > 0:
		Global.player.gold += result.gold
	if result.damage > 0:
		Global.player.take_true_damage(result.damage)
	return result
