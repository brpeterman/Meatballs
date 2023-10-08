shader_type spatial;
render_mode ensure_correct_normals;

uniform vec2 size = vec2(32.0, 32.0);
uniform float max_thickness = 2.0;
uniform float uv_scale = 5.0;
uniform float metallic = 0.15;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D trail_texture: source_color, filter_linear_mipmap;
uniform sampler2D sauce_texture: source_color;
uniform sampler2D normal_texture: hint_normal;

uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

float sample (vec3 pos) {
	float x = clamp((pos.x + (size.x * 0.5)) / size.x, 0.0, 1.0);
	float z = clamp((pos.z + (size.y * 0.5)) / size.y, 0.0, 1.0);
	vec4 trail = texture(trail_texture, vec2(x, z));
	return trail.r;
}

void vertex() {
	vec4 pos = vec4(VERTEX, 1.0);
	float thickness = sample(pos.xyz);
	float height = (1.0 - thickness) * max_thickness;
	VERTEX += NORMAL * height;
}

void fragment() {
	float e = (1.0 / 32.0);
	
	vec4 pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 albedo = texture(sauce_texture, UV * uv_scale);
	vec4 normal = texture(normal_texture, UV * uv_scale);
	
	float thickness = 1.0 - sample(pos.xyz);
	float mask = COLOR.r * thickness;
	
	// TODO: use texture mask instead of vertex colors to smooth alpha on sauce boundary?
	
	ALBEDO = albedo.rgb;
	ROUGHNESS = max(0.05 * COLOR.r, 0.001);
	NORMAL_MAP = normal.rgb * mask;
	NORMAL_MAP_DEPTH = 1.0 * mask;
	METALLIC = metallic * mask;
	ALPHA = mask;
}

