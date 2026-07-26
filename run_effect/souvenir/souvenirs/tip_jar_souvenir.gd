extends Souvenir
class_name TipJarSouvenir

const GOLD_PER_COMBO := 2

func _init() -> void:
	display_name = "Tip Jar"
	description = "+%dg whenever you land a combo" % GOLD_PER_COMBO
	rarity = Souvenir.Rarity.UNCOMMON

## ctx.player rather than ctx.turn.combat.player — the context always carries
## the player directly, and the longer chain is null outside a live turn.
func on_combo_landed(_symbol: Symbol, ctx: ResolutionContext) -> void:
	ctx.player.gold += GOLD_PER_COMBO
