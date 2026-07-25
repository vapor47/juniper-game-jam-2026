extends Control
class_name CombatManager

const DEATH_SCREEN_SCENE = preload("res://screens/death_screen.tscn")
const BATTLE_VICTORY_SCREEN_SCENE = preload("res://screens/battle_victory_screen.tscn")
const COMBAT_REWARD_SCREEN_SCENE = preload("res://screens/combat_reward/combat_reward_screen.tscn")
const FLOATING_TEXT_SCENE = preload("res://floating_text.tscn")

signal player_turn_started
signal enemy_turn_started

enum CombatResult { LOSS, VICTORY }

var enemies: Array[EnemyData]
const ENEMY_SCENE = preload("res://combat/enemies/enemy.tscn")

@onready var slot_machine: SlotMachine = %SlotMachine

var context: CombatContext
var turn_context: TurnContext

## The turn's first spin is free; respins then cost 1/2/3... incrementing
## within the turn (§5). Both reset each turn.
var has_spun_this_turn: bool = false
var respins_this_turn: int = 0

## Cost of the Nth line played in a turn. The first is free; the rest are
## priced as multiples of per-turn token income (§5). Souvenirs raise the
## line cap, they never cut these prices.
const LINE_COSTS: Array[int] = [0, 2, 4]

## Lines played this turn — distinct from the pattern inventory, which is
## permanent (§4). Reset every turn.
var selected_lines: Array[Payline] = []
var _tokens_spent_on_lines: int = 0

## True while the reels are moving or the turn is resolving. Tracked explicitly
## rather than inferred from button states: "every control is disabled" is also
## true when the player has simply run out of tokens, which would wrongly lock
## them out of picking their free line.
var _busy: bool = false


func setup(e: Array[EnemyData]) -> void:
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


func spawn_popup(text: String) -> void:
	var popup := FLOATING_TEXT_SCENE.instantiate()
	popup.text = text
	add_child(popup)

	await get_tree().process_frame

	var screen_center := get_viewport().get_visible_rect().size / 2
	popup.global_position = screen_center - (popup.size / 2)


func _ready() -> void:
	EventBus.lever_pulled.connect(_on_lever_pulled)
	EventBus.slot_selection_confirmed.connect(_on_lock_in_pressed)
	slot_machine.payline_panel.line_clicked.connect(_on_line_clicked)
	slot_machine.payline_panel.line_hovered.connect(_on_line_hovered)

	_init_enemies()
	_begin_combat()

func _begin_combat() -> void:
	Global.player.replenish_tokens()
	context.player = Global.player

	Global.player.broadcast("on_combat_started", [context])
	_begin_player_turn()


## --------- Player turn: spin -> hold -> respin (paying) -> lock in --------- ##

func _begin_player_turn() -> void:
	context.turn_number += 1
	turn_context = TurnContext.new(context)
	# Block expires between turns; excess is wasted (§10).
	Global.player.reset_block()
	Global.player.regen_tokens()
	has_spun_this_turn = false
	respins_this_turn = 0
	selected_lines.clear()
	_tokens_spent_on_lines = 0
	_busy = false

	for col: ReelColumn in slot_machine.reel_columns:
		col.held = false

	player_turn_started.emit()
	Global.player.broadcast("on_player_turn_started", [context])

	# The turn opens with a free automatic spin. Everything stays locked (and
	# reads as locked) until it lands — there's no board to judge until then.
	_set_controls_enabled(false)
	_refresh_paylines()
	await _spin_all()


## The turn's free opening spin, or a paid respin. Locks the controls while the
## reels are in motion, then re-enables them once everything lands.
func _spin_all() -> void:
	_busy = true
	_set_controls_enabled(false)

	await slot_machine.spin_all()

	has_spun_this_turn = true
	_busy = false
	_set_controls_enabled(true)
	_refresh_paylines()


func _set_controls_enabled(enabled: bool) -> void:
	# `live` means there's a settled board to act on. Nothing is available
	# before the opening spin lands — including reading or picking paylines,
	# since selection is post-spin by design (§4).
	var live := enabled and has_spun_this_turn
	for col: ReelColumn in slot_machine.reel_columns:
		col.hold_button.disabled = not live
	slot_machine.lock_in_button.disabled = not live or selected_lines.is_empty()
	slot_machine.lever.disabled = not live or Global.player.tokens < _next_spin_cost()
	slot_machine.lever.text = "RESPIN (%d)" % _next_spin_cost()
	slot_machine.payline_panel.set_interactive(live)


## The opening spin is free and automatic, so the lever is always a respin:
## the nth respin of a turn costs n (§5).
func _next_spin_cost() -> int:
	return respins_this_turn + 1


## ---------------- Line selection (post-spin, perfect information) ---------------- ##

## What the Nth simultaneous line costs (§5). Index 0 is the free one.
func _cost_of_nth_line(n: int) -> int:
	if n < LINE_COSTS.size():
		return LINE_COSTS[n]
	return LINE_COSTS[-1]


