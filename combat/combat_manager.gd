extends Node

enum Turn { PLAYER, ENEMY }
enum CombatState { INACTIVE, PLAYER_TURN, ENEMY_TURN, ENDED }

var state: CombatState = CombatState.INACTIVE
var current_turn: Turn = Turn.PLAYER
var enemies: Array[EnemyData] = []

const EnemyScene = preload("res://combat/enemies/enemy.tscn")
const FLOATING_TEXT_SCENE = preload("res://floating_text.tscn")
const gambler = preload("res://combat/enemies/destitute_gambler.tres")

var has_player_spun: bool = false:
	set(value):
		if has_player_spun != value:
			EventBus.spin_lock_toggled.emit()
		has_player_spun = value
		
var respin_tokens: int = 3:
	set(value):
		respin_tokens = value
		EventBus.respin_count_updated.emit()
#Testing
func spawn_popup(text: String) -> void:
	var popup = FLOATING_TEXT_SCENE.instantiate()
	popup.text = text
	
	var screen_center = get_viewport().get_visible_rect().size / 2
	
	# Assign position (and adjust for label size so it centers perfectly)
	popup.global_position = screen_center - (popup.size / 2)
	
	# Add it to the scene tree so it renders
	add_child(popup)
	
func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.slots_locked_in.connect(_on_spin_resolved)
	EventBus.lever_pulled.connect(_on_lever_pulled)
	
	print("About to instantiate EnemyUI")
	var dummy = EnemyScene.instantiate()
	dummy.enemy_data = gambler
	var current_scene = get_tree().current_scene.get_child(0)
	current_scene.add_child(dummy)
	current_scene.move_child(dummy, 0)
	
	start_combat(Global.player, [dummy.enemy_data])

func _on_entity_died(who) -> void:
	print_debug("Entity died")
	if who == Global.player:
		state = CombatState.ENDED
		EventBus.combat_ended.emit("lose")
		#spawn_popup("THE HOUSE ALWAYS WINS")
	else:
		enemies.erase(who)
		if enemies.is_empty():
			state = CombatState.ENDED
			EventBus.combat_ended.emit("win")
			spawn_popup("YOU WIN!!!")

func start_combat(p: PlayerData, e: Array[EnemyData]) -> void:
	print_debug("Combat started!")
	Global.player = p
	enemies = e
	state = CombatState.PLAYER_TURN
	_start_player_turn()

func _start_player_turn() -> void:
	_reset_player_turn_state()
	state = CombatState.PLAYER_TURN
	EventBus.turn_started.emit(Turn.PLAYER)

func _end_player_turn() -> void:
	state = CombatState.ENEMY_TURN
	EventBus.turn_ended.emit(Turn.PLAYER)
	_start_enemy_turn()
	
func _reset_player_turn_state() -> void:
	has_player_spun = false

func _on_spin_resolved(stops: Array[ReelStop]) -> void:
	var effects = SymbolResolver.resolve(stops)
	for effect in effects:
		_apply_effect(effect)
		
	spawn_popup(effects[0].type + ": " + str(effects[0].value) + "\n" + effects[1].type + ": " + str(effects[1].value))
	_end_player_turn()
	
func _apply_effect(effect: Dictionary) -> void:
	match effect.type:
		"damage":
			for enemy: EnemyData in enemies:
				enemy.take_damage(effect.value)
				print_debug("Dealt " + str(effect.value) + " damage!")
		"block":
			Global.player.add_block(effect.value)
		"heal":
			Global.player.heal(effect.value)

func _on_lever_pulled():
	has_player_spun = true
# Enemy
func _start_enemy_turn() -> void:
	EventBus.turn_started.emit(Turn.ENEMY)
	for enemy in enemies:
		if is_instance_valid(enemy):
			await enemy.make_move()
	if state != CombatState.ENDED:
		_start_player_turn()
