extends Debuff
class_name CoverChargeDebuff
## The first line of the turn stops being free.
##
## Replaces Seeing Double, which cut the per-turn line cap. That only bit on a
## turn where the player could already afford three lines — nine tokens against
## a baseline income of one a turn — so for most players it was a punishment
## they never felt. This charges for the thing everyone does every turn.
##
## Deliberately affordable rather than crippling: combats open with three tokens
## and regen one a turn, so this costs the turn's respin, not the turn. Three
## turns, on the turn clock, so it is a squeeze and not a sentence.

const CHARGE: int = 1
const DURATION_TURNS: int = 3


func _init() -> void:
	display_name = "Cover Charge"
	description = "Your first payline costs %d token for %d turns" % [CHARGE, DURATION_TURNS]
	turns_remaining = DURATION_TURNS


func modify_line_cost(cost: int, index: int) -> int:
	return cost + CHARGE if index == 0 else cost
