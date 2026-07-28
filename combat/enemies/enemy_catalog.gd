extends RefCounted
class_name EnemyCatalog
## Every enemy that exists, in one place.
##
## This is the *existence* list, not the run order — RunManager owns the order
## because that is a design decision, and an enemy can exist without being in a
## run yet. Anything that needs to enumerate enemies (the God Menu's fight
## picker, future encounter generation) reads from here.
##
## It exists because it was previously two hardcoded lists that had to agree,
## and they immediately did not: The Rake was added to the run queue and the
## debug picker kept offering five enemies. Same failure as the shop's private
## colour table and the paytable's private sort order — a second copy of a fact
## that drifts silently.
##
## Adding an enemy: put it here. Add it to RunManager.encounter_queue only if it
## belongs in the run's fixed order.

const ALL: Array[GDScript] = [
	preload("res://combat/enemies/destitute_gambler.gd"),
	preload("res://combat/enemies/chargey_guy.gd"),
	preload("res://combat/enemies/two_faced.gd"),
	preload("res://combat/enemies/the_rake.gd"),
	preload("res://combat/enemies/the_cooler.gd"),
	preload("res://combat/enemies/pit_boss.gd"),
]


## Every enemy in the run queue must exist in the catalog. Cheap guard against
## the exact drift this class was written to stop.
static func missing_from_catalog() -> Array[String]:
	var missing: Array[String] = []
	for pool: Array in RunManager.encounter_queue:
		for script: GDScript in pool:
			if script not in ALL:
				missing.append(script.resource_path.get_file())
	return missing
