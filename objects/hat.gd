extends Marker3D

@export var target: Meatball
@export var collider: CollisionShape3D

@onready var offset = position.y
@onready var height = offset

func _ready():
	top_level = true
	target.resized.connect(_on_resized)
	_resize()
	
func _input(ev):
	if ev is InputEventKey:
		if ev.is_pressed() and ev.keycode == KEY_E:
			target.grow()
	
func _process(delta):
	if not target: return
	global_position = target.global_position
	global_position.y += height

func _on_resized():
	_resize()

func _resize():
	if not target or not collider: return
	
	var sphere = collider.shape as SphereShape3D
	var radius = sphere.radius
	var tween = create_tween()
	var y = radius
	
	tween.parallel().tween_property(self, 'height', y + 0.2, 0.1)
	tween.tween_property(self, 'scale', Vector3(1.4, 1.6, 1.4), 0.1)
	tween.parallel().tween_property(self, 'height', y, 0.1)
	tween.tween_property(self, 'scale', Vector3(1.0, 1.0, 1.0), 0.1)
