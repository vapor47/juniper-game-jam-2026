extends Node

var player: PlayerData

## The single shared master reel strip (§2/§3). Every ReelColumn's Reel points
## at this same array (GDScript arrays are reference types), so shop edits
## (Phase 4) are visible to all 5 columns immediately.
var strip: Array[Stop] = []

## Flat amount taken off every scoring action, set by enemies that rake the pot
## (§ The Rake). Combat-scoped: cleared when a fight starts so it can never leak
## into the next one. Global rather than passed around because the paytable and
## every hover preview have to agree with resolution about what an action pays,
## and they build their own contexts.
var action_cut: int = 0

# Animations
const SLOT_SPIN_DURATION: float = 1.0
const SLOT_SPIN_INTERVAL: float = 0.01
const SLOT_REVEAL_STAGGER: float = 0.33


func reset() -> void:
	player = PlayerData.new()
	action_cut = 0
	_load_strip()


func _ready() -> void:
	player = PlayerData.new()
	_load_strip()

## Decides every Mystery stop for the coming spin. Called once per spin rather
## than per read: resolving lazily would give a different answer to the hover
## preview than to the resolution that follows it.
##
## Not called on a nudge. A nudge moves the window over stops the spin already
## decided; rerolling them would mean nudging one column silently changed the
## symbols in another.
func reroll_mysteries() -> void:
	for stop: Stop in strip:
		stop.reroll()


func _load_strip() -> void:
	strip = []
	for symbol: Symbol in SymbolTable.build_default_strip():
		strip.append(Stop.new(symbol))
