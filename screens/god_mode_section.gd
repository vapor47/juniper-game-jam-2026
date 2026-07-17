extends PanelContainer


@onready var amount_input: SpinBox = %AmountInput
@onready var entity_option_button: OptionButton = %EntityOptionButton

func _ready() -> void:
	entity_option_button.add_item("Enemy", 0)
	entity_option_button.add_item("Player", 1)
	self.visibility_changed.connect(
		func() -> void:
			if self.visible:
				if SceneManager.in_combat() and SceneManager._curr_combat.enemies:
					entity_option_button.set_item_metadata(0, SceneManager._curr_combat.enemies[0])
					entity_option_button.set_item_disabled(0, false)
				else:
					entity_option_button.set_item_disabled(0, true)
				entity_option_button.set_item_metadata(1, Global.player)
	)
	
func _deal_damage(amount: int, entity: CombatantData) -> void:
	entity.take_damage(amount)

func _on_deal_damage_button_pressed() -> void:
	var idx := entity_option_button.selected
	_deal_damage(int(amount_input.value), entity_option_button.get_item_metadata(idx))
