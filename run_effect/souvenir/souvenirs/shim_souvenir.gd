extends Souvenir
class_name ShimSouvenir
## Lets the player push a column one stop instead of rerolling it.
##
## Nudging is the only verb that acts on strip *order* rather than composition.
## Order is what the Reel Preview shows and what the shop's insert-vs-replace
## choice decides, and until now nothing in a fight could act on either — a
## player who studied their reel got no way to spend that knowledge.
##
## It is deliberately scarce rather than priced, at least to begin with. A nudge
## is precise where a respin is a gamble, so an unlimited one would flatten the
## respin decision into "line it up." Three a combat forces the question to be
## *when*, which is the interesting version.

const CHARGES := 3

var charges: int = CHARGES


func _init() -> void:
	display_name = "The Shim"
	description = "Nudge a column one stop, %d times each combat" % CHARGES
	rarity = Souvenir.Rarity.RARE


func on_combat_started(_ctx: CombatContext) -> void:
	charges = CHARGES
