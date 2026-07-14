extends CanvasLayer
class_name LoadoutSelection

"""
Need to populate empty cells for reels, based on players total slots

Just below is a container of the players inventory.
Player can click a reel as long as they have it in their inventory
	Tho it shouldn't update their inventory yet. That happens when a reel is physically inserted
	Create a snapshop of their inventory and disable based on those values

Can player confirm if they don't fill up all slots?
sure why not. We can then code it such that an insertion on empty slot is free

Slots will naturally fill from left to right
Player can specify what slot to fill by clicking on the cell (track selected cell idx)

Clicking on an occupied cell return the reel to the inventory

Stretch goals:
	(drag and drop)
"""
@onready var loadout_cells := %LoadoutCells
@onready var inventory_grid: GridContainer = %InventoryGrid

signal loadout_confirmed(reels: Array[Reel])

const LOADOUT_CELL_SCENE := preload("res://combat/loadout/loadout_cell.tscn")

var selected_loadout_cell: LoadoutCell
var reel_to_item: Dictionary[Reel, LoadoutSelectInventoryItem]

func _ready() -> void:
	_init_loadout_cells()
	_init_inventory_view()
	if loadout_cells.get_child_count():
		selected_loadout_cell = loadout_cells.get_child(0)

func _init_loadout_cells() -> void:
	for i in Global.player.total_slots:
		var cell: LoadoutCell = LOADOUT_CELL_SCENE.instantiate()
		cell.loadout_cell_pressed.connect(_on_loadout_cell_pressed)
		loadout_cells.add_child(cell)

func _init_inventory_view() -> void:
	for reel_name: String in Global.reel_inventory:
		var reel := Global.reels[reel_name]
		var quantity := Global.reel_inventory[reel_name]
		var item := LoadoutSelectInventoryItem.create(reel, quantity)
		item.loadout_inventory_item_selected.connect(_on_inventory_item_selected)
		reel_to_item[reel] = item
		inventory_grid.add_child(item)

func _on_inventory_item_selected(reel: Reel) -> void:
	if not selected_loadout_cell or not reel:
		return
	if reel == selected_loadout_cell.reel:
		return
	if reel_to_item[reel].quantity <= 0:
		return
		
	var removed_reel: Reel = selected_loadout_cell.insert(reel)
	reel_to_item[reel].quantity -= 1
	if removed_reel:
		reel_to_item[removed_reel].quantity += 1
		
	_select_next_available_cell()

	
func _on_loadout_cell_pressed(cell: LoadoutCell) -> void:
	if cell.reel:
		reel_to_item[cell.reel].quantity += 1
		cell.reel = null
	
	selected_loadout_cell = cell

func _select_next_available_cell() -> void:
	var start := selected_loadout_cell.get_index()
	var num_cells := loadout_cells.get_child_count()
	for i in range(1, num_cells):
		var idx := (start + i) % num_cells
		var cell: LoadoutCell = loadout_cells.get_child(idx)
		if not cell.reel:
			selected_loadout_cell = cell
			return
			
	selected_loadout_cell = null

func _on_confirm_button_pressed() -> void:
	var loadout: Array[Reel] = []
	for c: LoadoutCell in loadout_cells.get_children():
		loadout.append(c.reel)
	loadout_confirmed.emit(loadout)
