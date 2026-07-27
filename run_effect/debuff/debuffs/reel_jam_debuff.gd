extends CurseSymbolDebuff
class_name ReelJamDebuff
## Freezes any column it shows in until the next spin.
##
## Scales by copies only, capped at three. There is nothing for a level to do —
## a column is frozen or it is not. Measured over 400k spins, one copy jams at
## least one column on 54% of them (0.71 of 5 on average), three copies on 88%
## (1.78 of 5). Past three the board stops being a puzzle and starts being
## inert, and total lockouts get common enough to matter.

const MAX_COPIES := 3


func _init() -> void:
	super(SymbolTable.REEL_JAM)
	refresh_text()


## Nothing for a level to raise: a column is frozen or it is not.
func can_upgrade() -> bool:
	return false


func can_add_copy() -> bool:
	return copies() < MAX_COPIES


func describe() -> String:
	return "Columns showing it cannot be respun (%d on your reel)" % copies()
