extends Marker3D

@export var target: Meatball
@export var mesh: MeshInstance3D

@onready var offset = position.y
@onready var height = offset

func _ready():
	top_level = true
	target.resized.connect(_on_resized)
	_resize(mesh.scale.x)
	
func _input(ev):
	if ev is InputEventKey:
		if ev.is_pressed() and ev.keycode == KEY_E:
			target.grow()
	
func _process(delta):
	if not target: return
	global_position = target.global_position
	global_position.y += height

func _on_resized(new_size: float):
	_resize(new_size)

func _resize(new_size: float):
	if not target or not mesh: return
	
	var tween = create_tween()
	
	tween.parallel().tween_property(self, 'height', new_size + 0.2, 0.1)
	tween.tween_property(self, 'scale', Vector3(1.4, 1.6, 1.4), 0.1)
	tween.parallel().tween_property(self, 'height', new_size, 0.1)
	tween.tween_property(self, 'scale', Vector3(1.0, 1.0, 1.0), 0.1)
