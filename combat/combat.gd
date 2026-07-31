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
##
## At 2/4 an extra line was bought on essentially every turn, which is the
## exact condition §5 says to correct. 4/8 overcorrected: a second line ate a
## whole early turn's budget, so those turns collapsed to one line and no
## respins. At 3/6 the second line stays the normal purchase while the third
## becomes something you bank for — the bank-and-spike decision §5 wanted.
const LINE_COSTS: Array[int] = [0, 3, 6]

## Lines played this turn — distinct from the pattern inventory, which is
## permanent (§4). Reset every turn.
var selected_lines: Array[Payline] = []
var _tokens_spent_on_lines: int = 0

## What was played last turn, for Cold Deck to lock out. Cleared at combat start
## so the first turn of a fight is never restricted.
var lines_played_last_turn: Array[Payline] = []

## True while the reels are moving or the turn is resolving. Tracked explicitly
## rather than inferred from button states: "every control is disabled" is also
## true when the player has simply run out of tokens, which would wrongly lock
## them out of picking their free line.
var _busy: bool = false

## Latched the moment either side dies. Resolution stops immediately: the rest
## of a payline must not keep swinging at a corpse, and every downstream step
## (further actions, the encore repeat, the enemy turn, the next player turn)
## has to become a no-op.
var _combat_over: bool = false


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
	if _combat_over:
		return
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
	slot_machine.nudge_requested.connect(_on_nudge_requested)
	slot_machine.payline_panel.line_clicked.connect(_on_line_clicked)
	slot_machine.payline_panel.line_hovered.connect(_on_line_hovered)

	_init_enemies()
	_begin_combat()

func _begin_combat() -> void:
	# Combat-scoped, so a rake from the last fight cannot follow the player.
	Global.action_cut = 0
	Global.player.replenish_tokens()
	context.player = Global.player

	Global.player.broadcast("on_combat_started", [context])
	_begin_player_turn()


## --------- Player turn: spin -> hold -> respin (paying) -> lock in --------- ##

func _begin_player_turn() -> void:
	context.turn_number += 1
	turn_context = TurnContext.new(context)
	# Drinks expire and debuffs land without a shared signal, so the turn
	# boundary is where the HUD catches up on what is actually in effect.
	HUD.refresh()
	# Block expires between turns; excess is wasted (§10). There is no previous
	# turn to expire on turn 1, so combat-start grants (Rabbit's Foot) survive
	# into it instead of being wiped the instant they land.
	if context.turn_number > 1:
		Global.player.reset_block()
	Global.player.regen_tokens()
	has_spun_this_turn = false
	respins_this_turn = 0
	selected_lines.clear()
	_tokens_spent_on_lines = 0
	slot_machine.payline_panel.locked_lines = _locked_lines()
	_busy = false

	for col: ReelColumn in slot_machine.reel_columns:
		col.jammed = false
		col.held = false

	player_turn_started.emit()
	Global.player.broadcast("on_player_turn_started", [context])

	# Choosing an intent can end the fight — Two Faced bleeds itself to charge
	# and may die doing it. Don't open a turn against a corpse.
	if _combat_over:
		return

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

	# Held columns do not move, so they do not re-appear — captured before the
	# spin because holds are cleared as the turn advances.
	var moved: Array[ReelColumn] = []
	for col: ReelColumn in slot_machine.reel_columns:
		if not col.held:
			moved.append(col)

	Global.reroll_mysteries()
	await slot_machine.spin_all()

	has_spun_this_turn = true

	# Symbols that pay just for showing up (§ Penny), counted only where the reel
	# actually turned. Holding a Penny and rerolling around it is not a new
	# appearance, and paying it again would make it farmable for the price of a
	# respin.
	var board := BoardEffects.apply(moved, Symbol.Trigger.ON_SPIN)
	if board.gold > 0:
		spawn_popup("+%dg from the board" % board.gold)
	if board.damage > 0:
		spawn_popup("-%d HP from the board" % board.damage)

	_apply_reel_jams()

	_busy = false
	_set_controls_enabled(true)
	_refresh_paylines()


## Freezes every column showing a Reel Jam, and clears the rest — a jam lasts
## exactly until the next spin, so a column that shook one off is free again.
##
## Never all five. At one Jam stop that state is a 1-in-21,000 fluke, but a
## board where every column is frozen makes the respin button cost tokens to do
## nothing, and "rare" is not "acceptable" for a dead end.
func _apply_reel_jams() -> void:
	var jammed: Array[ReelColumn] = []
	for col: ReelColumn in slot_machine.reel_columns:
		col.jammed = false
		var has_jam := false
		for stop: Stop in col.reel.visible_stops():
			if stop != null and stop.symbol == SymbolTable.REEL_JAM:
				has_jam = true
		if has_jam:
			jammed.append(col)

	if jammed.size() >= slot_machine.reel_columns.size():
		jammed.pop_back()
	for col: ReelColumn in jammed:
		col.jammed = true


