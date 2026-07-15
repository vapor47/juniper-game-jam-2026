extends Button
class_name LoadoutSelectInventoryItem

signal loadout_inventory_item_selected(reel: Reel)

@onready var quantity_label: Label = %QuantityLabel

const ITEM_SCENE = preload("res://combat/loadout/loadout_select_inventory_item.tscn")

var reel: Reel
var quantity: int = 0:
	set(new_value):
		if new_value < 0:
			push_error("LOADOUT SELECT: Attempted to insert more reels than available")
		quantity = new_value
		if is_node_ready():
			quantity_label.text = "x%d" % new_value

func _ready() -> void:
	quantity_label.text = "x%d" % quantity
	tooltip_text = reel.reel_name + " Reel"

func _on_pressed() -> void:
	loadout_inventory_item_selected.emit(reel)

static func create(p_reel: Reel, p_quantity: int) -> LoadoutSelectInventoryItem:
	var item := ITEM_SCENE.instantiate()
	item.quantity = p_quantity
	item.icon = p_reel.icon
	item.reel = p_reel
	return item
