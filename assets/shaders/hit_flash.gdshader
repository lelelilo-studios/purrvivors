shader_type canvas_item;
// White hit-flash for damageable sprites. Tween `flash` 1.0 -> 0.0 on hit.

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	tex.rgb = mix(tex.rgb, vec3(1.0), flash);
	COLOR = tex * COLOR;
}
