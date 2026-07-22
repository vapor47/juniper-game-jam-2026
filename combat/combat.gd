extends Control
class_name CombatManager

@onready var side_panel: SidePanel = %ReelInventorySidePanel
#@onready var toggle_btn: Button = $ToggleButton
const DEATH_SCREEN_SCENE = preload("res://screens/death_screen.tscn")
const BATTLE_VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")
const COMBAT_REWARD_SCREEN_SCENE = preload("res://screens/combat_reward/combat_reward_screen.tscn")
const FLOATING_TEXT_SCENE = preload("res://floating_text.tscn")

var curr_swap_cost: int = 0

# Close side panel if click is unhandled
func _unhandled_input(event: InputEvent) -> void:
	if not side_panel.is_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if not side_panel.get_global_rect().has_point(event.position):
			side_panel.close()
			slot_to_swap = null
			


func _on_item_pressed(item_data: Dictionary) -> void:
	print("Item pressed: ", item_data)
	# Handle action here

func _get_reel_inventory_data() -> Array:
	return Global.reels.keys().map(func(reel_name: String): return {
		"reel_name": reel_name,
		"reel": Global.reels[reel_name],
		"amount": Global.player.get_reel_inventory()[reel_name],
	})
	
	
 # --------- Combat Migration ---------- #
signal player_turn_started
signal enemy_turn_started

enum CombatResult { LOSS, VICTORY }
#enum CombatState { INACTIVE, PLAYER_TURN, ENEMY_TURN, ENDED }

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
	# TODO: dedupe
	context = CombatContext.new()
	context.enemies = e
	enemies = e
	for enemy in enemies:
		enemy.died.connect(_on_entity_died)
		player_turn_started.connect(enemy._choose_intent)
	Global.player.died.connect(_on_entity_died)
		

func _init_enemies() -> void:
	var enemy_container := %EnemyContainer
	for enemy_data in enemies:
		var enemy_ui: EnemyUI = ENEMY_SCENE.instantiate()
		enemy_ui.enemy_data = enemy_data
		enemy_container.add_child(enemy_ui)

func _on_entity_died(who: CombatantData) -> void:
	if who == Global.player:
		_end_combat(CombatResult.LOSS)
	else:
		enemies.erase(who)
		if enemies.is_empty():
			_end_combat(CombatResult.VICTORY)
	

#Testing
func spawn_popup(text: String) -> void:
	var popup := FLOATING_TEXT_SCENE.instantiate()
	popup.text = text
	add_child(popup)
	
	await get_tree().process_frame
	
	var screen_center := get_viewport().get_visible_rect().size / 2
	
	# Assign position (and adjust for label size so it centers perfectly)
	popup.global_position = screen_center - (popup.size / 2)
	
	# Add it to the scene tree so it renders


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
@onready var slot_machine: SlotMachine = %SlotMachine

const LOADOUT_SELECTION_MODAL = preload("res://combat/loadout/loadout_selection.tscn")

var context: CombatContext
var turn_context: TurnContext

var max_active_slots: int = 3
var selected_slots: Dictionary[Slot, bool] = {}:
	set(new_val):
		selected_slots = new_val
		#if len(selected_slots) == num_active_slots:
			#emit signal to enable confirm button

# SWAP for reel swapping phase
# SELECT for slot selection phase
# NONE otherwise (enemy turn, etc.)
enum SlotPressAction { SWAP, SELECT, NONE }
var curr_slot_press_action: SlotPressAction = SlotPressAction.NONE:
	set(new_val):
		if new_val == curr_slot_press_action:
			return
		curr_slot_press_action = new_val
		#slot_machine.phase_label
		match new_val:
			SlotPressAction.SWAP:
				# Set Slot press action to reel swap
				print_debug("Switching slot press to reel swap mode.")
				slot_machine.phase_label.text = "PREPARE — Swap reels, then pull the lever when ready"
				pass
			SlotPressAction.SELECT:
				print_debug("Switching slot press to slot select mode.")
				slot_machine.phase_label.text = "SELECT — Hold desired slots & respin the rest • Choose %d results • LOCK IT IN" % max_active_slots
				# Set Slot press action to select
				pass
			SlotPressAction.NONE:
				# Disable Slot press action
				print_debug("Disabling slot press.")
				slot_machine.phase_label.text = ""
				pass

var slot_to_swap: Slot = null:
	set(new_val):
		if not new_val or new_val == slot_to_swap:
			if slot_to_swap:
				slot_to_swap.unselect()
				slot_to_swap = null
				side_panel.close()
		else:
			if slot_to_swap:
				slot_to_swap.unselect()
			slot_to_swap = new_val
			new_val.select()

func _on_side_panel_closed() -> void:
	#slot_to_swap = null
	pass

