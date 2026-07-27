extends CanvasLayer
## Pattern acquisition (§4): the player picks a new line shape after a combat.
##
## In isolation all patterns are statistically identical, so the offer is only
## meaningful relative to what's already owned — each option shows how many
## cells it shares with the current inventory, which is the concentrate-vs-
## spread axis the choice actually turns on.

const NUM_REWARDS := 3

## Everything the screen draws, so peeking can hide the lot in one go while
## leaving the button that brings it back.
var _panels: Array[CanvasItem] = []
var _peek_button: Button

## Gap between the Continue button and the peek button.
const PEEK_GAP := 16.0


func _ready() -> void:
	_show_payout()
	_build_peek_button()
	var pool := PaylineCatalog.acquirable(Global.player.owned_paylines)
	pool.shuffle()
	_init_rewards(pool.slice(0, NUM_REWARDS))


## The win's gold, stated as a figure and nothing else. It has already been
## banked by the time this screen opens; this is where the player sees it.
func _show_payout() -> void:
	var vbox: VBoxContainer = $VBoxContainer
	var label := Label.new()
	label.text = "+%dg" % RunManager.last_combat_reward
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	vbox.add_child(label)
	vbox.move_child(label, 1)


## Peeking at the machine behind the screen, rather than restating the payline
## inventory here. The board is still on screen and already draws every owned
## line in its panel — a second, smaller copy of that on top of it was the same
## information twice, in a worse rendering.
##
## Combat disabled its controls when it ended, so the machine underneath is
## read-only; peeking cannot touch it.
func _build_peek_button() -> void:
	# Only the shade and the offers hide. The button is a separate child so it
	# keeps its place while peeking instead of vanishing with what it toggles.
	_panels = [$ColorRect, $VBoxContainer]

	_peek_button = Button.new()
	_peek_button.text = "VIEW MACHINE"
	_peek_button.toggle_mode = true
	_peek_button.focus_mode = Control.FOCUS_NONE
	_peek_button.toggled.connect(_on_peek_toggled)
	add_child(_peek_button)

	# Positioned off the Continue button's real rect rather than laid out beside
	# it. The reward panel is a full-rect centred VBox, so its height is the
	# whole screen — a spacer sized from it put the button off the bottom edge.
	get_viewport().size_changed.connect(_place_peek)
	_peek_button.resized.connect(_place_peek)
	_place_peek.call_deferred()


## Centred horizontally, a fixed gap under Continue.
func _place_peek() -> void:
	if not is_instance_valid(_peek_button):
		return
	var cont: Control = $VBoxContainer/ContinueButton
	var screen := get_viewport().get_visible_rect().size
	_peek_button.global_position = Vector2(
		(screen.x - _peek_button.size.x) * 0.5,
		cont.global_position.y + cont.size.y + PEEK_GAP)


func _on_peek_toggled(peeking: bool) -> void:
	for panel: CanvasItem in _panels:
		panel.visible = not peeking
	_peek_button.text = "BACK" if peeking else "VIEW MACHINE"


func _unhandled_input(event: InputEvent) -> void:
	if _peek_button != null and _peek_button.button_pressed \
			and event.is_action_pressed("ui_cancel"):
		_peek_button.button_pressed = false
		get_viewport().set_input_as_handled()


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

	button.pressed.connect(func() -> void:
		Global.player.add_payline(payline)
		SceneManager.combat_reward_chosen.emit())
	return button


## Cells shared with any already-owned line, per column. The glyph draws these
## hot, which is the whole concentrate-vs-spread read — no prose needed.
func _shared_columns(payline: Payline) -> Dictionary:
	var shared := {}
	for owned: Payline in Global.player.owned_paylines:
		for col in payline.pattern.size():
			if payline.row_at(col) == owned.row_at(col):
				shared[col] = true
	return shared
