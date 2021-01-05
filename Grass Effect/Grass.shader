shader_type spatial;
render_mode cull_disabled;

uniform vec4 color_top:hint_color = vec4(1, 1, 1, 1);
uniform vec4 color_bottom:hint_color = vec4(0, 0, 0, 1);

vec2 random2(vec2 p) {
	return fract(sin(vec2(
		dot(p, vec2(127.32, 231.4)),
		dot(p, vec2(12.3, 146.3))
	)) * 231.23);
}

float worley2(vec2 p) {
	float dist = 1.0;
	vec2 i_p = floor(p);
	vec2 f_p = fract(p);
	for (int y=-1; y<=1; y++) {
		for (int x=-1; x<=1; x++) {
			vec2 n = vec2(float(x), float(y));
			vec2 diff = n + random2(i_p + n) - f_p;
			dist = min(dist, length(diff));
		}
	}
	return dist;
}

void vertex() {
	NORMAL = vec3(0, 1, 0);
	vec3 vertex = VERTEX;
	vertex.xz *= INSTANCE_CUSTOM.x;
	vertex.y *= INSTANCE_CUSTOM.y;
	VERTEX = vertex;
	COLOR = mix(color_bottom, color_top, UV2.y);
}

void fragment() {
	float side = FRONT_FACING ? 1.0 : -1.0;
	NORMAL = NORMAL * side;
	ALBEDO = COLOR.rgb;
}