extends Node

@warning_ignore_start("unused_signal")

signal open_side_panel(slot: Slot)
signal close_side_panel

signal side_panel_closed

signal slot_selected(slot: Slot)
signal reel_swapped(reel: Reel)
signal slots_locked_in(symbols: Array)
signal lever_pulled
signal slot_selection_confirmed
signal inventory_reel_pressed(reel: Reel)
signal spin_all_completed
signal combo_legend_updated(new_rows: Array[ComboLegendRow])
signal slot_press_action_changed(new_action: CombatManager.SlotPressAction)
signal spin_lock_toggled
signal token_count_updated(new_value: int)

signal reel_modified(reel: Reel)

signal curr_health_updated(who: CombatantData, new_val: int)
signal max_health_updated(who: CombatantData, new_val: int)

signal post_combat_completed()
