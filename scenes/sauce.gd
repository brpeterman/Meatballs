extends MeshInstance3D

func _process(delta):
	var texture = _get_sauce_trail_texture()
	if texture == null: return
	var material = material_override as ShaderMaterial
	material.set_shader_parameter('trail_texture', texture)
	
func _get_sauce_trail_texture() -> ViewportTexture:
	return Game.get_sauce_trail_texture()
