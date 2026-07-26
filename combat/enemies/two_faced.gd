extends EnemyData
class_name TwoFacedData
## Alternates between charging and swinging. Each charge doubles the pending
## hit, so letting it build compounds fast.
##
## The coin is flipped when the intent is *chosen*, not when it resolves, so
## the result is telegraphed before the player commits (§10). An unseen coin
## makes blocking a blind guess, and the satisfice decision needs a known
## number to aim at.

const BASE_ATTACK_VAL: int = 8
## Charges compound, so without a ceiling a long streak becomes an unavoidable
## one-shot. Capped where three lines of block can still meaningfully bite.
const MAX_ATTACK_VAL: int = 32

var curr_attack_val: int = BASE_ATTACK_VAL


func _init() -> void:
	display_name = "Two Faced"
	max_health = 150
	health = max_health


func _choose_intent() -> void:
	# A swing spends the charge; the next cycle starts over.
	if intent.get("type") == "attack":
		curr_attack_val = BASE_ATTACK_VAL

	if randi() % 2 == 0:
		curr_attack_val = mini(curr_attack_val * 2, MAX_ATTACK_VAL)
		intent = { "type": "charge", "value": curr_attack_val }
		custom_intent_str = "Heads — charging (%d)" % curr_attack_val
	else:
		intent = { "type": "attack", "value": curr_attack_val }
		custom_intent_str = "Tails — attacking for %d" % curr_attack_val
