# charm_pool.gd
class_name CharmPool

static var CHARMS: Array[GDScript] = [
	RabbitsFootCharm,
	MorningCoffeeCharm,
	TipJarCharm,
	FrequentFlyerCharm,
	CardCounterCharm,
]

const RARITY_WEIGHTS := {
	Charm.Rarity.COMMON: 0.60,
	Charm.Rarity.UNCOMMON: 0.30,
	Charm.Rarity.RARE: 0.10,
}


static func roll(count: int) -> Array[Charm]:
	var out: Array[Charm] = []
	for i in count:
		var rarity := _roll_rarity()
		var matches := CHARMS.filter(func(c: GDScript) -> bool:
			return c.get_rarity() == rarity)
		if matches.is_empty():
			continue
		out.append(matches.pick_random().new())
	return out


static func _roll_rarity() -> RunEffect.Rarity:
	var r := randf()
	var cumulative := 0.0
	for rarity: RunEffect.Rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if r <= cumulative:
			return rarity
	return RunEffect.Rarity.COMMON
