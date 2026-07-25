# good_neighbor_modifier.gd
extends StopModifier
class_name GoodNeighborModifier

func _init() -> void:
	display_name = "Good Neighbor"
	description = "+4 if an adjacent stop shares this symbol"

func modify_stop_value(base_value: int, ctx: ResolutionContext, stop: Stop) -> int:
	for neighbor in ctx.get_adjacent_stops(stop):
		if neighbor.symbol == stop.symbol:
			return base_value + 4
	return base_value
