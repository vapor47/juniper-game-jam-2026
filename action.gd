extends RefCounted
class_name Action

## GOLD and TOKEN let economy symbols ride the same run/combo/popup machinery
## as combat ones — a run of Coins pays more gold for free.
enum Type { NONE, ATTACK, DEFEND, HEAL, GOLD, TOKEN }

var type: Type
var value: int
var display_string: String

func _init(p_type: Type, p_value: int, p_display_string: String) -> void:
	type = p_type
	value = p_value
	display_string = p_display_string
