# souvenir_pool.gd
class_name SouvenirPool

enum Rarity { COMMON, UNCOMMON, RARE }

static var ENTRIES := [
	{ "souvenir": LoyaltyCardSouvenir,   "rarity": Rarity.COMMON },
	{ "souvenir": RabbitsFootSouvenir,   "rarity": Rarity.COMMON },
	{ "souvenir": MorningCoffeeSouvenir, "rarity": Rarity.COMMON },
	{ "souvenir": TipJarSouvenir,        "rarity": Rarity.UNCOMMON },
	{ "souvenir": FrequentFlyerSouvenir, "rarity": Rarity.UNCOMMON },
	{ "souvenir": CardCounterSouvenir,   "rarity": Rarity.RARE },
]

static var RARITY_WEIGHTS := {
	Rarity.COMMON: 0.60,
	Rarity.UNCOMMON: 0.30,
	Rarity.RARE: 0.10,
}

static func roll(count: int) -> Array[Souvenir]:
	var out: Array[Souvenir] = []
	for i in count:
		var rarity := _roll_rarity()
		var matches := ENTRIES.filter(func(e): return e["rarity"] == rarity)
		if matches.is_empty():
			continue
		out.append(matches.pick_random()["souvenir"].new())
	return out

static func _roll_rarity() -> Rarity:
	var r := randf()
	var cumulative := 0.0
	for rarity: Rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if r <= cumulative:
			return rarity
	return Rarity.COMMON
