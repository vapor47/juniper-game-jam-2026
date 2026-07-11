extends Control
class_name CombatScene

@onready var side_panel: PanelContainer = %ReelInventorySidePanel
#@onready var toggle_btn: Button = $ToggleButton
const DEATH_SCREEN_SCENE = preload("res://screens/death_screen.tscn")
const BATTLE_VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")
const COMBAT_REWARD_SCREEN_SCENE = preload("res://screens/combat_reward/combat_reward_screen.tscn")

var curr_swap_cost: int = 0

# Close side panel if click is unhandled
func _unhandled_input(event: InputEvent) -> void:
	if not side_panel.is_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if not side_panel.get_global_rect().has_point(event.position):
			side_panel.close()


func _on_item_pressed(item_data: Dictionary) -> void:
	print("Item pressed: ", item_data)
	# Handle action here

func _get_reel_inventory_data() -> Array:
	return Global.reels.keys().map(func(reel_name: String): return {
		"reel_name": reel_name,
		"reel": Global.reels[reel_name],
		"amount": Global.reel_inventory[reel_name],
	})
	
	
 # --------- Combat Migration ---------- #
signal player_turn_started
signal enemy_turn_started

enum CombatResult { LOSS, VICTORY }
#enum CombatState { INACTIVE, PLAYER_TURN, ENEMY_TURN, ENDED }
#
#var combat_state: CombatState = CombatState.INACTIVE
var enemies: Array[EnemyData]
# From this array of enemy data, we instantiate the enemies, and enemyUI scenes
const ENEMY_SCENE = preload("res://combat/enemies/enemy.tscn")
var initial_spin_completed: bool = false:
	set(new_value):
		#if initial_spin_completed != new_value:
			#EventBus.spin_lock_toggled.emit()
		initial_spin_completed = new_value


func setup(e: Array[EnemyData]) -> void:
	enemies = e
	for enemy in enemies:
		enemy.died.connect(_on_entity_died)
	Global.player.died.connect(_on_entity_died)
		

func _init_enemies() -> void:
	var enemy_container := %EnemyContainer
	for enemy_data in enemies:
		var enemy_ui: EnemyUI = ENEMY_SCENE.instantiate()
		enemy_ui.enemy_data = enemy_data
		enemy_container.add_child(enemy_ui)

func _ready() -> void:
	set_process_unhandled_input(true)
	
#	TODO: This should eventually be moved out once a Mainscreen is implemented
# 	Mainly for testing purposes. I think. idr at the time of writing this comment.
	setup(RunManager.get_next_encounter())
	
	side_panel.populate(_get_reel_inventory_data())
	EventBus.reel_swapped.connect(func(_reel: Reel) -> void: side_panel.populate(_get_reel_inventory_data()))
	EventBus.lever_pulled.connect(func() -> void: initial_spin_completed = true)
	EventBus.slots_locked_in.connect(_on_spin_resolved)
	
	# Insert starting reels
	
	_init_enemies()
	_start_combat()
		
func _start_combat() -> void:
#	(Actually this should be handled by enemy itself): Get initial enemy intent 

#	Perform any pre-combat setup (token replenishing, etc)
	_start_player_turn()
	pass
	
func _start_player_turn() -> void:
	player_turn_started.emit()
	initial_spin_completed = false
	curr_swap_cost = 0

# To be called once the player hits the lock in button
func _end_player_turn() -> void:
#	Disable slot machine controls
	_start_enemy_turn()
	
func _start_enemy_turn() -> void:
	enemy_turn_started.emit()
	#EventBus.turn_started.emit(Turn.ENEMY)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.make_move()
	#if combat_state != CombatState.ENDED:
	
	_start_player_turn()
	
func _end_enemy_turn() -> void:
	_start_player_turn()
	
func _end_combat(result: CombatResult) -> void:
	if result == CombatResult.VICTORY:
		#add_child(BATTLE_VICTORY_SCREEN_SCENE.instantiate())
		_show_post_combat()
	else:
		add_child(DEATH_SCREEN_SCENE.instantiate())
	
func _show_post_combat() -> void:
	add_child(COMBAT_REWARD_SCREEN_SCENE.instantiate())

	
func _continue() -> void:
#	Signal to sceneManager to move to next combat (for now)
	pass
	
func _on_entity_died(who: CombatantData) -> void:
	if who == Global.player:
		_end_combat(CombatResult.LOSS)
	else:
		enemies.erase(who)
		if enemies.is_empty():
			_end_combat(CombatResult.VICTORY)
	
	
func _on_spin_resolved(stops: Array[ReelStop]) -> void:
	var effects: Array = SymbolResolver.resolve(stops)
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

