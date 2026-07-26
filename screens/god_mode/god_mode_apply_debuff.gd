extends PanelContainer


@onready var debuff_option_button: OptionButton = %DebuffOptionButton

func _ready() -> void:
	for i in DebuffPool.ALL.size():
		var debuff_class: GDScript = DebuffPool.ALL[i]
		var temp: Debuff = debuff_class.new()
		debuff_option_button.add_item(temp.display_name, i)
		debuff_option_button.set_item_metadata(i, debuff_class)
	
## Respects can_apply even here — forcing one that clamps to no change would
## leave the player better off when it expires.
func _apply_debuff(debuff: Debuff) -> void:
	if debuff.can_apply(Global.player):
		Global.player.apply_debuff(debuff)
	else:
		push_warning("%s cannot apply to the player right now." % debuff.display_name)

func _on_apply_debuff_button_pressed() -> void:
	var idx := debuff_option_button.selected
	_apply_debuff(debuff_option_button.get_item_metadata(idx).new())
