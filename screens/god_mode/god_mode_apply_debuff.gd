extends PanelContainer


@onready var debuff_option_button: OptionButton = %DebuffOptionButton

func _ready() -> void:
	for i in DebuffPool.ALL.size():
		var debuff_class: GDScript = DebuffPool.ALL[i]
		var temp: Debuff = debuff_class.new()
		debuff_option_button.add_item(temp.display_name, i)
		debuff_option_button.set_item_metadata(i, debuff_class)
	
func _apply_debuff(debuff: Debuff) -> void:
	Global.player.apply_debuff(debuff)

func _on_apply_debuff_button_pressed() -> void:
	var idx := debuff_option_button.selected
	_apply_debuff(debuff_option_button.get_item_metadata(idx).new())
