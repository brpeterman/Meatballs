extends Node

var sauce_viewport: Viewport = null

func get_sauce_trail_texture() -> ViewportTexture:
	if not sauce_viewport: return null
	return sauce_viewport.get_texture()
