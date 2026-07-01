extends Resource
class_name CombatantData

@export var display_name: String = "Combatant"
@export var max_health: int = 100
@export var health: int = max_health
var block: int = 0

func take_damage(amount: int) -> void:
	var actual = max(0, amount - block)
	block = max(0, block - amount)
	health -= actual
	# TODO: Potential refactor? make this a direct connection, rather than having all entities listen?
	# Altho i guess its at make like 5 listeners. not terrible.
	EventBus.damage_taken.emit(self)
	if health <= 0:
		EventBus.entity_died.emit(self)
		
	print_debug(str(display_name) + " Current Health: " + str(health))
	reset_block()

func add_block(amount: int) -> void:
	block += amount

func heal(amount: int) -> void:
	health += amount

func reset_block() -> void:
	block = 0
