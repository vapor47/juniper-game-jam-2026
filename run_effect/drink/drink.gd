extends RunEffect
class_name Drink

var combats_remaining: int = 1
var alcohol_content: float = 10.0


func on_combat_ended(_result, _ctx: CombatContext) -> void:
	combats_remaining -= 1

func is_expired() -> bool:
	return combats_remaining <= 0

func on_acquired(player: PlayerData) -> void:
	"""
	Roll debuff chance before alcohol contribution to guarantee
	no debuffs on first drink.
	
	** We probably want two separate rolls later
	- One, for if we get a debuff at all
	- Second, for what debuff we get, we should consider the drunkenness
	  and perceived level of debuff, such that they feel appropriate
	"""
	var roll := randf_range(0.0, 100.0)
	if player.drunkenness > 0.0 and roll <= player.drunkenness:
		player.apply_debuff(DebuffPool.get_random_debuff())
	
	player.drunkenness += alcohol_content


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
