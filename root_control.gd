extends Control

@onready var side_panel: PanelContainer = %ReelInventorySidePanel
#@onready var toggle_btn: Button = $ToggleButton

func _ready() -> void:
	#toggle_btn.pressed.connect(side_panel.toggle)
	#$SidePanel/VBoxContainer/Header/CloseButton.pressed.connect(side_panel.close)
	side_panel.populate(_get_reel_inventory_data())
	set_process_unhandled_input(true)
	
	EventBus.reel_swapped.connect(func(_reel): side_panel.populate(_get_reel_inventory_data()))

func _unhandled_input(event: InputEvent) -> void:
	if not side_panel.is_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if not side_panel.get_global_rect().has_point(event.position):
			side_panel.close()


func _on_item_pressed(item_data: Dictionary) -> void:
	print("Item pressed: ", item_data)
	# Handle action here

func _get_reel_inventory_data() -> Array:
	return Global.reels.keys().map(func(reel_name): return {
		"reel_name": reel_name,
		"reel": Global.reels[reel_name],
		"amount": Global.reel_inventory[reel_name],
	})
