extends CanvasLayer

@onready var label: RichTextLabel = %RichTextLabel

var _current_target: Control = null
@warning_ignore("untyped_declaration")
var _content_source
const OFFSET := Vector2(16, 16)
var _has_custom_pos = false

func _ready() -> void:
	label.hide()
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)

@warning_ignore("untyped_declaration")
func show_for(target: Control, content) -> void:
	_current_target = target
	_content_source = content
	#label.text = hover_text
	_refresh_text()
	label.show()
	_update_position()

func hide_for(target: Control) -> void:
	if _current_target == target:
		_current_target = null
		label.hide()
		_has_custom_pos = false

@warning_ignore("untyped_declaration")
func attach_to(node: Node, content) -> void:
	node.mouse_entered.connect(func() -> void: HoverLabel.show_for(node, content))
	node.mouse_exited.connect(func() -> void: HoverLabel.hide_for(node))
	
func _refresh_text() -> void:
	if _content_source is Callable:
		label.text = _content_source.call()
		@warning_ignore("standalone_ternary")
		show() if label.text else hide()
	else:
		label.text = str(_content_source)

func _process(_delta: float) -> void:
	if _current_target:
		if _content_source is Callable:
			_refresh_text()
		_update_position()

func _update_position() -> void:
	if _has_custom_pos:
		return
	var mouse_pos := label.get_viewport().get_mouse_position()
	var viewport_size := label.get_viewport().get_visible_rect().size
	var label_size := label.size

	var pos := mouse_pos + OFFSET

	# flip horizontally if it would overflow the right edge
	if pos.x + label_size.x > viewport_size.x:
		pos.x = mouse_pos.x - OFFSET.x - label_size.x

	# flip vertically if it would overflow the bottom edge
	if pos.y + label_size.y > viewport_size.y:
		pos.y = mouse_pos.y - OFFSET.y - label_size.y

	label.global_position = pos

func set_target_relative_pos(target: Control, relative_pos: Vector2) -> void:
	_has_custom_pos = true
	var target_pos := target.get_global_rect().get_center()
	label.global_position = target_pos + relative_pos
	
"""
Add fixed position and style

Fixed (relative position): (Node-relative position)
	Get center position of node, add vector2. Set as fixed
	Do not update in update position
	
Apply direction to face label, and anchoring/alignment
"""
