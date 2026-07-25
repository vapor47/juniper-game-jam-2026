extends RefCounted
class_name StripAnalysis
## §6: placement position matters, and it's invisible without UI support.
##
## A column shows 3 adjacent stops, so every insertion edits the adjacency
## graph — which symbols can co-occur in one column window. And because a
## payline takes one cell per column, two copies inside the same window can
## never both score on a line: duplicates want to be *spread*, not clustered.
##
## The doc's own worked example: two Heavy Atks at stops 10 and 11 occupy 4 of
## 20 windows; the same two at 10 and 1 occupy 6 of 20 — 50% better for the
## same stop count. `windows_covered` is exactly that number.


## The 3 stops visible when the reel rests at `index`.
static func window_at(strip: Array[Stop], index: int) -> Array[Stop]:
	var out: Array[Stop] = []
	for row in range(-1, 2):
		out.append(strip[wrapi(index + row, 0, strip.size())])
	return out


## How many of the strip's N windows contain at least one copy of `symbol`.
## Higher is better: it's how often the symbol is actually on the board.
static func windows_covered(strip: Array[Stop], symbol: Symbol) -> int:
	var covered := 0
	for i in strip.size():
		for stop: Stop in window_at(strip, i):
			if stop.symbol == symbol:
				covered += 1
				break
	return covered


static func count_of(strip: Array[Stop], symbol: Symbol) -> int:
	var n := 0
	for stop: Stop in strip:
		if stop.symbol == symbol:
			n += 1
	return n


## Probability a specific stop is somewhere on the board in a given spin:
## 1 - (1 - 3/N)^5. Shortening the strip raises this for everything left,
## which is why removal is the strongest verb (§6).
static func on_board_chance(strip_size: int) -> float:
	if strip_size <= 0:
		return 0.0
	return 1.0 - pow(1.0 - 3.0 / float(strip_size), 5.0)


## Result of a hypothetical edit, for previewing before committing.
static func preview_replace(strip: Array[Stop], index: int, symbol: Symbol) -> Array[Stop]:
	var copy := strip.duplicate()
	copy[index] = Stop.new(symbol)
	return copy


static func preview_insert(strip: Array[Stop], index: int, symbol: Symbol) -> Array[Stop]:
	var copy := strip.duplicate()
	copy.insert(index, Stop.new(symbol))
	return copy


static func preview_remove(strip: Array[Stop], index: int) -> Array[Stop]:
	var copy := strip.duplicate()
	copy.remove_at(index)
	return copy
