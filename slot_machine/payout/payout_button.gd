extends Button
class_name PayoutButton
## Hover target for the paytable. The panel stays up while the cursor is on
## either the button or the panel itself, so the table can be read and
## scrolled without it closing underneath the pointer.
##
## Pressing the button locks it open, so the table can be left up while
## holding columns and reading the board — the case where it's most useful is
## exactly the one where the cursor has to be somewhere else. The button is a
## toggle, so its pressed state is what says the table is pinned.

const GAP := 6.0
const MARGIN := 8.0

@onready var legend_panel: PayoutPanel = $PayoutPanel  # popup child, hidden until hovered

var button_hovered := false:
	set(new_val):
		if new_val == button_hovered:
			return
		button_hovered = new_val
		_update_visibility()

var panel_hovered := false:
	set(new_val):
		if new_val == panel_hovered:
			return
		panel_hovered = new_val
		_update_visibility()


func _ready() -> void:
	# Drawn in screen space rather than inside the header's layout: the button
	# lives in an HBoxContainer, so a panel positioned in local space is both
	# clipped by the machine's margins and z-ordered under its siblings.
	legend_panel.top_level = true
	legend_panel.z_index = 100
	legend_panel.hide()
	legend_panel.panel_updated.connect(_reposition)
	legend_panel.resized.connect(_reposition)
	mouse_entered.connect(func() -> void: button_hovered = true)
	mouse_exited.connect(func() -> void: button_hovered = false)
	legend_panel.mouse_entered.connect(func() -> void: panel_hovered = true)
	legend_panel.mouse_exited.connect(func() -> void: panel_hovered = false)
	toggled.connect(func(_on: bool) -> void: _update_visibility())


## Pinned by the toggle, or held open by the cursor resting on either half.
func locked() -> bool:
	return button_pressed


func _update_visibility() -> void:
	if locked() or button_hovered or panel_hovered:
		legend_panel.build_legend()
		legend_panel.show()
		_reposition()
	else:
		legend_panel.hide()


## Hangs below the button and right-aligned to it, then clamped into the
## viewport. The button sits in the machine's header, so the old placement
## above it put an eleven-row table off the top of the screen.
func _reposition() -> void:
	await get_tree().process_frame  # let the rebuilt table settle its size
	if not is_instance_valid(legend_panel) or not legend_panel.visible:
		return

	var panel_size := legend_panel.get_combined_minimum_size()
	panel_size.x = maxf(panel_size.x, legend_panel.size.x)
	panel_size.y = maxf(panel_size.y, legend_panel.size.y)

	var screen := get_viewport_rect().size
	var pos := global_position + Vector2(size.x - panel_size.x, size.y + GAP)

	# Below if it fits, above if it doesn't, then clamped either way so the
	# table is never partly off-screen.
	if pos.y + panel_size.y > screen.y - MARGIN:
		var above := global_position.y - panel_size.y - GAP
		pos.y = above if above >= MARGIN else MARGIN

	pos.x = clampf(pos.x, MARGIN, maxf(MARGIN, screen.x - panel_size.x - MARGIN))
	pos.y = clampf(pos.y, MARGIN, maxf(MARGIN, screen.y - panel_size.y - MARGIN))
	legend_panel.global_position = pos
