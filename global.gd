extends Node

var player: PlayerData

## The single shared master reel strip (§2/§3). Every ReelColumn's Reel points
## at this same array (GDScript arrays are reference types), so shop edits
## (Phase 4) are visible to all 5 columns immediately.
var strip: Array[Stop] = []

# Animations
const SLOT_SPIN_DURATION: float = 1.0
const SLOT_SPIN_INTERVAL: float = 0.01
const SLOT_REVEAL_STAGGER: float = 0.33


func reset() -> void:
	player = PlayerData.new()
	_load_strip()


func _ready() -> void:
	player = PlayerData.new()
	_load_strip()

func _load_strip() -> void:
	strip = []
	for symbol: Symbol in SymbolTable.build_default_strip():
		strip.append(Stop.new(symbol))
