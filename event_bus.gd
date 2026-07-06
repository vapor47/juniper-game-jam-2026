extends Node

@warning_ignore_start("unused_signal")

signal open_side_panel(slot)
signal close_side_panel

signal slot_selected(slot)
signal reel_swapped(reel: Reel)
signal slots_locked_in(symbols: Array)
signal lever_pulled
signal spin_lock_toggled
signal respin_count_updated(new_value: int)

signal curr_health_updated(who: CombatantData, new_val: int)
signal max_health_updated(who: CombatantData, new_val: int)

signal post_combat_completed()
