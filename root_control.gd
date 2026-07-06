extends Control
class_name CombatScene

@onready var side_panel: PanelContainer = %ReelInventorySidePanel
#@onready var toggle_btn: Button = $ToggleButton
const DEATH_SCREEN_SCENE = preload("res://screens/death_screen.tscn")
const BATTLE_VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")

#func _ready() -> void:
	##toggle_btn.pressed.connect(side_panel.toggle)
	##$SidePanel/VBoxContainer/Header/CloseButton.pressed.connect(side_panel.close)
	#side_panel.populate(_get_reel_inventory_data())
	#set_process_unhandled_input(true)
	#
	#EventBus.reel_swapped.connect(func(_reel): side_panel.populate(_get_reel_inventory_data()))
	##EventBus.combat_ended.connect(
		##func(result):
			##if result == "lose":
				##add_child(DEATH_SCREEN_SCENE.instantiate())
			##elif result == "win":
				##add_child(BATTLE_VICTORY_SCREEN_SCENE.instantiate())
	##)

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
	return Global.reels.keys().map(func(reel_name): return {
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
		if initial_spin_completed != new_value:
			EventBus.spin_lock_toggled.emit()
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
	EventBus.reel_swapped.connect(func(_reel): side_panel.populate(_get_reel_inventory_data()))
	EventBus.lever_pulled.connect(func(): initial_spin_completed = true)
	EventBus.slots_locked_in.connect(_on_spin_resolved)


	_init_enemies()
	_start_combat()
		
func _start_combat() -> void:
#	(Actually this should be handled by enemy itself): Get initial enemy intent 

#	Perform any pre-combat setup (token replenishing, etc)
	_start_player_turn()
	pass
	
func _start_player_turn() -> void:
	initial_spin_completed = false
#	Enable slot machine controls
#	Disable LockInButton

# To be called once the player hits the lock in button
func _end_player_turn() -> void:
#	Disable slot machine controls
	_start_enemy_turn()
	
func _start_enemy_turn() -> void:
	#EventBus.turn_started.emit(Turn.ENEMY)
	for enemy in enemies:
		if is_instance_valid(enemy):
			await enemy.make_move()
	#if combat_state != CombatState.ENDED:
	_start_player_turn()
	
func _end_enemy_turn() -> void:
	_start_player_turn()
	
func _end_combat(result: CombatResult) -> void:
	if result == CombatResult.VICTORY:
		add_child(BATTLE_VICTORY_SCREEN_SCENE.instantiate())
		_show_post_combat()
	else:
		add_child(DEATH_SCREEN_SCENE.instantiate())
	
func _show_post_combat() -> void:
	pass
	
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