func _ready() -> void:
	EventBus.lever_pulled.connect(_end_swap_phase)
	#EventBus.lever_pulled.connect(_begin_slot_select_phase)
	EventBus.slot_selection_confirmed.connect(_end_slot_select_phase)
	EventBus.inventory_reel_pressed.connect(_on_inventory_reel_pressed)
	EventBus.slot_selected.connect(_on_slot_pressed)
	EventBus.side_panel_closed.connect(_on_side_panel_closed)
	EventBus.spin_all_completed.connect(_on_spin_all_completed)
	
#	TODO: implement (maybe?)
	#EventBus.reel_swaps_completed.connect(_end_swap_phase)
	
	### Existing code
	set_process_unhandled_input(true)
	
	_init_enemies()
	_begin_combat()

func _begin_combat() -> void:
	curr_slot_press_action = SlotPressAction.NONE
	Global.player.replenish_tokens()
	context.player = Global.player
	
	_open_loadout_selection_modal()
	Global.player.broadcast("on_combat_started", [context])
	_begin_player_turn()

func _open_loadout_selection_modal() -> void:
	var modal: LoadoutSelection = LOADOUT_SELECTION_MODAL.instantiate()
	modal.loadout_confirmed.connect(_on_loadout_confirmed.bind(modal))
	add_child(modal)

func _on_loadout_confirmed(reels: Array[Reel], modal: LoadoutSelection) -> void:
	if reels.size() > Global.player.total_slots:
		push_error("Starting loadout greater than total slots")
		return 
	
	var slots: Array[Slot] = slot_machine.get_slots()
	for i in reels.size():
		if not reels[i]:
			continue
		slots[i]._insert_reel(reels[i], false)
	
	modal.queue_free()
	
	_update_combo_legend()
	
func _init_starting_loadout() -> void:
	var slots: Array[Slot] = slot_machine.get_slots()

	slots[0]._insert_reel(Global.reels.get("Attack"), false)
	slots[1]._insert_reel(Global.reels.get("Attack"), false)
	slots[2]._insert_reel(Global.reels.get("Attack"), false)
	slots[3]._insert_reel(Global.reels.get("Defend"), false)
	slots[4]._insert_reel(Global.reels.get("Defend"), false)

func _begin_player_turn() -> void:
	turn_context = TurnContext.new(context)
	_reset_player_turn_state()
	Global.player.regen_tokens()
	player_turn_started.emit()
	Global.player.broadcast("on_player_turn_started", [context])
	
	_begin_swap_phase()

func _reset_player_turn_state() -> void:
	selected_slots = {}
	slot_to_swap = null
	slot_machine.lever.disabled = false
	slot_machine.lock_in_button.disabled = true
	max_active_slots = Global.player.max_active_slots
	
	for slot: Slot in get_tree().get_nodes_in_group("slots"):
		slot.hold_button.disabled = true
		slot.is_held = false


func _begin_swap_phase() -> void:
	curr_slot_press_action = SlotPressAction.SWAP


# On lever pulled
func _end_swap_phase() -> void:
#	Disable swapping (potentially change what action clicking on slot performs)
	if curr_slot_press_action != SlotPressAction.SELECT:
		for slot: Slot in get_tree().get_nodes_in_group("slots"):
			slot.reset_hold()
	curr_slot_press_action = SlotPressAction.NONE
	_begin_slot_select_phase()

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
	curr_slot_press_action = SlotPressAction.SELECT

# On confirm button press
func _end_slot_select_phase() -> void:
	slot_machine.lever.disabled = true
	slot_machine.lock_in_button.disabled = true
	curr_slot_press_action = SlotPressAction.NONE
	_begin_action_resolution_phase()


func _begin_action_resolution_phase() -> void:
	"""
	Calculate result of player's finalized symbols and
		perform actions
	"""
	var res_context: ResolutionContext = ResolutionContext.build(Global.player, enemies, initial_spin_completed, selected_slots, turn_context)
	res_context.actions = SymbolResolver.resolve(res_context)
	
	Global.player.broadcast("on_resolution", [res_context])
	await _perform_actions(res_context.actions, Global.player, enemies[0])
	
	var encore: TheEncoreDrink = null
	for drink in Global.player.active_drinks:
		if drink is TheEncoreDrink:
			encore = drink
			break

	if encore and encore.available:
		await _perform_actions(res_context.actions, Global.player, enemies[0])
		encore.available = false
	
	_end_player_turn()

#func _get_selected_stops() -> Array[ReelStop]:
##	TODO: if we don't care about order, and more about quantity - update to dictionary of counts
	#var stops: Array[ReelStop] = []
	#for slot: Slot in selected_slots.keys():
		#stops.append(slot.get_curr_stop())
	#
	#return stops


func _perform_actions(actions: Array[Action], source: CombatantData = Global.player, target: CombatantData = null) -> void:
	for action in actions:
		# Don't perform no ops
		if action.value == 0:
			continue
		
		match action.type:
			Action.Type.ATTACK:
				#for enemy: EnemyData in enemies:
				var actual_dmg := target.take_damage(action.value)
				action.display_string = "%s dealt %d damage to %s!" % [source.display_name, actual_dmg, target.display_name]
			Action.Type.DEFEND:
				source.add_block(action.value)
			Action.Type.HEAL:
				source.heal(action.value)
				
				
		_display_action(action)
		await get_tree().create_timer(1.3).timeout


