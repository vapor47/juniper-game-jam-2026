class_name DrinkPool

enum Rarity { COMMON, UNCOMMON, RARE }

static var ENTRIES := [
	{ "drink": OldFashionedDrink, "rarity": Rarity.COMMON },
	{ "drink": TheEncoreDrink, "rarity": Rarity.COMMON },
]

const RARITY_WEIGHTS := {
	Charm.Rarity.COMMON: 0.60,
	Charm.Rarity.UNCOMMON: 0.30,
	Charm.Rarity.RARE: 0.10,
}

static func roll(count: int) -> Array[Drink]:
	var out: Array[Drink] = []
	for i in count:
		var rarity := _roll_rarity()
		var matches := ENTRIES.filter(func(e): return e["rarity"] == rarity)
		if matches.is_empty():
			continue
		out.append(matches.pick_random()["drink"].new())
	return out

static func _roll_rarity() -> Rarity:
	#var r := randf()
	#var cumulative := 0.0
	#for rarity: Rarity in RARITY_WEIGHTS:
		#cumulative += RARITY_WEIGHTS[rarity]
		#if r <= cumulative:
			#return rarity
	return Rarity.COMMON
