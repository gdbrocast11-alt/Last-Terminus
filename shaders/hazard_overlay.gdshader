shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
// Danger-intuition highlight: rim glow + moving hatch stripes so the cue never
// depends on colour alone.
uniform vec4 glow_color : source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform float strength = 1.0;
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float hatch = step(0.5, fract((UV.x + UV.y) * 24.0 + TIME * 0.6));
	float pulse = 0.65 + 0.35 * sin(TIME * 6.0);
	ALBEDO = glow_color.rgb * (rim * 1.6 + hatch * 0.18) * strength * pulse;
	ALPHA = 1.0;
}