const FLOATING_TEXT_SCENE = preload("res://floating_text.tscn")

#Testing
func spawn_popup(text: String) -> void:
	var popup := FLOATING_TEXT_SCENE.instantiate()
	popup.text = text
	
	var screen_center := get_viewport().get_visible_rect().size / 2
	
	# Assign position (and adjust for label size so it centers perfectly)
	popup.global_position = screen_center - (popup.size / 2)
	
	# Add it to the scene tree so it renders
	add_child(popup)


############ COMBAT MIGRATION ################
"""
User swaps slot reels
User spins all reels
User can choose up to 3 of 5 reel outcomes at part of their turn

They can increase their number of slots, and number of active choice slots separately
User could be incentivized to just increase options, for more information
	and better odds for what they want
	
I think with this, we remove the mechanic of swapping reels mid turn?
Well what would it look like if it remained?


Yeah no it should go.
Perhapssss along individual respins? I think the idea of locking slots in place and only having the option to spin all unlocked is more interesting
"""
"""
- Player freely swaps reels in their slots with their desired reels
- Player then spins all reels via lever
- Player must choose X of N slots from which their symbols comprise the player’s action.
- Before confirming, player may choose to lock in the result of certain slots, and then re-spin all non-locked slots. (Costing some amount of something, tokens or otherwise)
- Repeat this locking / re-spin phase. (Decide whether or not player should be able to unlock already locked slots. I feel like it’s more interesting to not allow)
- User finally confirms their X chosen slots, and the player actions are calculated and resolved.
"""
var num_selected_slots: int = 0:
	set(new_val):
		num_selected_slots = new_val
		#if num_selected_slots == num_active_slots:
			#emit signal to enable confirm button

# SWAP for reel swapping phase
# SELECT for slot selection phase
# NONE otherwise (enemy turn, etc.)
enum SlotPressAction { SWAP, SELECT, NONE }
var curr_slot_press_action: SlotPressAction = SlotPressAction.NONE:
	set(new_val):
		curr_slot_press_action = new_val
		match new_val:
			SlotPressAction.SWAP:
				# Set Slot press action to reel swap
				pass
			SlotPressAction.SELECT:
				# Set Slot press action to select
				pass
			SlotPressAction.NONE:
				# Disable Slot press action
				pass

func _rrready() -> void:
	EventBus.lever_pulled.connect(_begin_slot_select_phase)
	EventBus.slot_selection_confirmed.connect(_end_slot_select_phase)


func _begin_player_turn() -> void:
	_reset_player_turn_values()
	_begin_swap_phase()

func _reset_player_turn_values() -> void:
	num_selected_slots = 0


func _begin_swap_phase() -> void:
#	Allow swapping
	pass


func _end_swap_phase() -> void:
#	Disable swapping (potentially change what action clicking on slot performs)
	pass

#on first spin emit
#func _begin_phase
#choose / lock / respin
func _begin_slot_select_phase() -> void:
	"""
	Repeatable phase; Called either by self or lever_pulled signal.
		Actually dont even need self. Can only be lever pulled!
	Player can either lock certain slot results and spin again
		or they can finalize their selected slots
	Ends when player either spins lever again, or finalizes selection
	If lever, repeat phase
	else continue
	"""
	
	pass


func _end_slot_select_phase() -> void:
#	Disable confirm button
	_begin_action_resolution_phase()


func _begin_action_resolution_phase() -> void:
	"""
	Calculate result of player's finalized symbols and
		perform actions
	"""
	var symbols: Array[SlotSymbol] = _get_selected_symbols()
	#TODO define Action class
	var actions: ActionResults = _calculate_action_results(symbols)
	_perform_actions(actions)
	_end_player_turn()

func _get_selected_symbols() -> Array[SlotSymbol]:
	pass
class ActionResults:
	pass
#TODO define ActionResults
func _calculate_action_results(symbols: Array[SlotSymbol]) -> ActionResults:
	pass
	
func _perform_actions(actions: ActionResults) -> void:
	pass


func _endddddd_player_turn() -> void:
	pass

"""
that could be funny, if the lock-in/confirm button just changed text all the time
to random phrases of agreement / confirmatino
just thought of this because im struggling what to call it.
lock in button is a little confusing with the slot lock button
can also call locked slots frozen. nah i like locked.
lets just call it the confirm button in the backend. This is very clear on what it is

LOCK IN
CONFIRM
YES
OH YES
YOU BET!
THIS IS THE ONE!
I LOVE IT
OH YEAH
OH MY HEAVENS YES
SURE
GOOD ENOUGH
THUMBS UP EMOJI
CHECKMARK

"""
