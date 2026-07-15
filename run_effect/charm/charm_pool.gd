# charm_pool.gd
class_name CharmPool

enum Rarity { COMMON, UNCOMMON, RARE }

static var ENTRIES := [
	{ "charm": RabbitsFootCharm,   "rarity": Rarity.COMMON },
	{ "charm": MorningCoffeeCharm, "rarity": Rarity.COMMON },
	{ "charm": TipJarCharm,        "rarity": Rarity.UNCOMMON },
	{ "charm": FrequentFlyerCharm, "rarity": Rarity.UNCOMMON },
	{ "charm": CardCounterCharm,   "rarity": Rarity.RARE },
]

static var RARITY_WEIGHTS := {
	Rarity.COMMON: 0.60,
	Rarity.UNCOMMON: 0.30,
	Rarity.RARE: 0.10,
}

static func roll(count: int) -> Array[Charm]:
	var out: Array[Charm] = []
	for i in count:
		var rarity := _roll_rarity()
		var matches := ENTRIES.filter(func(e): return e["rarity"] == rarity)
		if matches.is_empty():
			continue
		out.append(matches.pick_random()["charm"].new())
	return out

static func _roll_rarity() -> Rarity:
	var r := randf()
	var cumulative := 0.0
	for rarity: Rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if r <= cumulative:
			return rarity
	return Rarity.COMMON
