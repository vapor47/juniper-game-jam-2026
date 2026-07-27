extends Debuff
class_name ColdDeckDebuff
## Locks out whatever lines were played last turn, so a good pattern cannot
## simply be replayed.
##
## Needs at least two owned lines to exist at all. With one, it would lock the
## only line the player has and brick the turn outright — the same failure the
## line-cap debuff had before it learned to check.

func _init() -> void:
	display_name = "Cold Deck"
	description = "Lines you played last turn are unavailable"
	rarity = RunEffect.Rarity.UNCOMMON


func can_apply(player: PlayerData) -> bool:
	return player.owned_paylines.size() >= 2
