extends Button
class_name LoadoutCell

signal loadout_cell_pressed(cell: LoadoutCell)

## Styling
const LOADOUT_CELL_SIZE := 128
static var _normal_style: StyleBoxFlat
static var _hover_style: StyleBoxFlat

static func _get_styles() -> Dictionary:
	if not _normal_style:
		_normal_style = StyleBoxFlat.new()
		_normal_style.bg_color = Color(0.15, 0.15, 0.15)
		_normal_style.border_color = Color(0.4, 0.4, 0.4)
		_normal_style.set_border_width_all(4)
		_normal_style.set_corner_radius_all(16)

		_hover_style = _normal_style.duplicate() as StyleBoxFlat
		_hover_style.border_color = Color.GOLD
	return { "normal": _normal_style, "hover": _hover_style }

var reel: Reel:
	set(new_reel):
		reel = new_reel
		#update ui
		if reel:
			icon = reel.icon
		else:
			icon = null

func _ready() -> void:
	custom_minimum_size = Vector2(LOADOUT_CELL_SIZE, LOADOUT_CELL_SIZE)
	expand_icon = true
	var styles := _get_styles()
	for state: String in styles:
		add_theme_stylebox_override(state, styles[state])
	HoverLabel.attach_to(self, func() -> String: return reel.reel_name if reel else "")

func _on_pressed() -> void:
	loadout_cell_pressed.emit(self)

func insert(p_reel: Reel) -> Reel:
	var old_reel := reel
	reel = p_reel
	return old_reel
