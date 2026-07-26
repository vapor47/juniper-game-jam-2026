extends Resource
class_name CombatantData

signal died(who: CombatantData)

@export var display_name: String = "Combatant"
var max_health: int = 100:
	set(new_val):
		max_health = new_val
		EventBus.max_health_updated.emit(self, new_val)
		
var health: int = max_health:
	set(new_val):
		health = new_val
		EventBus.curr_health_updated.emit(self, new_val)
		
var block: int = 0

## Latches on the killing blow so `died` fires exactly once. Without it every
## later hit re-emits it, since `health <= 0` stays true.
var is_dead: bool = false


func take_damage(amount: int) -> int:
	if is_dead:
		return 0

	var actual: int = max(0, amount - block)
	block = max(0, block - amount)
	health = max(0, health - actual)

	reset_block()

	if health <= 0:
		is_dead = true
		died.emit(self)
	return actual

## Damage that ignores block — self-inflicted harm and anything else that
## shouldn't be soaked. Shares take_damage's death latch so `died` still fires
## exactly once whichever route kills.
func take_true_damage(amount: int) -> int:
	if is_dead:
		return 0

	var actual: int = mini(amount, health)
	health = max(0, health - actual)

	if health <= 0:
		is_dead = true
		died.emit(self)
	return actual


func add_block(amount: int) -> int:
	block += amount
	return amount

## Returns how much health was actually restored — healing at full stops at
## max_health rather than running past it.
func heal(amount: int) -> int:
	var actual: int = min(amount, max(0, max_health - health))
	health += actual
	return actual

func reset_block() -> void:
	block = 0
