extends RunEffect
class_name Drink

var combats_remaining: int = 1


func on_combat_ended(_result, _ctx: CombatContext) -> void:
	combats_remaining -= 1

func is_expired() -> bool:
	return combats_remaining <= 0


"""
Drink ideas: (the more easily visually identifiable, the better)
	Cocktails:
		Old Fashioned
		Negroni
		Mojito
		Moscow Mule
		Margarita
		Martini
		Long Island Iced Tea
		Bloody Mary
		Daiquiri
		Manhattan
		Cosmopolitan
		Mai Tai
		Gin and Tonic
		
		Azulito
		
	Mocktails:
		
	Shots:
		Lemon Drop
		Green Tea Shot
		Tequila (add a slice of lime visually, maybe in a small plate)
		Jager Bomb
	
	Bottles: (ehh idk if this feels classy enough)
		
	Water: Can reduce drink consumed count? can be more rare, as a given event maybe?

"""
