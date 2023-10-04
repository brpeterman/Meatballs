extends Node3D
class_name Player

var pawn: Meatball

# Called when the node enters the scene tree for the first time.
func _ready():
	pawn = $Meatball as Meatball


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not Input.is_action_pressed("move_left")\
		and not Input.is_action_pressed("move_right")\
		and not Input.is_action_pressed("move_down")\
		and not Input.is_action_pressed("move_up"):
			pawn.set_direction(Vector3.ZERO)

func _unhandled_input(event):
	if event.is_action("jump"):
		pawn.jump()
	
	if !is_movement_input(event):
		return
	
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.z -= 1
	if Input.is_action_pressed("move_down"):
		direction.z += 1
	
	if direction.length() <= 0:
		return
	
	pawn.set_direction(direction.normalized())

func is_movement_input(event):
	return event.is_action("move_left")\
		or event.is_action("move_right")\
		or event.is_action("move_up")\
		or event.is_action("move_down")