## Total tokens required to hold `count` lines at once.
func _total_cost_for(count: int) -> int:
	var total := 0
	for i in count:
		total += _cost_of_nth_line(i)
	return total


func _on_line_clicked(payline: Payline) -> void:
	# Selection is post-spin (§4) — there's no board to judge before then.
	# Being broke never blocks selection: the first line is always free.
	if _busy or not has_spun_this_turn:
		return

	var next := selected_lines.duplicate()
	if payline in next:
		next.erase(payline)
	else:
		if next.size() >= Global.player.max_lines_per_turn:
			return  # cap at 3 lines per turn (§4)
		next.append(payline)

	var required := _total_cost_for(next.size())
	var delta := required - _tokens_spent_on_lines
	if delta > Global.player.tokens:
		return  # can't afford it

	# Selection is freely reversible before lock-in: no new information arrives
	# between selecting and resolving, so irreversibility would be a misclick
	# tax, same reasoning as free holds (§5).
	Global.player.tokens -= delta
	_tokens_spent_on_lines = required
	selected_lines = next

	_refresh_paylines()
	_set_controls_enabled(true)


func _on_line_hovered(payline: Payline) -> void:
	if payline == null:
		slot_machine.show_selected_paylines(selected_lines)
	else:
		slot_machine.highlight_payline(payline)


func _refresh_paylines() -> void:
	var costs := {}
	var next_index := selected_lines.size()
	for payline: Payline in Global.player.owned_paylines:
		if payline in selected_lines:
			costs[payline] = 0
		else:
			costs[payline] = _cost_of_nth_line(next_index)

	slot_machine.payline_panel.refresh(
			Global.player.owned_paylines,
			selected_lines,
			slot_machine.reel_columns,
			PaylineEvaluator.incoming_damage(enemies),
			costs)
	slot_machine.show_selected_paylines(selected_lines)


func _on_lever_pulled() -> void:
	if _busy or not has_spun_this_turn:
		return
	var cost := _next_spin_cost()
	if Global.player.tokens < cost:
		slot_machine.lever.disabled = true
		return

	Global.player.tokens -= cost
	respins_this_turn += 1
	await _spin_all()


func _on_lock_in_pressed() -> void:
	if _busy or not has_spun_this_turn or selected_lines.is_empty():
		return
	_busy = true
	_set_controls_enabled(false)
	slot_machine.show_selected_paylines(selected_lines)

	# Every purchased line scores independently and they sum — a cell sitting on
	# two lines pays into both (double-dip, §4). One Action per matched run,
	# left to right within each line, so _perform_actions animates them one at
	# a time in board order.
	var actions := PaylineEvaluator.combined_actions(selected_lines, slot_machine.reel_columns)

	var stops: Array[Stop] = []
	for line: Payline in selected_lines:
		stops.append_array(PaylineEvaluator.stops_for(line, slot_machine.reel_columns))

	var res_context := ResolutionContext.build(
			Global.player, enemies, respins_this_turn == 0, stops, turn_context)
	res_context.actions = actions
	Global.player.broadcast("on_resolution", [res_context])

	await _perform_actions(actions, Global.player, enemies[0])

	var encore: TheEncoreDrink = null
	for drink in Global.player.active_drinks:
		if drink is TheEncoreDrink:
			encore = drink
			break

	if encore and encore.available:
		await _perform_actions(actions, Global.player, enemies[0])
		encore.available = false

	_end_player_turn()


func _perform_actions(actions: Array[Action], source: CombatantData = Global.player, target: CombatantData = null) -> void:
	for action in actions:
		# Don't perform no ops
		if action.value == 0:
			continue

		match action.type:
			Action.Type.ATTACK:
				var actual_dmg := target.take_damage(action.value)
				action.display_string = "%s dealt %d damage to %s!" % [
						source.display_name, actual_dmg, target.display_name]
			Action.Type.DEFEND:
				source.add_block(action.value)
				action.display_string = "%s gained %d block! (%d total)" % [
						source.display_name, action.value, source.block]
			Action.Type.HEAL:
				var actual_heal := source.heal(action.value)
				if actual_heal > 0:
					action.display_string = "%s healed %d!" % [source.display_name, actual_heal]
				else:
					action.display_string = "%s is already at full health!" % source.display_name

		_display_action(action)
		await get_tree().create_timer(1.3).timeout


func _display_action(action: Action) -> void:
	spawn_popup(action.display_string)


func _end_player_turn() -> void:
	Global.player.broadcast("on_turn_ended", [context])

	await get_tree().create_timer(2).timeout
	_start_enemy_turn()


func _start_enemy_turn() -> void:
	enemy_turn_started.emit()
	for enemy in enemies:
		if is_instance_valid(enemy):
			var actions := enemy.get_actions()
			await _perform_actions(actions, enemy, Global.player)
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
