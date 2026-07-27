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

## Every symbol visible across all 15 cells. Effects that read the whole board
## rather than one line need it, and previews need it too, or a hover would
## disagree with what locking in actually pays.
var board_symbols: Array[Symbol] = []

## The line currently being scored, in column order. Set by PaylineScorer at
## the top of score_line, because one context is shared across every line of a
## resolution and "adjacent" has to mean adjacent *on this line*.
var line_stops: Array[Stop] = []

## combo info, populated mid-resolution so HOOK B/D can read it
var combo_symbols: Array[Symbol] = []   # symbols that comboed this resolution


## A throwaway context for hover previews. Modifier hooks need one to read
## from, but a preview has no turn behind it — so this carries just enough for
## them to answer, and nothing that would let a preview change game state.
static func preview(p_stops: Array[Stop] = [],
		p_board: Array[Symbol] = []) -> ResolutionContext:
	var ctx := ResolutionContext.new()
	ctx.player = Global.player
	ctx.board_symbols = p_board
	ctx.selected_stops = p_stops
	ctx.selected_count = p_stops.size()
	ctx.is_initial_spin = false
	return ctx


static func build(p_player: PlayerData, p_enemies: Array[EnemyData],
		p_is_initial_spin: bool, p_selected_stops: Array[Stop], turn_context,
		p_board: Array[Symbol] = []) -> ResolutionContext:
	var ctx := ResolutionContext.new()
	ctx.board_symbols = p_board
	ctx.player = p_player
	ctx.enemies = p_enemies
	ctx.is_initial_spin = p_is_initial_spin
	ctx.turn = turn_context
	ctx.selected_stops = p_selected_stops
	ctx.selected_count = p_selected_stops.size()
	return ctx

## How many cells on the board are junk — Blank and every curse. The
## junk-synergy effects all key off this, so it lives here rather than being
## recounted by each of them.
func junk_count() -> int:
	return BoardEffects.count_junk(board_symbols)


func is_stop_in_combo(stop: Stop) -> bool:
	return stop.symbol in combo_symbols


## Neighbours of `stop` along the line being scored — the cells either side of
## it on the payline path, not on the strip. A payline is a path, not a loop,
## so the ends have one neighbour each.
##
## The same Stop can occupy more than one column, since all five columns are
## windows into one shared strip, so every occurrence contributes its own
## neighbours.
func get_line_neighbors(stop: Stop) -> Array[Stop]:
	var out: Array[Stop] = []
	for i in line_stops.size():
		if line_stops[i] != stop:
			continue
		if i > 0:
			out.append(line_stops[i - 1])
		if i + 1 < line_stops.size():
			out.append(line_stops[i + 1])
	return out
