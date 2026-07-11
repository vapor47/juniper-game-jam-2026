extends Button
class_name ComboLegendButton

@onready var legend_panel: ComboLegendPanel = $ComboLegendPanel  # sibling popup, initially hidden

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

var _update_pending := false

func _ready() -> void:
	$ComboLegendPanel.panel_updated.connect(_on_panel_updated)
	legend_panel.hide()
	mouse_entered.connect(func() -> void: button_hovered = true)
	mouse_exited.connect(func() -> void: button_hovered = false)
	legend_panel.mouse_entered.connect(func() -> void: panel_hovered = true)
	legend_panel.mouse_exited.connect(func() -> void: panel_hovered = false)


func _request_update() -> void:
	if _update_pending:
		return
	_update_pending = true
	await get_tree().process_frame  # let all enter/exit events settle this frame
	_update_visibility()
	_update_pending = false


func _update_visibility() -> void:
	if button_hovered or panel_hovered:
		_show_legend()
	else:
		legend_panel.hide()

func _show_legend() -> void:
	legend_panel.build_legend()
	legend_panel.show()
	
	#await get_tree().process_frame  # let size resolve after building content
	#
	## local position, relative to this button's parent — no global/screen coords needed
	#legend_panel.position = Vector2(-legend_panel.size.x + size.x, -legend_panel.size.y - 4)  # anchor above button, local space

func _on_panel_updated() -> void:
	await get_tree().process_frame
	legend_panel.position = Vector2(-legend_panel.size.x + size.x, -legend_panel.size.y - 4)  # anchor above button, local space
