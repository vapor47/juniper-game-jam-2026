extends CanvasLayer
## Pattern acquisition (§4): the player picks a new line shape after a combat.
##
## In isolation all patterns are statistically identical, so the offer is only
## meaningful relative to what's already owned — each option shows how many
## cells it shares with the current inventory, which is the concentrate-vs-
## spread axis the choice actually turns on.

const NUM_REWARDS := 3


func _ready() -> void:
	var pool := PaylineCatalog.acquirable(Global.player.owned_paylines)
	pool.shuffle()
	_init_rewards(pool.slice(0, NUM_REWARDS))


func _init_rewards(paylines: Array[Payline]) -> void:
	var container: HBoxContainer = %CombatRewardContainer
	if paylines.is_empty():
		var done := Label.new()
		done.text = "Every payline acquired."
		container.add_child(done)
		return

	for payline: Payline in paylines:
		container.add_child(_build_reward_button(payline))


func _build_reward_button(payline: Payline) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(200, 160)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)

	var glyph := PaylineGlyph.new()
	glyph.payline = payline
	glyph.shared_columns = _shared_columns(payline)
	glyph.custom_minimum_size = Vector2(90, 80)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(glyph)

	var name_label := Label.new()
	name_label.text = payline.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var overlap_label := Label.new()
	overlap_label.text = _overlap_text(payline)
	overlap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(overlap_label)

	button.pressed.connect(func() -> void:
		Global.player.add_payline(payline)
		SceneManager.combat_reward_chosen.emit())
	return button


## Cells shared with any already-owned line, per column.
func _shared_columns(payline: Payline) -> Dictionary:
	var shared := {}
	for owned: Payline in Global.player.owned_paylines:
		for col in payline.pattern.size():
			if payline.row_at(col) == owned.row_at(col):
				shared[col] = true
	return shared


func _overlap_text(payline: Payline) -> String:
	var shared := _shared_columns(payline).size()
	if shared == 0:
		return "spreads — no shared cells\n(more of the board live)"
	return "concentrates — %d shared cell%s\n(holds pay into both)" % [
			shared, "" if shared == 1 else "s"]
