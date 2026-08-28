shader_type canvas_item;

// THE POSTER LAYER.
//
// Art direction §6, the two-layer rule: the poster layer is period-honest and
// FLAT -- limited palette, halftone or screenprint texture, heavy blacks, paper
// grain, registration slightly off. The effects layer is modern and LIT.
//
// KEEP THE SEAM VISIBLE. Do not blend them into one smooth illustration. The
// gap between the two layers IS the style, because the gap is the idea:
// something inhuman is happening inside an ordinary printed poster.
//
// So this shader deliberately does NOT try to look good in the modern sense.
// It tries to look PRINTED -- badly, cheaply, by a state print office on paper
// that was not the first choice.
//
// Written for this project rather than imported. godotshaders.com is the right
// place to read for technique, but it has no default licence -- authors pick
// CC0, MIT or GPL-3 per submission, and GPL-3 cannot go in a closed-source
// game. See docs/RESOURCES.md.

// ---- halftone
uniform bool halftone_on = true;
// Dot pitch in screen pixels. Larger = cheaper-looking print.
uniform float dot_size : hint_range(1.0, 12.0) = 3.4;
// Screen angle in degrees. Real print screens sit off-axis so the dot grid
// does not fight the pixel grid; 15 and 45 are the traditional angles.
uniform float screen_angle : hint_range(0.0, 90.0) = 15.0;
// How completely the halftone replaces the original. 1.0 is a pure print.
uniform float halftone_mix : hint_range(0.0, 1.0) = 0.55;

// ---- paper
uniform bool paper_on = true;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.10;
uniform vec3 paper_tint : source_color = vec3(0.93, 0.90, 0.82);
uniform float paper_bias : hint_range(0.0, 1.0) = 0.06;

// ---- registration
// The plates do not line up. This is a real property of cheap colour print and
// it is the single most convincing thing in the effect, because a clean image
// with halftone dots on it reads as a filter, and a MISREGISTERED one reads as
// a thing that came off a press.
uniform bool registration_on = true;
uniform float registration_px : hint_range(0.0, 4.0) = 0.9;

// ---- palette flattening. Poster stock has few inks.
uniform bool posterize_on = true;
uniform float levels : hint_range(2.0, 16.0) = 6.0;

// Same post-process sampling as attenuation.gdshader: a full-screen
// canvas_item shader must read hint_screen_texture at SCREEN_UV, NOT TEXTURE
// at UV -- the latter is the quad's own flat colour and silently hides the
// game behind a solid rectangle.
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float time_seed = 0.0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 px = 1.0 / SCREEN_PIXEL_SIZE;   // viewport size in pixels
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// ---- registration: pull the "plates" apart by under a pixel each way.
	// Sampled from the same texture rather than from real separations, which
	// is a cheat that reads correctly because the eye is looking for the
	// coloured fringe, not for genuine CMYK.
	if (registration_on) {
		vec2 off = registration_px * SCREEN_PIXEL_SIZE;
		float r = texture(screen_tex, SCREEN_UV + vec2( off.x,  0.0)).r;
		float g = texture(screen_tex, SCREEN_UV).g;
		float b = texture(screen_tex, SCREEN_UV + vec2(-off.x, off.y)).b;
		col = vec3(r, g, b);
	}

	// ---- posterize toward a small ink count.
	if (posterize_on) {
		col = floor(col * levels + 0.5) / levels;
	}

	// ---- halftone. Dots grow as the source darkens, on a rotated grid.
	if (halftone_on) {
		float a = radians(screen_angle);
		mat2 rot = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
		vec2 grid = (rot * (SCREEN_UV * px)) / max(dot_size, 0.5);
		vec2 cell = fract(grid) - 0.5;
		float d = length(cell);

		// Dot radius from darkness: dark ink = big dot.
		float ink = 1.0 - luma(col);
		float radius = sqrt(clamp(ink, 0.0, 1.0)) * 0.72;
		// Antialiased edge, in grid units.
		float dot_mask = 1.0 - smoothstep(radius - 0.09, radius + 0.09, d);

		// The printed version: ink where the dot is, paper where it is not.
		vec3 ink_col = col * 0.35;
		vec3 printed = mix(paper_tint, ink_col, dot_mask);
		col = mix(col, printed, halftone_mix);
	}

	// ---- paper: a warm bias and a fixed grain.
	//
	// The grain is keyed to UV only, NOT to time, and that is deliberate. Paper
	// grain that crawls reads as video noise and puts the image back in a
	// camera; a static grain reads as a surface the image was printed onto.
	// time_seed exists so a deliberate re-print can be triggered, not so the
	// texture animates every frame.
	if (paper_on) {
		float n = hash21(SCREEN_UV * px + vec2(time_seed));
		col += (n - 0.5) * grain_amount;
		col = mix(col, col * paper_tint, paper_bias);
	}

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
