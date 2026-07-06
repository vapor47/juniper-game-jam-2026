extends Resource
class_name Encounter

enum Type { COMBAT, SHOP }

@export var type: Type
@export var scene: PackedScene
