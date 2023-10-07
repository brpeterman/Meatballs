extends Node3D
class_name Player

signal player_on_floor_status

# TODO: Lower the angle when we can see through the level
@export var camera_direction = Vector3(0, 5.0, 3.9)
@export var camera_base_distance = 20.0
@export var camera_base_fov = 20

var camera_position = camera_direction.normalized() * camera_base_distance
var pawn: Meatball

# Called when the node enters the scene tree for the first time.
func _ready():
	pawn = $Meatball as Meatball

func _process(delta):
	if not Input.is_action_pressed("move_left")\
		and not Input.is_action_pressed("move_right")\
		and not Input.is_action_pressed("move_down")\
		and not Input.is_action_pressed("move_up"):
			pawn.set_direction(Vector3.ZERO)
	
	if Input.is_action_pressed("jump"):
		pawn.jump()
	
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

func _physics_process(delta):
	$Camera3D.global_position = $Meatball.global_position + camera_position
	$Camera3D.look_at($Meatball.global_position)
	
	emit_signal("player_on_floor_status", pawn.is_on_floor())

func is_movement_input(event: InputEvent):
	return event.is_action("move_left")\
		or event.is_action("move_right")\
		or event.is_action("move_up")\
		or event.is_action("move_down")


func _on_meatball_resized():
	var fov_tween = get_tree().create_tween()
	var new_fov = camera_base_fov * pow($Meatball/CollisionShape3D.scale.x, 1.2)
	fov_tween.tween_property($Camera3D, "fov", new_fov, 0.5)
