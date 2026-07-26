class_name DrinkPool

static var ENTRIES := [
	{ "drink": OldFashionedDrink, "rarity": Drink.Rarity.COMMON },
	{ "drink": TheEncoreDrink, "rarity": Drink.Rarity.COMMON },
	{ "drink": RetailTherapyDrink, "rarity": Drink.Rarity.COMMON },
	{ "drink": DasBootDrink, "rarity": Drink.Rarity.UNCOMMON },
]

const RARITY_WEIGHTS := {
	Drink.Rarity.COMMON: 0.60,
	Drink.Rarity.UNCOMMON: 0.30,
	Drink.Rarity.RARE: 0.10,
}


## Distinct drinks — the bar never stocks the same bottle twice in one visit.
static func roll(count: int) -> Array[Drink]:
	var out: Array[Drink] = []
	for entry in PoolRoller.draw(ENTRIES, count, RARITY_WEIGHTS,
			func(e: Dictionary) -> int: return e["rarity"]):
		out.append(entry["drink"].new())
	return out
