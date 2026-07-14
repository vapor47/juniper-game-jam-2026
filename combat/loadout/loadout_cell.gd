extends Button
class_name LoadoutCell

signal loadout_cell_pressed(cell: LoadoutCell)

var reel: Reel:
	set(new_reel):
		reel = new_reel
		#update ui
		if reel:
			icon = reel.icon
		else:
			icon = null

func _on_pressed() -> void:
	loadout_cell_pressed.emit(self)

func insert(p_reel: Reel) -> Reel:
	var old_reel := reel
	reel = p_reel
	return old_reel
