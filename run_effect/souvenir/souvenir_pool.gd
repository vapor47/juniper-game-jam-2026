class_name SouvenirPool

static var ENTRIES := [
	{ "souvenir": LoyaltyCardSouvenir,   "rarity": Souvenir.Rarity.COMMON },
	{ "souvenir": RabbitsFootSouvenir,   "rarity": Souvenir.Rarity.COMMON },
	{ "souvenir": MorningCoffeeSouvenir, "rarity": Souvenir.Rarity.COMMON },
	{ "souvenir": HealthSouvenir,        "rarity": Souvenir.Rarity.COMMON },
	{ "souvenir": TipJarSouvenir,        "rarity": Souvenir.Rarity.UNCOMMON },
	{ "souvenir": FrequentFlyerSouvenir, "rarity": Souvenir.Rarity.UNCOMMON },
	{ "souvenir": CardCounterSouvenir,   "rarity": Souvenir.Rarity.RARE },
]

static var RARITY_WEIGHTS := {
	Souvenir.Rarity.COMMON: 0.60,
	Souvenir.Rarity.UNCOMMON: 0.30,
	Souvenir.Rarity.RARE: 0.10,
}


## Distinct souvenirs, and never one the player already owns — each is a
## permanent one-of, so offering a duplicate would be offering nothing.
static func roll(count: int) -> Array[Souvenir]:
	var available := ENTRIES.filter(
			func(e: Dictionary) -> bool:
				return Global.player == null or not Global.player.owns_souvenir(e["souvenir"]))

	var out: Array[Souvenir] = []
	for entry in PoolRoller.draw(available, count, RARITY_WEIGHTS,
			func(e: Dictionary) -> int: return e["rarity"]):
		out.append(entry["souvenir"].new())
	return out
