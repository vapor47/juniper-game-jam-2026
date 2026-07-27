extends CurseSymbolDebuff
class_name ReelJamDebuff
## Freezes any column it shows in until the next spin.
##
## Deliberately never scales. One copy already jams at least one column on 54%
## of spins; at three copies that is 88%, averaging 1.8 of 5 columns frozen,
## with a total lockout every ~158 spins. Extra copies stop making the fight
## harder and start making the board inert, so The Cooler is not allowed to
## deepen this one.

func _init() -> void:
	super(SymbolTable.REEL_JAM)
	refresh_text()


func can_deepen() -> bool:
	return false


func describe() -> String:
	return "Columns showing it cannot be respun (%d on your reel)" % copies()
