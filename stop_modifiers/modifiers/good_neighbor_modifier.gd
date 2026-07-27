# good_neighbor_modifier.gd
extends StopModifier
class_name GoodNeighborModifier

func _init() -> void:
	display_name = "Good Neighbor"
	description = "+4 if a stop beside it on the line shares this symbol"

## Adjacent on the payline, not on the strip. Strip adjacency made this a flat
## permanent bonus you could engineer once in the editor and never think about
## again; on the line it has to actually land next to its twin.
func modify_stop_value(base_value: int, ctx: ResolutionContext, stop: Stop) -> int:
	for neighbor in ctx.get_line_neighbors(stop):
		if neighbor.symbol == stop.symbol:
			return base_value + 4
	return base_value
