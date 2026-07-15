extends VBoxContainer

var reel: Reel
var amount: int
var is_actionable: bool = true

func setup(reel_name: String, p_amount: int) -> void:
	amount = p_amount
	reel = Global.reels[reel_name]
	
	if !reel:
		push_error("Null reel on inventory item setup")
		
	$Label.text = reel.reel_name + " x" + str(amount)
	tooltip_text = reel.description
	$Button.icon = reel.icon


func _on_button_pressed() -> void:
	if get_tree().current_scene.slot_to_swap:
		#print_debug("emitting reel_swapped")
		EventBus.inventory_reel_pressed.emit(reel)
	
#	Otherwise do...? What happens when we click on a reel inventory item in a non swap context
