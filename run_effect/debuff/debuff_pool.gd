extends RefCounted
class_name DebuffPool

const ALL: Array = [
	preload("res://run_effect/debuff/debuffs/decrease_line_cap_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/decrease_token_regen_debuff.gd"),
]

static func get_random_debuff() -> Debuff:
	return ALL.pick_random().new()
