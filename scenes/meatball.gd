extends CharacterBody3D
class_name Meatball

signal meatball_collided
signal died

@export var base_speed = 10.0
@export var mass = 1.0
@export var acceleration = 20.0
@export var drag = 2.0
@export var jump_power = 250.0

var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var MASS_DELTA = 0.5
var MAX_MASS = 3.0
var SIZE_DELTA = 1.4
var OUT_OF_BOUNDS = 500.0

var input_direction = Vector3.ZERO
var jump_impulse = Vector3.ZERO
var dead = false

func _ready():
	resize(1.0)

func _process(delta):
	#var force_vector_mesh = $ForceVector.mesh
	#force_vector_mesh
	pass

func _physics_process(delta):
	if global_position.length() > OUT_OF_BOUNDS:
		emit_signal("died", self)
	
	var desired_velocity = velocity
	
	if not is_on_floor():
		desired_velocity.y -= GRAVITY * delta
	
	if is_on_floor():
		var velocity_delta = input_direction * acceleration * delta / mass
		
		var max_speed = base_speed / mass
		# Downhill velocity is allowed to exceed max
		desired_velocity += velocity_delta
		if desired_velocity.length() > max_speed and desired_velocity.y >= 0:
			desired_velocity = desired_velocity.normalized() * max_speed
		
		desired_velocity -= desired_velocity.normalized() * drag * delta
		pass
		
		if get_floor_normal() != Vector3.UP:
			var upslope = Vector3.UP - get_floor_normal()
			# TODO: Don't apply full gravity to a slope
			desired_velocity -= upslope * GRAVITY * delta
		
		if desired_velocity.length() < 0:
			desired_velocity = Vector3.ZERO
		
		if jump_impulse.length() > 0:
			desired_velocity += jump_impulse * delta
			jump_impulse = Vector3.ZERO
	
	velocity = desired_velocity
	
	# Rotate the mesh based on velocity
	$MeshInstance3D.rotate(Vector3(0, 0, -1), velocity.x * delta)
	$MeshInstance3D.rotate(Vector3(1, 0, 0), velocity.z * delta)
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Meatball:
			emit_signal("meatball_collided", self, collision)
	
func set_direction(direction):
	input_direction = direction

func jump():
	if is_on_floor():
		jump_impulse = get_floor_normal() * jump_power

func shrink():
	if mass <= MASS_DELTA:
		emit_signal("died", self)
		return
	mass -= MASS_DELTA
	resize(1.0/SIZE_DELTA)
	
func grow():
	if mass >= MAX_MASS:
		mass = MAX_MASS
		return
	mass += MASS_DELTA
	resize(SIZE_DELTA)

func resize(factor: float):
	var tween = create_tween()
	tween.tween_property($MeshInstance3D, "scale", Vector3(factor, factor, factor), 0.2).set_trans(Tween.TRANS_SPRING)
	$CollisionShape3D.transform.scaled(Vector3(factor, factor, factor))
