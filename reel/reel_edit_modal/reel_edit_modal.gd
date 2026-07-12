extends Control
class_name ReelEditModal

signal edit_completed
signal back_requested

var reel: Reel
var action: ReelModificationFlow.ModAction

@warning_ignore("untyped_declaration")
var payload  # SlotSymbol for ADD_STOP, modifier Resource for ADD_MODIFIER, null for REMOVE

@onready var wheel: ReelWheelDisplay = %Wheel
@onready var instruction_label: Label = %InstructionLabel
@onready var hover_info: Label = %HoverInfoLabel
@onready var back_button: Button = %BackButton

@warning_ignore("untyped_declaration")
func setup(p_reel: Reel, p_action: ReelModificationFlow.ModAction, p_payload = null) -> void:
	reel = p_reel
	action = p_action
	payload = p_payload


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_requested.emit())
	wheel.setup(reel)
	wheel.wedge_clicked.connect(_on_wedge_clicked)
	wheel.insertion_clicked.connect(_on_insertion_clicked)
	wheel.wedge_hovered.connect(_on_wedge_hovered)

	match action:
		ReelModificationFlow.ModAction.ADD_STOP:
			wheel.mode = ReelWheelDisplay.WheelMode.SELECT_INSERTION
			instruction_label.text = "Choose where to insert the new %s stop" % payload.symbol_name
		ReelModificationFlow.ModAction.ADD_MODIFIER:
			wheel.mode = ReelWheelDisplay.WheelMode.SELECT_STOP
			instruction_label.text = "Choose a stop to receive the modifier"
		ReelModificationFlow.ModAction.REMOVE_STOP:
			wheel.mode = ReelWheelDisplay.WheelMode.SELECT_STOP
			instruction_label.text = "Choose a stop to remove"


func _on_wedge_clicked(stop_index: int) -> void:
	print_debug(action)
	match action:
		ReelModificationFlow.ModAction.ADD_MODIFIER:
			reel.reel_stops[stop_index].modifiers.append(payload)
		ReelModificationFlow.ModAction.REMOVE_STOP:
			if reel.reel_stops.size() <= 1:
				return
			reel.reel_stops.remove_at(stop_index)
	_complete()


func _on_insertion_clicked(insert_index: int) -> void:
	if action != ReelModificationFlow.ModAction.ADD_STOP:
		return
	reel.reel_stops.insert(insert_index, ReelStop.new(payload))
	_complete()


func _complete() -> void:
	EventBus.reel_modified.emit(reel)
	edit_completed.emit()


func _on_wedge_hovered(stop_index: int) -> void:
	if stop_index == -1:
		hover_info.text = ""
		return
	var stop: ReelStop = reel.reel_stops[stop_index]
	var mods := ""
	if not stop.modifiers.is_empty():
		mods = "  (+%d modifier%s)" % [stop.modifiers.size(), "s" if stop.modifiers.size() > 1 else ""]
	hover_info.text = stop.slot_symbol.symbol_name + mods
