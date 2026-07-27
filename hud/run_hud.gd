extends CanvasLayer
class_name RunHUD
## Run state that persists across a fight but had nowhere to live: gold, the
## souvenirs and drinks currently in effect, and the way into the pause menu.
##
## Gold was visible only in the shop, so a player spent an entire combat unable
## to see the resource the combat pays out. Souvenirs and drinks were worse —
## they fire hooks every resolution with no on-screen representation at all, so
## an effect changing a payout looked like the numbers being wrong.
##
## Names only, descriptions on hover (§0). A chip states what it is; what it
## does is one hover away, the same contract the shop already uses.

const CHIP_FONT_SIZE := 13
const GOLD_COLOR := Color(0.95, 0.82, 0.35)
const SOUVENIR_COLOR := Color(0.55, 0.72, 0.95)
const DRINK_COLOR := Color(0.78, 0.6, 0.92)
const DEBUFF_COLOR := Color(0.9, 0.5, 0.45)

var _gold_label: Label
var _effects_row: HBoxContainer
var _strip_view: StripView


func _ready() -> void:
	layer = 5
	_build()
	_refresh_gold(Global.player.gold if Global.player else 0)
	if Global.player:
		Global.player.gold_updated.connect(_refresh_gold)
	# Effects change on purchase, on expiry and when a debuff lands, none of
	# which share a single signal — rebuild on the one that covers acquisition
	# and poll the rest at turn boundaries.
	EventBus.run_effect_added.connect(func(_e: RunEffect) -> void: _refresh_effects())
	_refresh_effects()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_theme_constant_override("separation", 20)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(top)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 22)
	_gold_label.add_theme_color_override("font_color", GOLD_COLOR)
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_gold_label)

	_effects_row = HBoxContainer.new()
	_effects_row.add_theme_constant_override("separation", 6)
	_effects_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_effects_row)

	# A toggle rather than hover: the strip is something you study against the
	# board, so it has to stay up while the cursor is somewhere else. Same
	# reason the paytable stopped being a hover popup.
	var strip_toggle := Button.new()
	strip_toggle.text = "STRIP"
	strip_toggle.toggle_mode = true
	strip_toggle.focus_mode = Control.FOCUS_NONE
	strip_toggle.toggled.connect(_on_strip_toggled)
	top.add_child(strip_toggle)

	var settings := Button.new()
	settings.text = "MENU"
	settings.focus_mode = Control.FOCUS_NONE
	settings.pressed.connect(_toggle_pause)
	top.add_child(settings)

	var strip_holder := CenterContainer.new()
	strip_holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip_holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	strip_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip_holder)

	_strip_view = StripView.new()
	_strip_view.hide()
	strip_holder.add_child(_strip_view)


## Rebuilt on open rather than kept live: the strip only changes in the shop,
## so a fight never invalidates it, and rebuilding on show costs nothing.
func _on_strip_toggled(pressed: bool) -> void:
	if pressed:
		_strip_view.refresh()
	_strip_view.visible = pressed


func _refresh_gold(amount: int) -> void:
	_gold_label.text = "%dg" % amount


## One chip per active effect. Rebuilt wholesale — the row is a handful of
## nodes and reconciling it in place would cost more than it saves.
func _refresh_effects() -> void:
	for child in _effects_row.get_children():
		_effects_row.remove_child(child)
		child.queue_free()
	if Global.player == null:
		return
	for s: Souvenir in Global.player.owned_souvenirs:
		_effects_row.add_child(_chip(s, SOUVENIR_COLOR))
	for d: Drink in Global.player.active_drinks:
		_effects_row.add_child(_chip(d, DRINK_COLOR))
	for b: Debuff in Global.player.active_debuffs:
		_effects_row.add_child(_chip(b, DEBUFF_COLOR))


func _chip(effect: RunEffect, color: Color) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.22)
	style.border_color = Color(color.r, color.g, color.b, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	label.text = effect.display_name
	label.add_theme_font_size_override("font_size", CHIP_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	HoverLabel.attach_to(panel, effect.description)
	return panel


## PauseMenu is an autoload, so it already exists and already answers Esc. This
## button is a second way in, not the only one — instantiating the scene here
## would create a rival copy and, because the autoload loads the same resource,
## preloading it from a scene the autoload can reach breaks the autoload itself.
func _toggle_pause() -> void:
	PauseMenu.toggle()


## Drinks expire and debuffs land without a shared signal, so the turn boundary
## is the cheap place to catch up.
func refresh() -> void:
	_refresh_effects()