func _display_action(action: Action) -> void:
	spawn_popup(action.display_string)
	

func _end_player_turn() -> void:
	Global.player.broadcast("on_turn_ended", [context])
#	Reset selected slots pressed
	for slot: Slot in selected_slots:
		slot.unselect()
		
	await get_tree().create_timer(2).timeout
	_start_enemy_turn()


func _start_enemy_turn() -> void:
	enemy_turn_started.emit()
	#EventBus.turn_started.emit(Turn.ENEMY)
	for enemy in enemies:
		if is_instance_valid(enemy):
			var actions := enemy.get_actions()
			await _perform_actions(actions, enemy, Global.player)
	#if combat_state != CombatState.ENDED:
	
	#_start_player_turn()
	_end_enemy_turn()


func _end_enemy_turn() -> void:
	_begin_player_turn()


# TODO: these should emit signals and let scene manager handle
func _end_combat(result: CombatResult) -> void:
	Global.player.broadcast("on_combat_ended", [result, context])
	
	if result == CombatResult.VICTORY:
		_show_post_combat()
	else:
		add_child(DEATH_SCREEN_SCENE.instantiate())
	
func _show_post_combat() -> void:
	add_child(COMBAT_REWARD_SCREEN_SCENE.instantiate())

# On slot press
func _on_slot_pressed(slot: Slot) -> void:
	match curr_slot_press_action:
		SlotPressAction.SWAP:
			_start_swap(slot)
		SlotPressAction.SELECT:
			_select_slot(slot)
		SlotPressAction.NONE:
			pass # no op

func _start_swap(slot: Slot) -> void:
	if curr_slot_press_action != SlotPressAction.SWAP:
		return
	
	if slot == slot_to_swap:
		side_panel.close()
		slot_to_swap = null
		return
	
	slot_to_swap = slot
	side_panel.open_for_swap()

# On inventory reel press
func _on_inventory_reel_pressed(reel: Reel) -> void:
	if slot_to_swap:
		_swap_slot_reels(reel)

func _swap_slot_reels(reel_to_insert: Reel) -> void:
	if not slot_to_swap:
		return
	
	if slot_to_swap.attempt_reel_swap(reel_to_insert) == true:
		slot_to_swap = null

func _select_slot(slot: Slot) -> void:
	if curr_slot_press_action != SlotPressAction.SELECT:
		return
	
	if slot in selected_slots:
		selected_slots.erase(slot)
		slot.unselect()
	else:
		if len(selected_slots) < max_active_slots:
			selected_slots[slot] = true
			slot.select()
		else:
#			Block selection and notify user
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

Next up:
	create combo legend
	think about combo values.
		need to create decision points on when/which to lock slots.
		do i lock a heavy in hopes for a heavy combo (less likely to hit)? or do i lock in a light
		for higher chance of light combo?
"""

func _on_spin_all_completed() -> void:
	_update_combo_legend()
	slot_machine.lever.disabled = curr_slot_press_action == SlotPressAction.NONE or Global.player.tokens <= 0

func _update_combo_legend() -> void:
	var slots: Array[Slot] = []
	
	for slot: Slot in slot_machine.get_slots():
		slots.append(slot)

	var combo_legend_values := _get_combo_legend_values(slots, max_active_slots)
	EventBus.combo_legend_updated.emit(combo_legend_values)

func _get_combo_legend_values(options: Array[Slot], max_combo_size: int) -> Array[ComboLegendRow]:
	"""
	Given an array of available symbols/stops and max_combo_size.
	Do we want to account for specific stop/modifiers?
	That might make things complicated??
	Let's just do symbols for now, since modifiers don't exist yet, and we can reconsider later
	
	what exactly do we want to return? how to populate legend?
	required symbols: Array[SlotSymbol]
	result: (e.g. HEAL 5)
			result type
			value
	"""
	"""
	impl:
		count frequencies
		for symbol:
			for i in range(count[symbol]):
				add row (get combo value)
				SymbolResolver._get_combo_value()
	"""
	var legend_rows: Array[ComboLegendRow] = []
	var symbol_count: Dictionary[SlotSymbol, int]
	
	for option: Slot in options:
		if not option.get_curr_stop():
			continue
		var symbol: SlotSymbol = option.get_curr_stop().slot_symbol
		symbol_count[symbol] = symbol_count.get(symbol, 0) + 1
		
	for symbol: SlotSymbol in symbol_count.keys():
		var max_symbol_combo: int = min(symbol_count[symbol], max_combo_size)
		for i: int in max_symbol_combo:
			legend_rows.append(ComboLegendRow.new(symbol, i + 1))
			
	return legend_rows
	
	
"""
accessibility:
	Hold Slot: space bar
	Select/deselect slot:
	confirm
	Next slot: tab, right arrow
	prev slot: shift tab
	
"""
