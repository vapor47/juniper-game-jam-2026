extends RefCounted
class_name PoolRoller
## Shared rarity rolling for the shop pools.
##
## Rolls among the rarities that still have something to give, with the
## weights renormalised across those tiers. Rolling a rarity first and then
## discovering it's empty would silently drop the slot — that's how the shop
## used to hand back fewer drinks than it asked for. Here an exhausted tier
## simply can't be rolled, so every draw makes progress and the loop ends only
## when the pool itself runs out.


## `entries` is any array; `rarity_of` maps an entry to its rarity. Returns up
## to `count` distinct entries — never the same one twice.
static func draw(entries: Array, count: int, weights: Dictionary,
		rarity_of: Callable) -> Array:
	var remaining := entries.duplicate()
	var out: Array = []

	while out.size() < count and not remaining.is_empty():
		var by_rarity := {}
		for entry in remaining:
			var r: int = rarity_of.call(entry)
			if not by_rarity.has(r):
				by_rarity[r] = []
			by_rarity[r].append(entry)

		var rarity := _pick_rarity(by_rarity, weights)
		var chosen = (by_rarity[rarity] as Array).pick_random()
		remaining.erase(chosen)
		out.append(chosen)

	return out


## Weighted pick across only the rarities present in `by_rarity`.
static func _pick_rarity(by_rarity: Dictionary, weights: Dictionary) -> int:
	var total := 0.0
	for rarity: int in by_rarity:
		total += float(weights.get(rarity, 0.0))

	# Every present tier has zero weight (or none configured) — fall back to
	# uniform so the draw still resolves rather than biasing to one tier.
	if total <= 0.0:
		return (by_rarity.keys() as Array).pick_random()

	var roll := randf() * total
	var cumulative := 0.0
	for rarity: int in by_rarity:
		cumulative += float(weights.get(rarity, 0.0))
		if roll <= cumulative:
			return rarity
	return by_rarity.keys()[-1]
