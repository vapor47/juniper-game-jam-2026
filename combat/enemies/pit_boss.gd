extends EnemyData
class_name PitBossData
## The run's closer. A clock rather than a wall: the hit grows every turn, so
## the fight is a race between your output and the point where its swing
## outruns what a line can block.
##
## Was a flat 100 against the player's 100 max HP — an unavoidable one-shot on
## turn one, behind 1000 HP that could never be burned down first.
##
## A steep clock: the swing passes what any single line can block within a few
## turns, so this is a damage race that punishes arriving hurt. Balanced
## against a player with upgrades, extra patterns and multi-line — none of
## which the single-line model used elsewhere in this file's history accounts
## for.

const BASE_DAMAGE: int = 10
const ESCALATION: int = 4

var swings_taken: int = 0


func _init() -> void:
	display_name = "The Pit Boss"
	max_health = 200
	health = max_health


func _choose_intent() -> void:
	var damage := BASE_DAMAGE + ESCALATION * swings_taken
	swings_taken += 1
	intent = { "type": "attack", "value": damage }
