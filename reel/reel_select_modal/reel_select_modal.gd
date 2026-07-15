extends Control
class_name ReelSelectModal

signal reel_selected(reel: Reel)
signal cancelled

var action: ReelModificationFlow.ModAction
var payload

@onready var title_label: Label = %TitleLabel
@onready var reel_grid: GridContainer = %ReelGrid
@onready var cancel_button: Button = %CancelButton


func setup(p_action: ReelModificationFlow.ModAction, p_payload = null) -> void:
	action = p_action
	payload = p_payload

func _ready() -> void:
	cancel_button.pressed.connect(func() -> void: cancelled.emit())
	title_label.text = _title_for_action()
	_populate()


func _populate() -> void:
	for reel_name: String in Global.reels:
		if Global.player.get_reel_inventory().get(reel_name, 0) <= 0:
			continue  # not owned

		var reel: Reel = Global.reels[reel_name]
		var card := Button.new()
		card.custom_minimum_size = Vector2(140, 90)
		card.text = "%s\n%d stops" % [reel_name, reel.reel_stops.size()]

		# removal can't leave a reel empty
		if action == ReelModificationFlow.ModAction.REMOVE_STOP and reel.reel_stops.size() <= 1:
			card.disabled = true
			card.tooltip_text = "Can't remove the last stop"
			
		if action == ReelModificationFlow.ModAction.ADD_STOP and payload.get_symbol_type() not in reel.allowed_symbol_types:
			card.disabled = true
			card.tooltip_text = "Cannot add stop of this type to this reel"

		card.pressed.connect(func() -> void: reel_selected.emit(reel))
		reel_grid.add_child(card)


func _title_for_action() -> String:
	match action:
		ReelModificationFlow.ModAction.ADD_MODIFIER:
			return "Apply modifier to which reel?"
		ReelModificationFlow.ModAction.ADD_STOP:
			return "Add stop to which reel?"
		ReelModificationFlow.ModAction.REMOVE_STOP:
			return "Remove a stop from which reel?"
		_:
			return "Select a reel"