## A nudge is a spin: it changes what is on the board, so everything that keys
## off a settled board has to run again. That includes Live Wire and Penny —
## letting a nudge dodge the spin tax would quietly weaken the curse built to
## punish exactly this kind of board manipulation.
##
## It is not a *respin*, though: respins_this_turn is untouched, so nudging
## never raises the lever's price.
func _on_nudge_requested(column: ReelColumn, delta: int) -> void:
	if _busy or _combat_over or not has_spun_this_turn:
		return
	if not column.can_nudge():
		return
	var shim := Global.player.nudge_source()
	if shim == null:
		return

	shim.charges -= 1
	_busy = true
	_set_controls_enabled(false)

	await column.nudge(delta)

	# Only the nudged column moved, so only it can have newly appeared.
	var board := BoardEffects.apply([column] as Array[ReelColumn], Symbol.Trigger.ON_SPIN)
	if board.gold > 0:
		spawn_popup("+%dg from the board" % board.gold)
	if board.damage > 0:
		spawn_popup("-%d HP from the board" % board.damage)

	_apply_reel_jams()
	HUD.refresh()

	_busy = false
	_set_controls_enabled(true)
	_refresh_paylines()


func _set_controls_enabled(enabled: bool) -> void:
	# `live` means there's a settled board to act on. Nothing is available
	# before the opening spin lands — including reading or picking paylines,
	# since selection is post-spin by design (§4).
	var live := enabled and has_spun_this_turn
	var can_nudge := Global.player.nudge_source() != null
	for col: ReelColumn in slot_machine.reel_columns:
		col.hold_button.disabled = not live or col.jammed
		col.set_nudging_available(live and can_nudge)
	# Locking in with nothing selected is legal: it skips the turn. The label
	# stays LOCK IN either way — one button, one word.
	slot_machine.lock_in_button.disabled = not live
	slot_machine.lever.disabled = not live or Global.player.tokens < _next_spin_cost()
	slot_machine.lever.text = "RESPIN (%d)" % _next_spin_cost()
	slot_machine.payline_panel.set_interactive(live)


## Cost of the nth respin in a turn. The opening spin is free and automatic, so
## the lever is always a respin.
##
## Superlinear past the third. A flat +1 per respin let a hoarder convert banked
## tokens into six looks in one turn, which is searching for a board rather than
## gambling on one (§5). The first three are unchanged, because those are the
## only ones a player without Token stops ever reaches: baseline income is one
## token a turn, so this ladder is build-facing content and steepening its early
## rungs would only tax the build that pays for it.
const RESPIN_COSTS: Array[int] = [1, 2, 3, 5, 8]
## Each respin past the table costs this much more than the last.
const RESPIN_COST_STEP: int = 3


func _next_spin_cost() -> int:
	if respins_this_turn < RESPIN_COSTS.size():
		return RESPIN_COSTS[respins_this_turn]
	var beyond := respins_this_turn - RESPIN_COSTS.size() + 1
	return RESPIN_COSTS[-1] + RESPIN_COST_STEP * beyond


## ---------------- Line selection (post-spin, perfect information) ---------------- ##

## What the Nth simultaneous line costs (§5). Index 0 is normally the free one,
## which is exactly why a debuff that charges for it lands on every player
## rather than only on the ones already doing well enough to buy a second.
func _cost_of_nth_line(n: int) -> int:
	var cost := LINE_COSTS[n] if n < LINE_COSTS.size() else LINE_COSTS[-1]
	for effect: RunEffect in Global.player.get_active_effects():
		cost = effect.modify_line_cost(cost, n)
	return maxi(0, cost)


## Total tokens required to hold `count` lines at once.
func _total_cost_for(count: int) -> int:
	var total := 0
	for i in count:
		total += _cost_of_nth_line(i)
	return total


func _on_line_clicked(payline: Payline) -> void:
	# Selection is post-spin (§4) — there's no board to judge before then.
	# Being broke never blocks selection: the first line is always free.
	if _busy or _combat_over or not has_spun_this_turn:
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
			costs)
	slot_machine.show_selected_paylines(selected_lines)


func _on_lever_pulled() -> void:
	if _busy or _combat_over or not has_spun_this_turn:
		return
	var cost := _next_spin_cost()
	if Global.player.tokens < cost:
		slot_machine.lever.disabled = true
		return

	Global.player.tokens -= cost
	respins_this_turn += 1
	await _spin_all()


