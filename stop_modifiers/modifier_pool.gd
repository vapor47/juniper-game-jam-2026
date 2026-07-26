class_name ModifierPool
## Central registry of purchasable modifiers. Factories, not instances —
## each shop offer constructs a FRESH modifier (stateful mods like Ramping
## must never share instances across stops).

static var ENTRIES := [
	{ "make": func() -> StopModifier: return PolishedModifier.new(2),
	  "rarity": StopModifier.Rarity.COMMON },
	{ "make": func() -> StopModifier: return PolishedModifier.new(4),   # Gilded
	  "rarity": StopModifier.Rarity.COMMON },
	{ "make": func() -> StopModifier: return WeightedPayoutModifier.new(),
	  "rarity": StopModifier.Rarity.COMMON },
	{ "make": func() -> StopModifier: return BeginnersLuckModifier.new(),
	  "rarity": StopModifier.Rarity.UNCOMMON },
	{ "make": func() -> StopModifier: return HouseCreditModifier.new(),
	  "rarity": StopModifier.Rarity.UNCOMMON },
	{ "make": func() -> StopModifier: return GoodNeighborModifier.new(),
	  "rarity": StopModifier.Rarity.UNCOMMON },
	{ "make": func() -> StopModifier: return LoadedDiceModifier.new(),
	  "rarity": StopModifier.Rarity.RARE },
	{ "make": func() -> StopModifier: return MatchingCufflinksModifier.new(),
	  "rarity": StopModifier.Rarity.RARE },
]

const RARITY_WEIGHTS := {
	StopModifier.Rarity.COMMON: 0.60,
	StopModifier.Rarity.UNCOMMON: 0.30,
	StopModifier.Rarity.RARE: 0.10,
}


## Distinct modifiers — the same one is never offered twice in a visit.
## Polished and Gilded are separate entries, so both can appear.
##
## Rarity is stamped on from the entry rather than set inside each modifier:
## none of them declared one, so every modifier defaulted to COMMON and priced
## the same regardless of tier. The pool is the one place that knows.
static func roll(count: int) -> Array[StopModifier]:
	var out: Array[StopModifier] = []
	for entry in PoolRoller.draw(ENTRIES, count, RARITY_WEIGHTS,
			func(e: Dictionary) -> int: return e["rarity"]):
		var modifier: StopModifier = (entry["make"] as Callable).call()
		modifier.rarity = entry["rarity"]
		out.append(modifier)
	return out
