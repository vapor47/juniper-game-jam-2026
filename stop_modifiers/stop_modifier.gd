extends RefCounted
class_name StopModifier
## Base for all stop modifiers. Subclasses override the hooks they care about.
## Modifiers are stateless where possible; per-stop state (e.g. Ramping) is OK
## since each StopModifier instance is owned by exactly one ReelStop.

"""
What is required for a modifier?

Some overlay texture
some effect that it has on Stop
What possible effects?
- Modify stop value by flat amount (OP for multiplys)
- Modify Total value (e.g. +X or *X to final result)
- Increase odds of spinning to stop?
- Amplify combos including stop
- gain gold
- if only stop with modifier selected, big bonus

can also be debuffs applied by enemy
- Minus tokens
- Temp decrease token regen
- lose gold

"""
enum Rarity { COMMON, UNCOMMON, RARE }

var display_name: String = "Modifier"
var description: String = ""
var rarity: Rarity = Rarity.COMMON
var overlay_icon: Texture2D = null


## Can this modifier be applied to the given stop? Checked by the shop/edit flow.
func can_apply(stop: ReelStop) -> bool:
	return true


## HOOK A — modify this stop's own contributed value.
## Called once per resolution for the stop this modifier is attached to.
func modify_stop_value(base_value: int, ctx: ResolutionContext, stop: ReelStop) -> int:
	return base_value


## HOOK B — modify the final result total (runs after all stop values + combos).
## Called only if this modifier's stop was selected.
func modify_result_total(total: int, ctx: ResolutionContext, stop: ReelStop) -> int:
	return total


## HOOK C — combo participation. Read by SymbolResolver during combo counting.
func combo_count_bonus() -> int:
	return 0


## HOOK D — side effects after resolution (gold, tokens, healing...).
## Called only if this modifier's stop was selected.
func on_resolved(ctx: ResolutionContext, stop: ReelStop) -> void:
	pass


## HOOK E — fired when this stop's slot is respun away (stop was showing, got rerolled).
func on_spun_away(ctx: ResolutionContext, stop: ReelStop) -> void:
	pass
