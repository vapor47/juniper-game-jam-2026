extends RefCounted
class_name PaylineEvaluator
## Reads paylines off the board and combines them.
##
## Double-dip (§4): a cell on two purchased lines pays into both, so lines
## score independently and simply sum. That makes marginal ATK identical to
## standalone ATK — damage is unbounded.
##
## Block is the exception, and the reason §9 insists on *marginal* previews:
## block is capped by the intent number and overflow is wasted (§10), so a
## second block-heavy line can be worth far less than it looks, or nothing.


static func stops_for(payline: Payline, columns: Array[ReelColumn]) -> Array[Stop]:
	var stops: Array[Stop] = []
	for col in mini(payline.pattern.size(), columns.size()):
		stops.append(columns[col].get_stop_at_row(payline.row_at(col)))
	return stops


static func score_for(payline: Payline, columns: Array[ReelColumn]) -> PaylineScorer.LineResult:
	return PaylineScorer.score_line(stops_for(payline, columns))


## Combined actions across every purchased line, line by line in purchase
## order (each line's runs stay in left-to-right board order within it).
static func combined_actions(lines: Array[Payline], columns: Array[ReelColumn]) -> Array[Action]:
	var actions: Array[Action] = []
	for line: Payline in lines:
		actions.append_array(score_for(line, columns).to_actions())
	return actions


static func total_block(lines: Array[Payline], columns: Array[ReelColumn]) -> int:
	var sum := 0
	for line: Payline in lines:
		sum += score_for(line, columns).block
	return sum


static func total_attack(lines: Array[Payline], columns: Array[ReelColumn]) -> int:
	var sum := 0
	for line: Payline in lines:
		sum += score_for(line, columns).attack
	return sum


## Block that actually lands, given the hit it has to cover. Overflow is wasted.
static func effective_block(block: int, incoming: int) -> int:
	if incoming <= 0:
		return 0
	return mini(block, incoming)


## What adding `candidate` is really worth on top of `already_selected`.
## Attack is additive; block is only worth what isn't already covered.
static func marginal_block(candidate: Payline, already_selected: Array[Payline],
		columns: Array[ReelColumn], incoming: int) -> int:
	var current := total_block(already_selected, columns)
	var with_candidate := current + score_for(candidate, columns).block
	return effective_block(with_candidate, incoming) - effective_block(current, incoming)


## Total incoming damage the enemies have telegraphed for this turn (§10) —
## the number block satisfices against.
static func incoming_damage(enemies: Array[EnemyData]) -> int:
	var total := 0
	for enemy: EnemyData in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.intent.get("type") == "attack":
			total += int(enemy.intent.get("value", 0))
	return total
