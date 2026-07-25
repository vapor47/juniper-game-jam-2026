extends PanelContainer
class_name SlotMachine

@onready var lever = %SlotMachineLever
@onready var lock_in_button: Button = %LockInButton
@onready var health_bar: HealthBar = %PlayerHealthBar
@onready var phase_label: Label = %PhaseLabel
@onready var payline_panel: PaylinePanel = %PaylinePanel

var reel_columns: Array[ReelColumn] = []
var payline_overlay: PaylineOverlay


func _ready() -> void:
	var placeholder_col: InstancePlaceholder = %ReelColumn
	for i in 5:
		reel_columns.append(placeholder_col.create_instance())

	# Sits above the columns so it can draw a path across all of them. Added
	# after ReelColumns so it renders on top; PanelContainer fits both to the
	# same rect, so overlay-local coordinates line up with the grid.
	payline_overlay = PaylineOverlay.new()
	payline_overlay.columns = reel_columns
	var grid_panel: Control = (%ReelColumns as Control).get_parent()
	grid_panel.add_child(payline_overlay)

	health_bar.setup(Global.player)


## Spins every non-held column, staggered per §8. Columns are started in order
## with a delay between each, so the last one started is the last to land —
## awaiting it awaits the whole batch.
func spin_all() -> void:
	var cols_to_spin: Array[ReelColumn] = reel_columns.filter(func(c: ReelColumn) -> bool: return not c.held)
	if cols_to_spin.is_empty():
		EventBus.spin_all_completed.emit()
		return

	for i in cols_to_spin.size() - 1:
		cols_to_spin[i].spin(randi() % Global.strip.size())
		await get_tree().create_timer(Global.SLOT_REVEAL_STAGGER).timeout

	await cols_to_spin[-1].spin(randi() % Global.strip.size())
	EventBus.spin_all_completed.emit()


## Traces one line's path: its 5 cells lit (brighter where they're part of a
## scoring run), everything else dimmed (§9). Pass null to clear.
func highlight_payline(payline: Payline) -> void:
	payline_overlay.focused_line = payline
	if payline == null:
		for col: ReelColumn in reel_columns:
			col.clear_cell_states()
		return

	var run_columns := {}
	for run: PaylineScorer.Run in PaylineEvaluator.score_for(payline, reel_columns).matched_runs():
		for i in run.count:
			run_columns[run.start_column + i] = true

	for col_idx in reel_columns.size():
		var column: ReelColumn = reel_columns[col_idx]
		var lit_row: int = payline.row_at(col_idx) if col_idx < payline.pattern.size() else -1
		for row in Reel.VISIBLE_ROWS:
			if row != lit_row:
				column.set_cell_state(row, ReelColumn.CellState.DIMMED)
			elif run_columns.has(col_idx):
				column.set_cell_state(row, ReelColumn.CellState.IN_RUN)
			else:
				column.set_cell_state(row, ReelColumn.CellState.ON_LINE)


## Persistent, non-hover treatment: every cell on a purchased line stays lit
## so the board still reads when the cursor is elsewhere.
func show_selected_paylines(selected: Array[Payline]) -> void:
	payline_overlay.selected_lines = selected
	payline_overlay.focused_line = null
	for col: ReelColumn in reel_columns:
		col.clear_cell_states()
	for payline: Payline in selected:
		for col_idx in mini(payline.pattern.size(), reel_columns.size()):
			reel_columns[col_idx].set_cell_state(
					payline.row_at(col_idx), ReelColumn.CellState.ON_LINE)
