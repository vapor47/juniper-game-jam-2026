extends ProgressBar
class_name HealthBar
## Health, with block shown as a light blue segment on its right.
##
## The bar's width never changes; what changes is what a pixel is worth. The
## scale denominator is max(max_health, health + block), which gives both
## behaviours the same way:
##
##   - Hurt and lightly shielded, block fills into the gap the missing health
##     left. The bar is still scaled to max_health, so a point of health is the
##     same width it always was and the shield visibly plugs the hole.
##   - At full health, or shielded past max, there is no gap to fill, so the
##     denominator grows and health squeezes left to make room. A shield beyond
##     your maximum has to come from somewhere, and the honest thing is to show
##     the bar as over-full rather than clipping the surplus.
##
## ProgressBar does the squeezing for free: feeding it the denominator as
## max_value means its own fill is already health/denominator.

const BLOCK_COLOR := Color(0.55, 0.78, 0.96)

@onready var value_label: Label = $Label

var _max_health: int = 100
var _health: int = 100
var _block: int = 0

var _block_rect: ColorRect


func _ready() -> void:
	show_percentage = false

	_block_rect = ColorRect.new()
	_block_rect.color = BLOCK_COLOR
	_block_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_block_rect)
	# Behind the readout, in front of the fill.
	move_child(_block_rect, 0)
	if value_label != null:
		move_child(value_label, get_child_count() - 1)

	resized.connect(_refresh)
	_refresh()


func update_value(new_value: int) -> void:
	_health = new_value
	_refresh()


func update_max_value(new_value: int) -> void:
	_max_health = new_value
	_refresh()


func update_block(new_value: int) -> void:
	_block = new_value
	_refresh()


func _set_initial_values(max_hp: int, curr_hp: int = max_hp, blk: int = 0) -> void:
	_max_health = max_hp
	_health = curr_hp
	_block = blk
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return

	var denom: int = maxi(_max_health, _health + _block)
	denom = maxi(denom, 1)

	max_value = denom
	value = _health

	if _block_rect != null:
		var w: float = size.x
		var start: float = w * float(_health) / float(denom)
		_block_rect.position = Vector2(start, 0.0)
		_block_rect.size = Vector2(w * float(_block) / float(denom), size.y)
		_block_rect.visible = _block > 0

	_update_bar_text()


## Always the real maximum, never the scaling denominator — the denominator is
## a drawing detail and would read as the player's max health changing.
func _update_bar_text() -> void:
	if value_label == null:
		return
	if _block > 0:
		value_label.text = "%d / %d  +%d" % [_health, _max_health, _block]
	else:
		value_label.text = "%d / %d" % [_health, _max_health]


func setup(combatant: CombatantData) -> void:
	_set_initial_values(combatant.max_health, combatant.health, combatant.block)
	EventBus.curr_health_updated.connect(
		func(who: CombatantData, new_val: int) -> void:
			if who == combatant:
				update_value(new_val)
	)
	EventBus.max_health_updated.connect(
		func(who: CombatantData, new_val: int) -> void:
			if who == combatant:
				update_max_value(new_val)
	)
	EventBus.block_updated.connect(
		func(who: CombatantData, new_val: int) -> void:
			if who == combatant:
				update_block(new_val)
	)