func _on_lock_in_pressed() -> void:
	if _busy or _combat_over or not has_spun_this_turn:
		return

	# Skipping: no lines, so nothing scores, nothing resolves, and the turn ends
	# with the enemy's hit landing on an unblocked player. That cost is the whole
	# point — anything that pays for skipping is paying for taking it.
	if selected_lines.is_empty():
		_busy = true
		_set_controls_enabled(false)
		Global.player.broadcast("on_turn_skipped", [context])
		spawn_popup("SKIPPED")
		_end_player_turn()
		return

	_busy = true
	_set_controls_enabled(false)
	slot_machine.show_selected_paylines(selected_lines)

	var stops: Array[Stop] = []
	for line: Payline in selected_lines:
		stops.append_array(PaylineEvaluator.stops_for(line, slot_machine.reel_columns))

	var res_context := ResolutionContext.build(
			Global.player, enemies, respins_this_turn == 0, stops, turn_context,
			BoardEffects.visible_symbols(slot_machine.reel_columns))

	# Every purchased line scores independently and they sum — a cell sitting on
	# two lines pays into both (double-dip, §4). One Action per matched run,
	# left to right within each line, so _perform_actions animates them one at
	# a time in board order. This is the only path that fires combo payoffs and
	# modifier side effects; hover previews score without them.
	var actions := PaylineEvaluator.resolve(
			selected_lines, slot_machine.reel_columns, res_context)

	res_context.actions = actions
	Global.player.broadcast("on_resolution", [res_context])

	# Nothing anywhere warns this exists; landing it is the entire reveal.
	if PaylineEvaluator.take_wild_jackpot_flag():
		spawn_popup("JACKPOT")
		await get_tree().create_timer(1.0).timeout

	# Board payouts that land once per turn (§ Chip), before the line resolves.
	var board := BoardEffects.apply(slot_machine.reel_columns, Symbol.Trigger.ON_LOCK)
	if board.gold > 0:
		spawn_popup("+%dg from the board" % board.gold)
	await _perform_actions(actions, Global.player, enemies[0])

	var encore: TheEncoreDrink = null
	for drink in Global.player.active_drinks:
		if drink is TheEncoreDrink:
			encore = drink
			break

	# `enemies` is emptied on the killing blow, so this must not run afterwards.
	if encore and encore.available and not _combat_over and not enemies.is_empty():
		await _perform_actions(actions, Global.player, enemies[0])
		encore.available = false

	if _combat_over:
		return
	_end_player_turn()


func _perform_actions(actions: Array[Action], source: CombatantData = Global.player, target: CombatantData = null) -> void:
	for action in actions:
		# The killing blow ends the turn. Remaining runs on the payline don't
		# resolve — they'd hit a dead target and re-trigger the end of combat.
		if _combat_over:
			return
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
			Action.Type.GOLD:
				Global.player.gold += action.value
				action.display_string = "+%dg!" % action.value
			Action.Type.TOKEN:
				var before := Global.player.tokens
				Global.player.tokens += action.value
				var gained := Global.player.tokens - before
				action.display_string = "+%d token%s!" % [gained, "" if gained == 1 else "s"] \
						if gained > 0 else "Already at the token cap!"

		_display_action(action)
		await get_tree().create_timer(1.3).timeout


func _display_action(action: Action) -> void:
	spawn_popup(action.display_string)


## Lines Cold Deck is holding shut this turn. Never every line the player owns:
## a debuff that leaves no legal move is a softlock, not a difficulty spike.
func _locked_lines() -> Array[Payline]:
	var has_cold_deck := false
	for d: Debuff in Global.player.active_debuffs:
		if d is ColdDeckDebuff:
			has_cold_deck = true
	if not has_cold_deck or lines_played_last_turn.is_empty():
		return []
	var locked: Array[Payline] = []
	for line: Payline in lines_played_last_turn:
		if line in Global.player.owned_paylines:
			locked.append(line)
	if locked.size() >= Global.player.owned_paylines.size():
		locked.remove_at(locked.size() - 1)
	return locked


func _end_player_turn() -> void:
	lines_played_last_turn = selected_lines.duplicate()
	Global.player.broadcast("on_turn_ended", [context])

	await get_tree().create_timer(2).timeout
	if _combat_over:
		return
	_start_enemy_turn()


func _start_enemy_turn() -> void:
	enemy_turn_started.emit()
	# A guard raised last turn has done its job by now: it stood through the
	# player's turn, which is the only turn it could have mattered for.
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.reset_block()
	for enemy in enemies:
		if _combat_over:
			return
		if is_instance_valid(enemy):
			var actions := enemy.get_actions()
			await _perform_actions(actions, enemy, Global.player)
	if _combat_over:
		return
	_end_enemy_turn()


func _end_enemy_turn() -> void:
	_begin_player_turn()


# TODO: these should emit signals and let scene manager handle
## Idempotent — only the first call does anything, so a stray second death
## signal can never stack a second reward screen.
func _end_combat(result: CombatResult) -> void:
	if _combat_over:
		return
	_combat_over = true
	_set_controls_enabled(false)

	Global.player.broadcast("on_combat_ended", [result, context])

	if result == CombatResult.VICTORY:
		RunManager.award_combat_reward()
		_show_post_combat()
	else:
		add_child(DEATH_SCREEN_SCENE.instantiate())

func _show_post_combat() -> void:
	add_child(COMBAT_REWARD_SCREEN_SCENE.instantiate())
