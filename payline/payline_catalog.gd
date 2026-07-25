extends RefCounted
class_name PaylineCatalog
## §4: 12 curated, visually distinct patterns out of the 243 possible.
##
## In isolation every pattern is statistically identical — each has the same
## marginal distribution and 4 adjacent pairs. The choice only means something
## *relative to lines already owned*, so the pool deliberately spans the
## concentrate-vs-spread axis against a starting Center Line:
##   - never touch center (pure spread):  Top, Bottom, Zigzag, Zagzig
##   - touch center at the edges (mixed): Big V, Big Peak, Smile, Frown
##   - ride center heavily (concentrate): Pulse, Cascade, Rally

const T := Row.TOP
const C := Row.CENTER
const B := Row.BOTTOM

static var CENTER_LINE := Payline.new("Center Line", [C, C, C, C, C] as Array[int])
static var TOP_LINE := Payline.new("Top Line", [T, T, T, T, T] as Array[int])
static var BOTTOM_LINE := Payline.new("Bottom Line", [B, B, B, B, B] as Array[int])
static var BIG_V := Payline.new("Big V", [T, C, B, C, T] as Array[int])
static var BIG_PEAK := Payline.new("Big Peak", [B, C, T, C, B] as Array[int])
static var ZIGZAG := Payline.new("Zigzag", [T, B, T, B, T] as Array[int])
static var ZAGZIG := Payline.new("Zagzig", [B, T, B, T, B] as Array[int])
static var CASCADE := Payline.new("Cascade", [T, T, C, B, B] as Array[int])
static var RALLY := Payline.new("Rally", [B, B, C, T, T] as Array[int])
static var SMILE := Payline.new("Smile", [C, B, B, B, C] as Array[int])
static var FROWN := Payline.new("Frown", [C, T, T, T, C] as Array[int])
static var PULSE := Payline.new("Pulse", [C, T, C, B, C] as Array[int])


## What a run opens with. §4 specifies center-only; the three straights are
## owned from the start so the selection layer has something to compare
## against before any rewards land.
static func starting_paylines() -> Array[Payline]:
	return [CENTER_LINE, TOP_LINE, BOTTOM_LINE]


static func all() -> Array[Payline]:
	return [
		CENTER_LINE, TOP_LINE, BOTTOM_LINE, BIG_V, BIG_PEAK, ZIGZAG,
		ZAGZIG, CASCADE, RALLY, SMILE, FROWN, PULSE,
	]


## Patterns the player doesn't already own, for reward/acquisition offers.
static func acquirable(owned: Array[Payline]) -> Array[Payline]:
	return all().filter(func(p: Payline) -> bool: return p not in owned)


## Listing order for the selection panel: highest line on the board first, so
## the three straights read top / center / bottom the way they sit on the grid.
## Inventory order stays acquisition order — this is presentation only.
static func sorted_for_display(lines: Array[Payline]) -> Array[Payline]:
	var catalog := all()
	var out := lines.duplicate()
	out.sort_custom(func(a: Payline, b: Payline) -> bool:
		var height_a := _height_key(a)
		var height_b := _height_key(b)
		if not is_equal_approx(height_a, height_b):
			return height_a < height_b
		return catalog.find(a) < catalog.find(b))
	return out


## Mean row of the pattern. Row.TOP is 0 and Row.BOTTOM is 2, so a smaller
## key means the line sits higher on the board.
static func _height_key(payline: Payline) -> float:
	if payline.pattern.is_empty():
		return 0.0
	var total := 0
	for row: int in payline.pattern:
		total += row
	return float(total) / float(payline.pattern.size())
