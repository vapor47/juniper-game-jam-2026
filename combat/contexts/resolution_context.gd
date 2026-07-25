extends RefCounted
class_name ResolutionContext
## Snapshot of turn state handed to every modifier hook.
## Build one per resolution in CombatManager; modifiers only READ from it
## (except documented side-effect hooks D/E, which act via player/enemy refs).
##
## Phase 1 (§13) doesn't invoke StopModifier/RunEffect hooks yet — PaylineScorer
## scores directly off the payline's Stops. This class stays here, compiling
## and shaped correctly, so Phase 2+ can wire the hooks back in without
## re-deriving this shape.

var player: PlayerData
var enemies: Array[EnemyData]


var is_initial_spin: bool = true        # false once any respin has happened this turn

var turn: TurnContext

var actions: Array[Action]

var selected_stops: Array[Stop] = []
var selected_count: int = 0

## combo info, populated mid-resolution so HOOK B/D can read it
var combo_symbols: Array[Symbol] = []   # symbols that comboed this resolution


static func build(p_player: PlayerData, p_enemies: Array[EnemyData],
		p_is_initial_spin: bool, p_selected_stops: Array[Stop], turn_context) -> ResolutionContext:
	var ctx := ResolutionContext.new()
	ctx.player = p_player
	ctx.enemies = p_enemies
	ctx.is_initial_spin = p_is_initial_spin
	ctx.turn = turn_context
	ctx.selected_stops = p_selected_stops
	ctx.selected_count = p_selected_stops.size()
	return ctx

func is_stop_in_combo(stop: Stop) -> bool:
	return stop.symbol in combo_symbols


func get_adjacent_stops(stop: Stop) -> Array[Stop]:
	var i := Global.strip.find(stop)
	if i == -1 or Global.strip.size() < 2:
		return []
	var out: Array[Stop] = []
	out.append(Global.strip[wrapi(i - 1, 0, Global.strip.size())])
	out.append(Global.strip[wrapi(i + 1, 0, Global.strip.size())])
	return out
