extends Node
class_name ReelModificationFlow
## Owns the reel-select -> reel-edit modal flow. Usage from shop:
##   flow.start(ModAction.ADD_STOP, purchased_symbol)
##   flow.flow_finished.connect(_on_purchase_flow_done)   # commit gold here
##   flow.flow_aborted.connect(_on_purchase_flow_abort)   # refund/cancel here

signal flow_finished
signal flow_aborted

enum ModAction { ADD_MODIFIER, ADD_STOP, REMOVE_STOP }

const REEL_SELECT_MODAL_SCENE = preload("res://reel/reel_select_modal/reel_select_modal.tscn")
const REEL_EDIT_MODAL_SCENE = preload("res://reel/reel_edit_modal/reel_edit_modal.tscn")

var _action: ModAction
var _payload
var _select_modal: ReelSelectModal
var _edit_modal: ReelEditModal


func start(action: ModAction, payload = null) -> void:
	_action = action
	_payload = payload
	_open_select_modal()


func _open_select_modal() -> void:
	_select_modal = REEL_SELECT_MODAL_SCENE.instantiate()
	_select_modal.setup(_action)
	_select_modal.reel_selected.connect(_on_reel_selected)
	_select_modal.cancelled.connect(_abort)
	get_tree().current_scene.add_child(_select_modal)


func _on_reel_selected(reel: Reel) -> void:
	_edit_modal = REEL_EDIT_MODAL_SCENE.instantiate()
	_edit_modal.setup(reel, _action, _payload)
	_edit_modal.edit_completed.connect(_finish)
	_edit_modal.back_requested.connect(_back_to_select)
	get_tree().current_scene.add_child(_edit_modal)
	_select_modal.hide()  # keep alive underneath for "back"


func _back_to_select() -> void:
	_edit_modal.queue_free()
	_edit_modal = null
	_select_modal.show()


func _finish() -> void:
	_teardown()
	flow_finished.emit()


func _abort() -> void:
	_teardown()
	flow_aborted.emit()


func _teardown() -> void:
	if is_instance_valid(_edit_modal):
		_edit_modal.queue_free()
	if is_instance_valid(_select_modal):
		_select_modal.queue_free()
	_edit_modal = null
	_select_modal = null
