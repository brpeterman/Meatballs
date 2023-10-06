extends RigidBody3D
class_name Meatball

signal meatball_collided
signal died

@export var base_speed = 10.0
@export var movement_force = 50.0
@export var drag = 0.2
@export var jump_power = 250.0

var MASS_DELTA = 0.5
var MAX_MASS = 3.0
var SIZE_DELTA = 1.4
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
		if input_direction != Vector3.ZERO and can_accelerate():
			apply_central_force(input_direction * movement_force)
			input_direction = Vector3.ZERO
	
		if jump_impulse != Vector3.ZERO:
			apply_central_force(jump_impulse * sqrt(mass))
			jump_impulse = Vector3.ZERO
	
	# Rotate the mesh based on velocity
	#$MeshInstance3D.rotate(Vector3(0, 0, -1), linear_velocity.x * delta)
	#$MeshInstance3D.rotate(Vector3(1, 0, 0), linear_velocity.z * delta)

func _integrate_forces(state: PhysicsDirectBodyState3D):	
	for contact_idx in state.get_contact_count():
		var normal = state.get_contact_local_normal(contact_idx)
		var body = state.get_contact_collider_object(contact_idx)
		if body is Meatball:
			emit_signal("meatball_collided", self, body as Meatball, normal)
	
	state.integrate_forces()
	
func reload_floor_normal():
	var space_state = get_world_3d().direct_space_state
	var length = $CollisionShape3D.scale.x + 0.2
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * length)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		floor_normal = Vector3.ZERO
		return
	
	if not result["collider"] is Meatball:
		floor_normal = result["normal"] as Vector3

func can_accelerate():
	return is_on_floor() and linear_velocity.length() < base_speed / mass

func is_on_floor():
	return floor_normal != Vector3.ZERO\
		and Vector3.UP.angle_to(floor_normal) < PI / 4.0
	
func set_direction(direction):
	input_direction = direction

func jump():
	jump_impulse = floor_normal * jump_power

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
