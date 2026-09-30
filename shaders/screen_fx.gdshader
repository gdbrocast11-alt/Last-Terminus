shader_type canvas_item;
// Full-screen post effect for comfort-scaled camera drama: vignette, chromatic
// aberration, desaturation/tint, radial motion blur, wobble (premonitions), flash.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 0.03) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blur : hint_range(0.0, 1.0) = 0.0;
uniform float wobble : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float contrast : hint_range(0.5, 2.5) = 1.0;
uniform float exposure : hint_range(0.2, 4.0) = 1.0;
uniform float film_grain : hint_range(0.0, 0.3) = 0.0;
uniform float scanlines : hint_range(0.0, 1.0) = 0.0;
uniform float time_fx = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	if (wobble > 0.0) {
		uv += vec2(sin(uv.y * 18.0 + time_fx * 6.0), cos(uv.x * 14.0 + time_fx * 5.0)) * 0.006 * wobble;
		uv += c * sin(time_fx * 9.0) * 0.02 * wobble;
	}
	vec3 col;
	if (blur > 0.0) {
		col = vec3(0.0);
		float total = 0.0;
		for (int i = 0; i < 8; i++) {
			float t = float(i) / 7.0;
			float w = 1.0 - t * 0.6;
			col += textureLod(screen_tex, uv - c * t * 0.08 * blur, 0.0).rgb * w;
			total += w;
		}
		col /= total;
	} else if (aberration > 0.0) {
		float r = textureLod(screen_tex, uv + c * aberration, 0.0).r;
		float g = textureLod(screen_tex, uv, 0.0).g;
		float b = textureLod(screen_tex, uv - c * aberration, 0.0).b;
		col = vec3(r, g, b);
	} else {
		col = textureLod(screen_tex, uv, 0.0).rgb;
	}
	if (aberration > 0.0 && blur > 0.0) {
		col.r = mix(col.r, textureLod(screen_tex, uv + c * aberration, 0.0).r, 0.6);
		col.b = mix(col.b, textureLod(screen_tex, uv - c * aberration, 0.0).b, 0.6);
	}
	col *= exposure;
	col = (col - 0.5) * contrast + 0.5;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat);
	col = mix(col, col * tint.rgb, tint_amount);
	float v = smoothstep(0.85, 0.25, length(c) * (1.0 + vignette * 0.6));
	col *= mix(1.0, v, vignette);
	if (film_grain > 0.0) col += (hash(uv * 800.0 + time_fx) - 0.5) * film_grain;
	if (scanlines > 0.0) col *= 1.0 - scanlines * 0.25 * (0.5 + 0.5 * sin(uv.y * 900.0));
	col = mix(col, flash_color.rgb, flash);
	COLOR = vec4(col, 1.0);
}
