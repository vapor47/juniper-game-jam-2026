extends RefCounted
class_name ResolutionContext
## Snapshot of turn state handed to every modifier hook.
## Build one per resolution in CombatManager; modifiers only READ from it
## (except documented side-effect hooks D/E, which act via player/enemy refs).

var player: PlayerData
var enemies: Array[EnemyData]


var is_initial_spin: bool = true        # false once any respin has happened this turn

var turn: TurnContext

var actions: Array[Action]

var selected_stops: Array[ReelStop] = []
var selected_count: int = 0

## reel geometry lookups, populated per selected slot: stop -> its Reel
var stop_to_reel: Dictionary = {}

## combo info, populated by SymbolResolver mid-resolution so HOOK B/D can read it
var combo_symbols: Array[SlotSymbol] = []   # symbols that comboed this resolution


static func build(p_player: PlayerData, p_enemies: Array[EnemyData],
		p_is_initial_spin: bool, p_selected_slots: Dictionary[Slot, bool]) -> ResolutionContext:
	var ctx := ResolutionContext.new()
	ctx.player = p_player
	ctx.enemies = p_enemies
	ctx.is_initial_spin = p_is_initial_spin
	for slot: Slot in p_selected_slots:
		var stop := slot.get_curr_stop()
		ctx.selected_stops.append(stop)
		ctx.stop_to_reel[stop] = slot.slot_reel
	ctx.selected_count = ctx.selected_stops.size()
	return ctx

func is_stop_in_combo(stop: ReelStop) -> bool:
	return stop.slot_symbol in combo_symbols


func get_adjacent_stops(stop: ReelStop) -> Array[ReelStop]:
	var reel: Reel = stop_to_reel.get(stop)
	if reel == null:
		return []
	var i := reel.reel_stops.find(stop)
	if i == -1 or reel.stops.size() < 2:
		return []
	var out: Array[ReelStop] = []
	out.append(reel.stops[(i - 1 + reel.stops.size()) % reel.stops.size()])
	out.append(reel.stops[(i + 1) % reel.stops.size()])
	return out
