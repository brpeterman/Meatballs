extends SubViewport

@export var displacement_object: PackedScene
@export var area_size := Vector2(32.0, 32.0)

func _ready():
	Game.sauce_viewport = self
	
	for meatball in get_tree().get_nodes_in_group('meatballs'):
		var displacer = displacement_object.instantiate() as SauceDisplacer
		displacer.size = area_size
		displacer.resolution = size
		displacer.target = meatball
		add_child(displacer)
