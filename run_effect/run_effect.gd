# run_effect.gd — the shared hook surface (renamed from "Charm" as base concept)
extends RefCounted
class_name RunEffect

enum Rarity { COMMON, UNCOMMON, RARE }

var display_name: String
var description: String
static var rarity: Rarity = Rarity.COMMON
var icon: Texture2D

@warning_ignore_start("unused_parameter")
# -- resolution hooks (called by SymbolResolver, mirrors StopModifier) --
func modify_stop_value(v: int, ctx: ResolutionContext, stop: ReelStop) -> int: return v
func modify_result_total(total: int, type: CombatManager.Action.Type, ctx: ResolutionContext) -> int: return total
func combo_count_bonus() -> int: return 0

# -- lifecycle hooks (called by CombatManager/RunManager at the right seams) --
func on_acquired() -> void: pass
func on_combat_started(ctx: CombatContext) -> void: pass
func on_player_turn_started(ctx: CombatContext) -> void: pass
func on_turn_ended(ctx: CombatContext) -> void: pass
func on_combo_landed(symbol: SlotSymbol, ctx: ResolutionContext) -> void: pass
func on_combat_ended(result, ctx: CombatContext) -> void: pass

# -- economy --
func modify_shop_price(price: int, item: ShopItemData) -> int: return price

# -- lifetime --
func is_expired() -> bool: return false   # charms: never; drinks: after their combat

static func get_rarity() -> Rarity:
	return rarity
"""
Effect Ideas (map these to whatever drinks/charms feel best):
	- Gain gold if all flat values are 7 ( might be too rare )
	- +X to all results
	- *X to all results
	- Reduce damage taken
	- Loan
	- Gain flat gold
	- Flat/Mult Additional gold at end of combat
	- Wagers:
		- goals are easier
		- cons not as bad
		- more/less common
		- rewards are better
		- wager reroll
	- shop prices reduced
	- next item is free
	- enemies have reduced health
	- enemies get debuff on combat start
	- player get buff on combat start
	- player get effect every turn (buff, block, heal, etc)
	- enemy get effect every turn (debuff or damage)
	- Temporary additional tokens (cap, regen)
	- heal health
	- (turn stat upgrades into drinks instead? then need some way to track them in case we go backwards via wagers or events)

Charm ideas by hook point
A. Resolution hooks (global versions of modifier hooks)

Card Counter — combos count as +1 symbol (global Matching Cufflinks; stacks with it multiplicatively in feel — probably rare)
High Roller — all attack values +2, all heal values −1 (pro/con, Comps preview)
Loaded Table — final damage ×1.15
Insurance Policy — if your confirmed action total is under 10, add +8 (floor for bad turns; anti-frustration with a build angle)
Lucky Sevens — if your selected total equals exactly 7/17/27..., triple it (pure slots flavor, warps selection math deliciously)

B. Turn-lifecycle hooks

Morning Coffee — +1 token on the first turn of each combat
Momentum — land a combo → next turn's first respin is free
Patience — end turn with unspent tokens → +2 to next turn's first action

C. Spin/hold hooks

Steady Hands — first hold each turn doesn't count against hold limits / is free (whatever your hold economy ends up charging)
Second Wind — once per combat, your first respin refunds itself

D. Economy hooks

Tip Jar — +2g whenever you land any combo
Frequent Flyer — shop prices −10%
Golden Horseshoe — +1g per unspent token at combat end (global version of the Interest modifier idea)

E. Combat-lifecycle hooks

Rabbit's Foot — start each combat with 5 block
Last Call — surviving a hit that would've killed you: once per run, survive at 1 HP (passive Comp'd Suite; maybe too much overlap with the shop item — flag)
House Rules — enemies telegraph one extra turn ahead (information as a charm!)

F. Comps (pro/con, future tier — noting the pattern works in this architecture)

Marked Cards — combos +1 symbol, but shop prices +25%
Borrowed Luck — +3 all values, lose 2g per turn
"""
