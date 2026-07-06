extends Resource
class_name CombatantData

signal died(who: CombatantData)

@export var display_name: String = "Combatant"
@export var max_health: int = 100:
	set(new_val):
		max_health = new_val
		EventBus.max_health_updated.emit(self, new_val)
		
@export var health: int = max_health:
	set(new_val):
		health = new_val
		EventBus.curr_health_updated.emit(self, new_val)
		
var block: int = 0

func take_damage(amount: int) -> void:
	var actual = max(0, amount - block)
	block = max(0, block - amount)
	health -= actual
	if health <= 0:
		died.emit(self)
		
	print_debug(str(display_name) + " Current Health: " + str(health))
	reset_block()

func add_block(amount: int) -> void:
	block += amount

func heal(amount: int) -> void:
	health += amount

func reset_block() -> void:
	block = 0
