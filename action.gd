extends RefCounted
class_name Action

## GOLD and TOKEN let economy symbols ride the same run/combo/popup machinery
## as combat ones — a run of Coins pays more gold for free.
enum Type { NONE, ATTACK, DEFEND, HEAL, GOLD, TOKEN }

## Types that resolve inside the fight's own economy — the pot being played
## for. Everything else (gold, tokens) is currency that outlives the combat, and
## effects that skim the pot should leave it alone.
##
## Note this is not quite "affects both parties": heal only ever touches the
## player. The line that actually holds is whether the value is spent inside
## this fight or carried out of it. Bleed, poison and anything similar belong
## in here when they land.
const COMBAT_TYPES: Array[Type] = [Type.ATTACK, Type.DEFEND, Type.HEAL]


static func is_combat(t: Type) -> bool:
	return t in COMBAT_TYPES


var type: Type
var value: int
var display_string: String

func _init(p_type: Type, p_value: int, p_display_string: String) -> void:
	type = p_type
	value = p_value
	display_string = p_display_string
