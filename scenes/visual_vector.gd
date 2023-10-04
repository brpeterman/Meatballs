extends ImmediateMesh

@export var color: Color

var vector = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	clear_surfaces()
	
	
