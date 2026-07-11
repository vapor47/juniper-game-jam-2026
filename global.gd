extends Node

var player: PlayerData
var slot_symbols: Dictionary[String, SlotSymbol] = {}
var reels: Dictionary[String, Reel] = {}
var reel_inventory: Dictionary[String, int] = {
	"Attack": 3,
	"Defend": 3,
	"Heal": 3,
}

# Animations
const SLOT_SPIN_DURATION: float = 1.0
const SLOT_SPIN_INTERVAL: float = 0.01
const SLOT_REVEAL_STAGGER: float = 0.33

# Required for Web export
const SYMBOL_SCRIPTS := [
	preload("res://slot_symbols/symbols/attack/light_attack.gd"),
	preload("res://slot_symbols/symbols/attack/medium_attack.gd"),
	preload("res://slot_symbols/symbols/attack/heavy_attack.gd"),
	preload("res://slot_symbols/symbols/attack/multiply_attack.gd"),
	preload("res://slot_symbols/symbols/defend/light_defend.gd"),
	preload("res://slot_symbols/symbols/defend/medium_defend.gd"),
	preload("res://slot_symbols/symbols/defend/heavy_defend.gd"),
	preload("res://slot_symbols/symbols/defend/multiply_defend.gd"),
	preload("res://slot_symbols/symbols/heal/light_heal.gd"),
	preload("res://slot_symbols/symbols/heal/medium_heal.gd"),
	preload("res://slot_symbols/symbols/heal/heavy_heal.gd"),
	preload("res://slot_symbols/symbols/heal/multiply_heal.gd"),
]


func _ready() -> void:
	player = PlayerData.new()
	_load_symbols()
	_load_reels()

func _load_symbols() -> void:
	if OS.has_feature("web"):
		_load_symbols_web()
	else:
		_load_symbols_dynamic("res://slot_symbols/symbols/")

func _load_symbols_web() -> void:
	for script: GDScript in SYMBOL_SCRIPTS:
		var instance = script.new()
		slot_symbols[instance.symbol_name] = instance
	
func _load_symbols_dynamic(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			_load_symbols_dynamic(path + file_name + "/")  # recurse
		elif file_name.ends_with(".gd"):
			var script := load(path + file_name) as GDScript
			var instance = script.new()
			if instance is SlotSymbol:
				slot_symbols[instance.symbol_name] = instance
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _load_reels() -> void:
	reels = {
		"Attack": AttackReel.new(),
		"Defend": DefendReel.new(),
		"Heal": HealReel.new(),
	}
