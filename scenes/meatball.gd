extends RigidBody3D
class_name Meatball

signal meatball_collided
signal died
signal resized

@export var base_speed = 30.0
@export var movement_force = 100.0
@export var drag = 0.2
@export var jump_power = 5.0

var MASS_DELTA = 0.25
var SIZE_DELTA = pow((3 * MASS_DELTA) / (4 * PI), 1.0/3.0) / 2.0
var OUT_OF_BOUNDS = 500.0

var input_direction = Vector3.ZERO
var jump_impulse = Vector3.ZERO
var dead = false
var floor_normal = Vector3.ZERO

func _ready():
	resize(1.0)

func _process(delta):
	#var force_vector_mesh = $ForceVector.mesh
	#force_vector_mesh
	pass

func _physics_process(delta):
	reload_floor_normal()
	
	if global_position.length() > OUT_OF_BOUNDS:
		emit_signal("died", self)
	
	if is_on_floor():
		if input_direction != Vector3.ZERO and is_max_speed():
			# Remove the component that's in the direction of current movement
			input_direction -= linear_velocity.normalized()
			
		if input_direction != Vector3.ZERO:
			apply_central_force(input_direction * movement_force)
			input_direction = Vector3.ZERO
	
		if jump_impulse != Vector3.ZERO:
			apply_central_impulse(jump_impulse)
			jump_impulse = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D):	
	for contact_idx in state.get_contact_count():
		var normal = state.get_contact_local_normal(contact_idx)
		var body = state.get_contact_collider_object(contact_idx)
		if body is Meatball:
			emit_signal("meatball_collided", self, body as Meatball, normal)
	
	state.integrate_forces()
	
func reload_floor_normal():
	var space_state = get_world_3d().direct_space_state
	var length = sqrt(2) * $CollisionShape3D.scale.x # Far enough to see a 45deg slope
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * length)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		floor_normal = Vector3.ZERO
		return
	
	# Any object that we're balanced on is the "floor"
	floor_normal = (result["normal"] as Vector3).normalized()

func is_max_speed():
	return linear_velocity.length() >= base_speed / mass

func is_on_floor():
	return floor_normal != Vector3.ZERO\
		and Vector3.UP.angle_to(floor_normal) < PI / 4.0
	
func set_direction(direction):
	input_direction = direction

func jump():
	jump_impulse = floor_normal * jump_power * sqrt(mass)

func shrink():
	if mass <= MASS_DELTA:
		emit_signal("died", self)
		return
	mass -= MASS_DELTA
	resize(-SIZE_DELTA)
	
func grow():
	mass += MASS_DELTA
	resize(SIZE_DELTA)
	

func resize(size: float):
	var new_size = $CollisionShape3D.scale.x + size
	var tween = create_tween()
	tween.tween_property($MeshInstance3D, "scale", Vector3(new_size, new_size, new_size), 0.2).set_trans(Tween.TRANS_SPRING)
	$CollisionShape3D.scale = Vector3(new_size, new_size, new_size)
	resized.emit()
