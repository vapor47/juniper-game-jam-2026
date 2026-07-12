class_name ModifierPool
## Central registry of purchasable modifiers. Factories, not instances —
## each shop offer constructs a FRESH modifier (stateful mods like Ramping
## must never share instances across stops).

## rarity -> array of zero-arg factory Callables
static var _pool: Dictionary = {
	StopModifier.Rarity.COMMON: [
		func() -> StopModifier: return PolishedModifier.new(2),
		func() -> StopModifier: return PolishedModifier.new(4),   # Gilded
		func() -> StopModifier: return WeightedPayoutModifier.new(),
	],
	StopModifier.Rarity.UNCOMMON: [
		func() -> StopModifier: return BeginnersLuckModifier.new(),
		func() -> StopModifier: return HouseCreditModifier.new(),
		func() -> StopModifier: return GoodNeighborModifier.new(),
	],
	StopModifier.Rarity.RARE: [
		func() -> StopModifier: return LoadedDiceModifier.new(),
		func() -> StopModifier: return MatchingCufflinksModifier.new(),
	],
}

const RARITY_WEIGHTS := {
	StopModifier.Rarity.COMMON: 0.60,
	StopModifier.Rarity.UNCOMMON: 0.30,
	StopModifier.Rarity.RARE: 0.10,
}


static func roll(count: int) -> Array[StopModifier]:
	var out: Array[StopModifier] = []
	for i in count:
		out.append(_pool[_roll_rarity()].pick_random().call())
	return out


static func _roll_rarity() -> StopModifier.Rarity:
	var r := randf()
	var cumulative := 0.0
	for rarity: StopModifier.Rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if r <= cumulative:
			return rarity
	return StopModifier.Rarity.COMMON
