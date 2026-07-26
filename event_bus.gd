extends Node

@warning_ignore_start("unused_signal")

signal lever_pulled
signal slot_selection_confirmed
signal spin_all_completed
signal token_count_updated(new_value: int)

signal shop_exited
signal run_effect_added(r: RunEffect)

signal curr_health_updated(who: CombatantData, new_val: int)
signal max_health_updated(who: CombatantData, new_val: int)

signal post_combat_completed()
