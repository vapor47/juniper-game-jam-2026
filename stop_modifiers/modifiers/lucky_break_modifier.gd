# lucky_break_modifier.gd
extends StopModifier
class_name LuckyBreakModifier
## Turns the board's dead cells into value on one stop.
##
## Built as a modifier rather than a symbol on purpose: its value depends on
## board state, and the paytable renders symbol rows from a static value. A
## symbol whose worth changed every spin would print a number the machine then
## disagreed with. Modifiers are already allowed to vary per spin (Beginner's
## Luck does), and the paytable does not render them, so there is nothing to
## lie about.

const PER_BLANK := 2

func _init() -> void:
	display_name = "Lucky Break"
	description = "+%d for each blank on the board" % PER_BLANK

## Blank has no value of its own, so it can never carry this.
func can_apply(stop: Stop) -> bool:
	return stop.symbol != SymbolTable.BLANK and stop.symbol.value > 0

func modify_stop_value(base_value: int, ctx: ResolutionContext, _stop: Stop) -> int:
	return base_value + PER_BLANK * ctx.blank_count()
