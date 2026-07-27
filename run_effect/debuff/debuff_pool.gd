extends RefCounted
class_name DebuffPool

const ALL: Array = [
	preload("res://run_effect/debuff/debuffs/decrease_line_cap_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/decrease_token_regen_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/live_wire_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/marked_card_debuff.gd"),
	preload("res://run_effect/debuff/debuffs/cold_deck_debuff.gd"),
]


## Only debuffs that would actually bite the given player. Returns null when
## none would — the caller should treat that as "got away with it" rather than
## forcing a debuff that does nothing.
static func get_random_debuff(player: PlayerData) -> Debuff:
	var candidates: Array[Debuff] = []
	for script in ALL:
		var debuff: Debuff = script.new()
		if debuff.can_apply(player):
			candidates.append(debuff)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
