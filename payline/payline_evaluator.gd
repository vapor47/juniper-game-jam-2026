extends RefCounted
class_name PaylineEvaluator
## Reads paylines off the board and combines them.
##
## Double-dip (§4): a cell on two purchased lines pays into both, so lines
## score independently and simply sum.


static func stops_for(payline: Payline, columns: Array[ReelColumn]) -> Array[Stop]:
	var stops: Array[Stop] = []
	for col in mini(payline.pattern.size(), columns.size()):
		stops.append(columns[col].get_stop_at_row(payline.row_at(col)))
	return stops


static func score_for(payline: Payline, columns: Array[ReelColumn],
		ctx: ResolutionContext = null) -> PaylineScorer.LineResult:
	return PaylineScorer.score_line(stops_for(payline, columns), ctx)


## Combined actions across every purchased line, line by line in purchase
## order (each line's runs stay in left-to-right board order within it).
## Resolution path: scores every purchased line with the real context and
## fires each line's side effects. Previews must never call this.
static func resolve(lines: Array[Payline], columns: Array[ReelColumn],
		ctx: ResolutionContext) -> Array[Action]:
	var actions: Array[Action] = []
	for line: Payline in lines:
		var stops := stops_for(line, columns)
		var result := PaylineScorer.score_line(stops, ctx)
		PaylineScorer.apply_side_effects(result, stops, ctx)
		actions.append_array(result.to_actions())
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


## Total incoming damage the enemies have telegraphed for this turn (§10).
## The payline readout deliberately does *not* use this — it states what the
## lines pay and leaves weighing that against the hit to the player. Kept
## because the satisfice decision is still the point; block overflow really is
## wasted, it just isn't spelled out in the UI.
static func incoming_damage(enemies: Array[EnemyData]) -> int:
	var total := 0
	for enemy: EnemyData in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.intent.get("type") == "attack":
			total += int(enemy.intent.get("value", 0))
	return total
