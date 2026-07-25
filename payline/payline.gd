extends RefCounted
class_name Payline
## A line shape: one cell per column, left to right (§4). Always 5 cells,
## always 4 adjacent pairs, regardless of shape.

var display_name: String
## One Row value (Row.TOP / CENTER / BOTTOM) per column.
var pattern: Array[int] = []


func _init(p_display_name: String = "", p_pattern: Array[int] = []) -> void:
	display_name = p_display_name
	pattern = p_pattern


func row_at(column: int) -> int:
	return pattern[column]


## How many cells this line shares with another — the concentrate-vs-spread
## axis (§4). Surfaced in the UI so the choice is legible.
func overlap_with(other: Payline) -> int:
	var shared := 0
	for col in mini(pattern.size(), other.pattern.size()):
		if pattern[col] == other.pattern[col]:
			shared += 1
	return shared
