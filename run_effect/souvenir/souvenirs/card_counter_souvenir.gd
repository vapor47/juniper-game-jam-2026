extends Souvenir
class_name TipJarSouvenir

const GOLD_PER_COMBO := 2

func _init() -> void:
	display_name = "Tip Jar"
	description = "+%dg whenever you land a combo" % GOLD_PER_COMBO
	rarity = Souvenir.Rarity.UNCOMMON

func on_combo_landed(_symbol: SlotSymbol, ctx: ResolutionContext) -> void:
	ctx.combat.player.gold += GOLD_PER_COMBO
