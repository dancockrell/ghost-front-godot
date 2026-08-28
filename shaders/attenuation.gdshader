shader_type canvas_item;

// THE SCREEN TELLS THE TRUTH THE FORM WILL NOT.
//
// This is the honest channel, and that is its entire job. Form 42-C understates
// -- at 80% true attenuation it reports "3-C SATISFACTORY, minor coherence
// variance, no action indicated" -- and the handler reads that same form aloud.
// If the interface were the player's ONLY feedback, the game would be
// unlearnable rather than atmospheric.
//
// So: THE FORM LIES, THE WORLD DOES NOT. This shader is the world.
//
// `attenuation` here is the TRUE value, never FieldReadout's version. Anything
// that wires this to the displayed figure has removed the player's second
// opinion and turned the whole mechanic cosmetic, with no symptom, because the
// HUD would still animate. ReadoutProbe guards the same boundary in code.
//
// The distortion is designed to be READ RATHER THAN ENDURED. It has to be
// legible at a glance -- the player should be able to tell roughly how far
// gone they are without looking at a number -- and it must not get so heavy
// that the game becomes unplayable at the very moment it is most interesting.
// A fail state that blinds you is a fail state nobody chooses to explore, and
// this one is supposed to be tempting.

// POST-PROCESS SAMPLING, and getting this wrong is why the first version
// painted a flat white rectangle over the entire game.
//
// A canvas_item shader on a full-screen ColorRect samples TEXTURE by default,
// and TEXTURE is the RECT'S OWN colour -- a single flat value. It compiles, it
// runs, and it hides the world behind it. What is wanted is the frame rendered
// so far, which is `hint_screen_texture` read at SCREEN_UV.
//
// filter_linear_mipmap + repeat_disable: the channel split samples off-centre
// and would otherwise wrap the opposite screen edge into the fringe.
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float attenuation : hint_range(0.0, 1.0) = 0.0;
// Where involuntary phasing begins. Matches PhaseDash.unstable_at. Past this,
// the effect gains a jitter it does not have below -- so the threshold is
// visible without a warning ever being printed.
uniform float unstable_at : hint_range(0.0, 1.0) = 0.75;
uniform float time_sec = 0.0;

// Peak separation of the colour channels, px, at a full meter.
uniform float split_px : hint_range(0.0, 24.0) = 9.0;
// Peak desaturation. You are less present, so the world holds less of you.
uniform float desat_max : hint_range(0.0, 1.0) = 0.55;
// Vignette closing in as coherence goes.
uniform float vignette_max : hint_range(0.0, 1.0) = 0.6;

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

void fragment() {
	float a = clamp(attenuation, 0.0, 1.0);

	// Curved rather than linear: nothing visible in the safe band, so the
	// effect reads as something starting rather than as a filter that was
	// always on. Quadratic keeps the low end genuinely clean.
	float strength = a * a;

	vec2 uv = SCREEN_UV;

	// ---- above the instability threshold, the frame stops being reliable.
	// Small, irregular, and only here. This is the visual counterpart of the
	// floor going away, and it arrives at exactly the value where it does.
	float over = clamp((a - unstable_at) / max(1.0 - unstable_at, 0.0001), 0.0, 1.0);
	if (over > 0.0) {
		float band = floor(uv.y * 40.0);
		float j = hash21(vec2(band, floor(time_sec * 12.0)));
		// only some bands, only sometimes: a steady shear reads as a CRT
		if (j > 0.86) {
			uv.x += (j - 0.93) * 0.06 * over;
		}
	}

	// ---- channel separation. The agent is coming apart into components.
	vec2 off = vec2(split_px, 0.0) * SCREEN_PIXEL_SIZE * strength;
	float r = texture(screen_tex, uv + off).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - off).b;
	vec3 col = vec3(r, g, b);

	// ---- desaturation toward the value channel.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat_max * strength);

	// ---- vignette. The world narrows to what is still looking at you.
	vec2 c = SCREEN_UV - vec2(0.5);
	float v = 1.0 - smoothstep(0.24, 0.78, length(c));
	col *= mix(1.0, v, vignette_max * strength);

	COLOR = vec4(col, 1.0);
}
