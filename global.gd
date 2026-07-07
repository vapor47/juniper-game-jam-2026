extends Node

var player: PlayerData
var slot_symbols: Dictionary[String, SlotSymbol] = {}
var reels: Dictionary[String, Reel] = {}
var reel_inventory: Dictionary[String, int] = {
	"Attack": 3,
	"Defend": 3
}

# Animations
const SLOT_SPIN_DURATION: float = 1.0
const SLOT_SPIN_INTERVAL: float = 0.01
const SLOT_REVEAL_STAGGER: float = 0.33


func _ready() -> void:
	player = PlayerData.new()
	_load_symbols("res://slot_symbols/symbols/")
	_load_reels()

func _load_symbols(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			_load_symbols(path + file_name + "/")  # recurse
		elif file_name.ends_with(".gd"):
			var script = load(path + file_name) as GDScript
			var instance = script.new()
			if instance is SlotSymbol:
				slot_symbols[instance.symbol_name] = instance
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _load_reels() -> void:
	reels = {
		"Attack": AttackReel.new(),
		"Defend": DefendReel.new(),
	}
