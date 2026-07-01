extends Node

@warning_ignore_start("unused_signal")

signal open_side_panel(slot)
signal close_side_panel

signal slot_selected(slot)
signal reel_swapped(reel: Reel)
signal slots_locked_in(symbols: Array)
signal lever_pulled
signal spin_lock_toggled
signal respin_count_updated
signal damage_taken(who: CombatantData)

# Combat States
signal turn_started(who: CombatManager.Turn)
signal turn_ended(who: CombatManager.Turn)
signal entity_died(who: CombatantData)
signal combat_ended(result: String)
