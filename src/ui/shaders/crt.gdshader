shader_type canvas_item;

// CRT monitor effect - scanlines, slight curvature, phosphor glow
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float curvature : hint_range(0.0, 0.1) = 0.02;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float brightness : hint_range(0.8, 1.5) = 1.1;
uniform float flicker : hint_range(0.0, 0.05) = 0.01;
uniform vec3 phosphor_tint = vec3(0.9, 1.0, 0.85);

void fragment() {
	vec2 uv = UV;

	// Barrel distortion (CRT curvature)
	vec2 centered = uv - 0.5;
	float dist = dot(centered, centered);
	uv = uv + centered * dist * curvature;

	// Clamp UV - no return, just set black for out-of-bounds
	float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// Sample the texture
	vec4 col = texture(TEXTURE, uv);

	// Scanlines
	float scanline = sin(uv.y * 270.0 * 3.14159 * 2.0) * 0.5 + 0.5;
	col.rgb -= scanline_intensity * scanline * vec3(1.0);

	// Phosphor tint
	col.rgb *= phosphor_tint;

	// Brightness boost
	col.rgb *= brightness;

	// Subtle flicker
	col.rgb += flicker * sin(TIME * 60.0);

	// Vignette (darker edges)
	float vignette = 1.0 - dist * vignette_intensity * 4.0;
	col.rgb *= vignette;

	// Black out-of-bounds pixels
	col.rgb *= in_bounds;

	COLOR = col;
}
