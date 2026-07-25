extends PanelContainer
class_name PaylineSummaryPanel
## The line readout (§9), deliberately kept in its own fixed-size box above
## the payline list.
##
## It has to be fixed size. Hover text varies from one line to four, and if the
## box could resize it would push the rows under the cursor, firing
## mouse_exited/mouse_entered and flickering between two states forever.
##
## The size is held by giving this panel a custom_minimum_size while its
## contents hang off an anchored child, which contributes no minimum size of
## its own — so text length can never affect the box.

const BOX_SIZE := Vector2(360, 116)

var _title: Label
var _body: Label
var _block: Label


func _ready() -> void:
	custom_minimum_size = BOX_SIZE
	clip_contents = true

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)

	# Plain Control + anchored VBox: reports no minimum size, so however much
	# text lands inside, the panel stays exactly BOX_SIZE.
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(clip)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	clip.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_title = _make_label()
	_body = _make_label()
	_block = _make_label()
	for label in [_title, _body, _block]:
		vbox.add_child(label)


func _make_label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func set_content(title: String, body: String, block: String) -> void:
	_title.text = title
	_body.text = body
	_block.text = block


func clear() -> void:
	set_content("", "", "")
