extends EnemyData
class_name TwoFacedData
## Doubles down. On heads it cuts itself to double the pending hit; on tails it
## swings for whatever it has built up.
##
## The self-harm is what makes the fight a decision rather than a wait: the
## threat visibly costs it health, so racing it down and letting it bleed are
## both live plays. Blocking still aims at a known number — the coin is flipped
## when the intent is chosen, not when it resolves, so everything is telegraphed
## before the player commits (§10).

const BASE_ATTACK_VAL: int = 8
## Charges compound, so without a ceiling a long streak becomes an unavoidable
## one-shot. Capped where a couple of lines of block can still bite.
const MAX_ATTACK_VAL: int = 32
## What a charge costs it. A round number so the HP drop is easy to read at a
## glance while the fight is moving.
const SELF_DAMAGE: int = 10

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
		var bled := take_true_damage(SELF_DAMAGE)
		intent = { "type": "charge", "value": curr_attack_val }
		custom_intent_str = "Heads — bleeds %d, charging (%d)" % [bled, curr_attack_val]
	else:
		intent = { "type": "attack", "value": curr_attack_val }
		custom_intent_str = "Tails — attacking for %d" % curr_attack_val
