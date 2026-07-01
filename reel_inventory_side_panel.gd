extends PanelContainer

@export var panel_width: float = 300.0
@export var slide_duration: float = 0.3

var is_open: bool = false
var tween: Tween
var curr_selected_slot = null

@onready var grid = $MarginContainer/VBoxContainer/GridContainer

const ReelInventoryItemScene = preload("res://reel_inventory_item.tscn")


func _ready() -> void:
	custom_minimum_size.x = panel_width
	
	# Start off-screen
	# TODO: investigate why i have to add
	position.x = get_viewport().size.x + size.x + 200
	
	EventBus.slot_selected.connect(_on_open_requested)
	EventBus.close_side_panel.connect(close)

func populate(inventory_data) -> void:
	print_debug("Populating side panel...")
	for child in grid.get_children():
		child.queue_free()

	for i in inventory_data.size():
		var item = ReelInventoryItemScene.instantiate()
		grid.add_child(item)
		item.setup(inventory_data[i])
		
		
func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _on_open_requested(slot):
	if curr_selected_slot == slot:
		close()
	else:
		curr_selected_slot = slot
		open()
	
func open() -> void:
	if is_open: return
		
	is_open = true
	_animate_to(get_viewport().size.x - size.x)

func close() -> void:
	if !is_open: return

	is_open = false
	curr_selected_slot = null
	_animate_to(get_viewport().size.x)

func _animate_to(target_x: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:x", target_x, slide_duration)

"""
if we click the same slot, it will close it
if we click a different slot than current,
	it will keep it open
	
or if open and null, and we click a slot, it stays open
if closed and null, we open and update selected
	
We do have to track the currently selected slot
so as to know which slot to replace.
	where should that exist?
	On slot_machine
	
slot emit sidepanel toggle signal
	side panel requested selected_reel from SlotMachine
slot emit signal on press to update selected
slot machine listens for signal and updates selected

"""
