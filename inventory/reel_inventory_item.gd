extends VBoxContainer

var reel_data: Dictionary = {}
var amount: int
var is_actionable: bool = true

func setup(data: Dictionary) -> void:
	reel_data = data
	
	var reel_name = data["reel_name"]
	amount = data["amount"]
	var reel = data["reel"]
	
	if !reel:
		push_error("Null reel on inventory item setup")
		
	$Label.text = reel.reel_name + " x" + str(amount)
	tooltip_text = reel.description
	$Button.icon = reel.icon
